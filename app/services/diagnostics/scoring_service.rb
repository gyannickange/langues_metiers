module Diagnostics
  class ScoringService
    class InsufficientCareersError < StandardError; end

    SKILL_WEIGHT       = 0.4
    AFFIRMATION_WEIGHT = 0.6

    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def call
      score_data = @diagnostic.score_data.is_a?(Hash) ? @diagnostic.score_data : {}
      retained   = Array(score_data["retained_careers"]).select { |entry| entry.is_a?(Hash) && entry["career_id"].present? }
      raise InsufficientCareersError, "At least two retained careers are required to complete a diagnostic" if retained.size < 2

      careers_by_id   = Career.where(id: retained.map { |e| e["career_id"] }).index_by { |c| c.id.to_s }
      selected_skills = Array(@diagnostic.selected_skills)

      scored = retained.filter_map { |entry| score_entry(entry, careers_by_id, selected_skills) }
      raise InsufficientCareersError, "At least two scorable careers are required to complete a diagnostic" if scored.size < 2

      ranked = scored.sort_by { |entry| tie_break_key(entry) }
      primary_entry, secondary_entry = ranked.first(2)

      @diagnostic.update!(
        primary_career:       careers_by_id[primary_entry["career_id"].to_s],
        complementary_career: careers_by_id[secondary_entry["career_id"].to_s],
        status:               :pending_payment,
        completed_at:         Time.current,
        score_data:           score_data.merge("retained_careers" => scored)
      )
    end

    private

    def score_entry(entry, careers_by_id, selected_skills)
      career = careers_by_id[entry["career_id"].to_s]
      return nil unless career

      skill_score, missing_required_skills, matching_skills = skill_score_for(career, selected_skills)
      affirmation_score = affirmation_score_for(career)
      final_score = (SKILL_WEIGHT * skill_score) + (AFFIRMATION_WEIGHT * affirmation_score)

      entry.merge(
        "required_skills_snapshot" => career.required_skills,
        "selected_matching_skills" => matching_skills,
        "skill_score"               => skill_score.round(2),
        "missing_required_skills"   => missing_required_skills,
        "affirmation_score"         => affirmation_score.round(2),
        "final_score"               => final_score.round(2)
      )
    end

    def skill_score_for(career, selected_skills)
      required = Array(career.required_skills)
      return [ 0.0, true, [] ] if required.empty?

      matching = required & selected_skills
      [ (matching.size.to_f / required.size) * 100, false, matching ]
    end

    def affirmation_score_for(career)
      values = @diagnostic.diagnostic_answers.where(career_id: career.id).pluck(:effective_value).compact
      # A career with zero affirmations has an empty average (0), and normalize(0) would read as
      # -25% (below the 1..5 scale's floor) — treat "nothing to score" as 0%, not a negative score.
      return 0.0 if values.empty?

      Diagnostics::LikertScoring.normalize(Diagnostics::LikertScoring.average(values))
    end

    def tie_break_key(entry)
      [
        -entry["final_score"],
        -entry["affirmation_score"],
        -entry["disc_match_count"].to_i,
        -entry["academic_field_score"].to_f,
        entry["career_id"].to_s
      ]
    end
  end
end

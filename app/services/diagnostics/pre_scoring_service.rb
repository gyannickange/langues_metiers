# app/services/diagnostics/pre_scoring_service.rb
module Diagnostics
  class PreScoringService
    def self.call(diagnostic)
      new(diagnostic).call
    end

    def initialize(diagnostic)
      @diagnostic = diagnostic
    end

    def call
      scores = calculate_scores
      dominant_disc_types, dominant_academic_field = dominant_categories(scores)
      ranked = rank_careers(scores, dominant_disc_types, dominant_academic_field)

      @diagnostic.update!(
        score_data: scores.merge(
          "dominant_disc_types"     => dominant_disc_types,
          "dominant_academic_field" => dominant_academic_field,
          "top_career_ids"          => ranked.first(3).map { |entry| serialize_entry(entry) }
        )
      )
    end

    private

    def calculate_scores
      disc_scores       = Hash.new(0)
      academic_field_scores    = Hash.new(0)
      skill_scores = {}

      @diagnostic.diagnostic_answers.includes(:diagnostic_question).each do |answer|
        q = answer.diagnostic_question
        next unless q

        case q.kind
        when "disc"
          next if q.disc_type.nil?
          disc_scores[q.disc_type] += answer.points_awarded.to_i
        when "interest"
          academic_field_scores[answer.dimension_slug] += answer.points_awarded.to_i
        when "skill"
          skill_scores[q.skill_slug] = answer.points_awarded.to_i
        end
      end

      { "disc_scores" => disc_scores, "academic_field_scores" => academic_field_scores, "skill_scores" => skill_scores }
    end

    def dominant_categories(scores)
      dominant_disc    = scores["disc_scores"].sort_by { |_, v| -v }.first(2).map(&:first)
      dominant_academic_field = scores["academic_field_scores"].max_by { |_, v| v }&.first

      [ dominant_disc, dominant_academic_field ]
    end

    def rank_careers(scores, dominant_disc_types, dominant_academic_field)
      skill_scores = scores["skill_scores"]

      Career.diagnostic.published.map do |career|
        matched_disc_types = career.disc_types & dominant_disc_types
        disc_match    = matched_disc_types.size * 3
        academic_field_match = dominant_academic_field && career.academic_field_slug == dominant_academic_field ? 5 : 0
        matched_skills = (career.required_skills || []).each_with_object({}) do |slug, memo|
          memo[slug] = skill_scores[slug].to_i if skill_scores.key?(slug)
        end
        comp_match = matched_skills.values.sum

        {
          career:                career,
          score:                 disc_match + academic_field_match + comp_match,
          disc_match:            disc_match,
          academic_field_match:  academic_field_match,
          comp_match:            comp_match,
          matched_disc_types:    matched_disc_types,
          matched_skills:        matched_skills
        }
      end.sort_by { |entry| -entry[:score] }
    end

    def serialize_entry(entry)
      {
        "id"                   => entry[:career].id,
        "score"                => entry[:score],
        "disc_match"           => entry[:disc_match],
        "academic_field_match" => entry[:academic_field_match],
        "comp_match"           => entry[:comp_match],
        "matched_disc_types"   => entry[:matched_disc_types],
        "matched_skills"       => entry[:matched_skills]
      }
    end
  end
end

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
      scores      = calculate_scores
      top_careers = rank_careers(scores).first(3)

      @diagnostic.update!(
        score_data: scores.merge(
          "top_career_ids" => top_careers.map { |career, score| { "id" => career.id, "score" => score } }
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

    def rank_careers(scores)
      disc_scores       = scores["disc_scores"]
      academic_field_scores    = scores["academic_field_scores"]
      skill_scores = scores["skill_scores"]

      dominant_disc    = disc_scores.sort_by { |_, v| -v }.first(2).map(&:first)
      dominant_academic_field = academic_field_scores.max_by { |_, v| v }&.first

      Career.diagnostic.published.map do |career|
        disc_match    = career.disc_types.count { |t| dominant_disc.include?(t) } * 3
        academic_field_match = dominant_academic_field && career.academic_field_slug == dominant_academic_field ? 5 : 0
        comp_match    = (career.required_skills || []).sum { |c| skill_scores[c].to_i }
        [ career, disc_match + academic_field_match + comp_match ]
      end.sort_by { |_, s| -s }
    end
  end
end

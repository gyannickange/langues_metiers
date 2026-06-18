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
      filiere_scores    = Hash.new(0)
      competence_scores = {}

      @diagnostic.diagnostic_answers.includes(:diagnostic_question).each do |answer|
        q = answer.diagnostic_question
        next unless q

        case q.kind
        when "disc"
          next if q.disc_type.nil?
          disc_scores[q.disc_type] += answer.points_awarded.to_i
        when "interest"
          filiere_scores[answer.dimension_slug] += answer.points_awarded.to_i
        when "competence"
          competence_scores[q.competence_slug] = answer.points_awarded.to_i
        end
      end

      { "disc_scores" => disc_scores, "filiere_scores" => filiere_scores, "competence_scores" => competence_scores }
    end

    def rank_careers(scores)
      disc_scores       = scores["disc_scores"]
      filiere_scores    = scores["filiere_scores"]
      competence_scores = scores["competence_scores"]

      dominant_disc    = disc_scores.sort_by { |_, v| -v }.first(2).map(&:first)
      dominant_filiere = filiere_scores.max_by { |_, v| v }&.first

      Career.diagnostic.published.map do |career|
        disc_match    = career.disc_types.count { |t| dominant_disc.include?(t) } * 3
        filiere_match = dominant_filiere && career.filiere_slug == dominant_filiere ? 5 : 0
        comp_match    = (career.required_competences || []).sum { |c| competence_scores[c].to_i }
        [ career, disc_match + filiere_match + comp_match ]
      end.sort_by { |_, s| -s }
    end
  end
end

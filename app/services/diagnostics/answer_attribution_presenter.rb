module Diagnostics
  class AnswerAttributionPresenter
    Attribution = Struct.new(:label, :career, :entry, :affirmation, keyword_init: true)

    def initialize(diagnostic)
      @diagnostic   = diagnostic
      @score_data   = diagnostic.score_data.is_a?(Hash) ? diagnostic.score_data : {}
      @attributions = build_attributions
    end

    def available?
      @attributions.any?
    end

    def recap_line
      return nil unless available?

      @attributions.map { |a| "#{a.label} : #{final_score(a)} pts" }.join(" · ")
    end

    def badges_for(answer)
      question = answer.diagnostic_question
      return [] unless question

      @attributions.filter_map do |attribution|
        points = points_for(attribution, question)
        next unless points

        { label: attribution.label, points: points }
      end
    end

    def affirmation_rows
      @attributions.flat_map do |attribution|
        Array(attribution.affirmation&.dig("checked_affirmations")).map do |text|
          { label: attribution.label, text: text }
        end
      end
    end

    private

    def build_attributions
      top_career_ids = @score_data["top_career_ids"]
      return [] unless top_career_ids.is_a?(Array)

      [ [ "Métier 1", @diagnostic.primary_career ], [ "Métier 2", @diagnostic.complementary_career ] ].filter_map do |label, career|
        next unless career

        entry = top_career_ids.find { |h| h.is_a?(Hash) && h["id"].to_s == career.id.to_s }
        next unless entry && entry.key?("disc_match")

        affirmation = @score_data.dig("affirmation_breakdown", career.id.to_s)
        Attribution.new(label: label, career: career, entry: entry, affirmation: affirmation)
      end
    end

    def final_score(attribution)
      attribution.entry["score"].to_i + attribution.affirmation&.dig("bonus").to_i
    end

    def points_for(attribution, question)
      case question.kind
      when "disc"
        3 if Array(attribution.entry["matched_disc_types"]).include?(question.disc_type)
      when "interest"
        return nil unless @score_data["dominant_academic_field"] == question.academic_field_slug
        5 if attribution.career.academic_field_slug == question.academic_field_slug
      when "skill"
        attribution.entry.dig("matched_skills", question.skill_slug)
      end
    end
  end
end

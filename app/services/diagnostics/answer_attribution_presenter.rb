module Diagnostics
  class AnswerAttributionPresenter
    Attribution = Struct.new(:label, :career, :entry, :affirmation, :retained, keyword_init: true)

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

    def overview_cards
      @attributions.map do |attribution|
        {
          label:                attribution.label,
          career:               attribution.career,
          total:                final_score(attribution),
          categories:           category_breakdown(attribution),
          has_affirmation_data: attribution.affirmation.present?
        }
      end
    end

    def category_breakdown(attribution)
      entry = attribution.entry
      dominant_disc_count = Array(@score_data["dominant_disc_types"]).size

      rows = [
        { label: "DISC",        points: entry["disc_match"].to_i,           max: dominant_disc_count * 3 },
        { label: "Intérêts",    points: entry["academic_field_match"].to_i, max: 5 },
        { label: "Compétences", points: entry["comp_match"].to_i,           max: nil }
      ]

      if attribution.affirmation.present?
        rows << {
          label:  "Bonus affirmations",
          points: attribution.affirmation["bonus"].to_i,
          max:    attribution.affirmation["max_bonus"].to_i
        }
      end

      rows
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

      retained = [ [ "Métier 1", @diagnostic.primary_career ], [ "Métier 2", @diagnostic.complementary_career ] ].filter_map do |label, career|
        next unless career

        entry = top_career_ids.find { |h| h.is_a?(Hash) && h["id"].to_s == career.id.to_s }
        next unless entry && entry.key?("disc_match")

        affirmation = @score_data.dig("affirmation_breakdown", career.id.to_s)
        Attribution.new(label: label, career: career, entry: entry, affirmation: affirmation, retained: true)
      end

      retained + [ build_third_candidate(top_career_ids, retained) ].compact
    end

    def build_third_candidate(top_career_ids, retained)
      return nil unless retained.size == 2

      retained_ids = retained.map { |a| a.career.id.to_s }
      entry = top_career_ids.find do |h|
        h.is_a?(Hash) && h["id"].present? && h.key?("disc_match") && !retained_ids.include?(h["id"].to_s)
      end
      return nil unless entry

      career = Career.find_by(id: entry["id"])
      return nil unless career

      Attribution.new(label: "Non retenu", career: career, entry: entry, affirmation: nil, retained: false)
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

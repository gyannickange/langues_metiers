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

    def overview_cards
      @attributions.map do |attribution|
        base_total = attribution.entry["score"].to_i
        bonus = attribution.affirmation&.dig("bonus").to_i
        {
          label:                attribution.label,
          career:               attribution.career,
          retained:             attribution.retained,
          base_total:           base_total,
          bonus:                bonus,
          total:                base_total + bonus,
          categories:           category_breakdown(attribution),
          has_affirmation_data: attribution.affirmation.present?
        }
      end
    end

    def score_summary
      cards = overview_cards
      return [] if cards.empty?

      cards.map do |card|
        {
          label: card[:label],
          career: card[:career],
          score: card[:total],
          base_score: card[:base_total],
          bonus: card[:bonus],
          retained: card[:retained]
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

        {
          label: attribution.label,
          text: legacy_badge_text(question, points),
          tooltip: badge_content(question, points)[:tooltip]
        }
      end
    end

    def contribution_details_for(answer)
      question = answer.diagnostic_question
      return [] unless question

      @attributions.filter_map do |attribution|
        points = points_for(attribution, question)
        next unless points

        detail = badge_content(question, points)
        detail.merge(
          label: attribution.label,
          career: attribution.career,
          points: points,
          contribution_type: question.kind == "skill" ? :per_answer : :flat_bonus
        )
      end
    end

    def answer_value_label(answer)
      question = answer.diagnostic_question
      return answer.answer_value.to_s unless question

      option = Array(question.options).find { |item| item.is_a?(Hash) && item["value"].to_s == answer.answer_value.to_s }
      return option["text"].presence || option["label"].presence || answer.answer_value.to_s if option

      likert_labels[answer.answer_value.to_s].presence || answer.answer_value.to_s
    end

    def question_kind_label(question)
      {
        "disc" => "Profil de travail",
        "interest" => "Intérêt",
        "skill" => "Compétence"
      }.fetch(question.kind.to_s, question.kind.to_s.humanize)
    end

    def no_contribution_text(question)
      case question.kind
      when "disc"
        "Cette dimension DISC ne fait pas partie des dimensions dominantes retenues."
      when "interest"
        "Cet intérêt n’est pas le champ dominant retenu pour le calcul."
      when "skill"
        "Cette compétence n’est pas requise par les métiers candidats affichés."
      else
        "Cette réponse n’a pas de contribution enregistrée."
      end
    end

    def affirmation_rows
      @attributions.flat_map do |attribution|
        Array(attribution.affirmation&.dig("checked_affirmations")).map do |text|
          { label: attribution.label, text: text, career_id: attribution.career.id }
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

    # DISC and interest points are a flat bonus applied once per matched
    # dimension/field (see PreScoringService), not summed per question — so
    # every question on that dimension shows the same badge without implying
    # the points stack. Skill points genuinely are per-question, so they keep
    # the plain "+N pts" display.
    def badge_content(question, points)
      case question.kind
      when "disc"
        disc_label = Diagnostics::Vocabulary::DISC_TYPES[question.disc_type] || question.disc_type
        {
          text: "+#{points} pts · dimension #{disc_label} retenue",
          rule: "Bonus forfaitaire DISC",
          tooltip: "Bonus forfaitaire de #{points} pts pour la dimension DISC dominante #{disc_label}, " \
                   "compté une seule fois pour ce métier (pas cumulé par question)."
        }
      when "interest"
        field_name = academic_field_name(question.academic_field_slug)
        {
          text: field_name ? "+#{points} pts · intérêt dominant (#{field_name})" : "+#{points} pts · intérêt dominant",
          rule: "Bonus forfaitaire intérêt",
          tooltip: "Bonus forfaitaire de #{points} pts pour le champ d'intérêt dominant, " \
                   "compté une seule fois pour ce métier (pas cumulé par question)."
        }
      else
        { text: "+#{points} pts", rule: "Points de réponse", tooltip: nil }
      end
    end

    def legacy_badge_text(question, points)
      case question.kind
      when "disc"
        disc_label = Diagnostics::Vocabulary::DISC_TYPES[question.disc_type] || question.disc_type
        "Dimension #{disc_label} retenue"
      when "interest"
        field_name = academic_field_name(question.academic_field_slug)
        field_name ? "Intérêt dominant retenu (#{field_name})" : "Intérêt dominant retenu"
      else
        "+#{points} pts"
      end
    end

    def likert_labels
      {
        "1" => "Pas du tout moi",
        "2" => "Plutôt pas moi",
        "3" => "Partiellement moi",
        "4" => "Plutôt moi",
        "5" => "Tout à fait moi"
      }
    end

    def academic_field_name(slug)
      @academic_field_names ||= AcademicField.pluck(:slug, :name).to_h
      @academic_field_names[slug]
    end
  end
end

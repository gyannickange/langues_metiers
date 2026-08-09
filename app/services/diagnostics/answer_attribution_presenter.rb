module Diagnostics
  class AnswerAttributionPresenter
    Attribution = Struct.new(:label, :career, :entry, keyword_init: true)

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
        entry = attribution.entry
        {
          label:                attribution.label,
          career:               attribution.career,
          retained:             true,
          base_total:           (entry["skill_score"].to_f * 0.4).round(2),
          bonus:                (entry["affirmation_score"].to_f * 0.6).round(2),
          total:                entry["final_score"].to_f.round(2),
          categories:           category_breakdown(attribution),
          has_affirmation_data: true
        }
      end
    end

    def score_summary
      overview_cards.map do |card|
        {
          label:      card[:label],
          career:     card[:career],
          score:      card[:total],
          base_score: card[:base_total],
          bonus:      card[:bonus],
          retained:   card[:retained]
        }
      end
    end

    def category_breakdown(attribution)
      entry = attribution.entry
      dominant_disc_count = Array(@score_data["dominant_disc_types"]).size

      [
        { label: "Filière académique", points: entry["academic_field_score"].to_f.round, max: 100 },
        { label: "Personnalité (DISC)", points: entry["disc_match_count"].to_i, max: dominant_disc_count },
        { label: "Compétences",         points: entry["skill_score"].to_f.round, max: 100 },
        { label: "Affirmations",        points: entry["affirmation_score"].to_f.round, max: 100 }
      ]
    end

    def badges_for(answer)
      question = answer.diagnostic_question
      return [] unless question

      @attributions.filter_map do |attribution|
        points = points_for(attribution, question)
        next unless points

        { label: attribution.label, text: badge_content(question)[:text], tooltip: badge_content(question)[:tooltip] }
      end
    end

    def contribution_details_for(answer)
      question = answer.diagnostic_question
      return [] unless question

      @attributions.filter_map do |attribution|
        points = points_for(attribution, question)
        next unless points

        badge_content(question).merge(label: attribution.label, career: attribution.career, points: points, contribution_type: :flat_bonus)
      end
    end

    def answer_value_label(answer)
      question = answer.diagnostic_question
      return likert_labels[answer.answer_value.to_s].presence || answer.answer_value.to_s unless question

      option = Array(question.options).find { |item| item.is_a?(Hash) && item["value"].to_s == answer.answer_value.to_s }
      return option["text"].presence || option["label"].presence || answer.answer_value.to_s if option

      likert_labels[answer.answer_value.to_s].presence || answer.answer_value.to_s
    end

    def question_kind_label(question)
      return "Affirmation métier" unless question

      {
        "disc" => "Profil de travail",
        "interest" => "Intérêt",
        "skill" => "Compétence"
      }.fetch(question.kind.to_s, question.kind.to_s.humanize)
    end

    def no_contribution_text(question)
      case question&.kind
      when "disc"
        "Ce type DISC ne fait pas partie des types dominants retenus."
      when "interest"
        "Cette filière ne fait pas partie des 2 filières dominantes retenues."
      when "skill"
        "Les compétences ne sont plus notées question par question : elles sont sélectionnées globalement à l’étape compétences."
      else
        "Cette réponse n’a pas de contribution enregistrée."
      end
    end

    def affirmation_rows
      @attributions.flat_map do |attribution|
        @diagnostic.diagnostic_answers.where(career_id: attribution.career.id).order(:affirmation_index).map do |answer|
          { label: attribution.label, text: "#{answer.affirmation_text} (#{answer.answer_value}/5)", career_id: attribution.career.id }
        end
      end
    end

    private

    def build_attributions
      retained = Array(@score_data["retained_careers"]).select { |h| h.is_a?(Hash) && h["career_id"].present? && h.key?("final_score") }
      return [] if retained.size < 2

      [ [ "Métier 1", @diagnostic.primary_career ], [ "Métier 2", @diagnostic.complementary_career ] ].filter_map do |label, career|
        next unless career

        entry = retained.find { |h| h["career_id"].to_s == career.id.to_s }
        next unless entry

        Attribution.new(label: label, career: career, entry: entry)
      end
    end

    def points_for(attribution, question)
      case question.kind
      when "disc"
        1 if Array(attribution.entry["matched_disc_types"]).include?(question.disc_type)
      when "interest"
        return nil unless Array(@score_data["dominant_academic_fields"]).include?(question.academic_field_slug)
        1 if attribution.career.academic_field_slug == question.academic_field_slug
      end
    end

    def badge_content(question)
      case question.kind
      when "disc"
        disc_label = Diagnostics::Vocabulary::DISC_TYPES[question.disc_type] || question.disc_type
        {
          text: "Type DISC #{disc_label} retenu",
          rule: "Filtre de personnalité",
          tooltip: "Ce métier a été retenu notamment parce que son profil DISC inclut le type dominant #{disc_label} de l’utilisateur."
        }
      when "interest"
        field_name = academic_field_name(question.academic_field_slug)
        {
          text: field_name ? "Filière dominante retenue (#{field_name})" : "Filière dominante retenue",
          rule: "Filtre d’intérêt",
          tooltip: "Ce métier appartient à l’une des 2 filières académiques dominantes de l’utilisateur."
        }
      else
        { text: nil, rule: nil, tooltip: nil }
      end
    end

    def likert_labels
      {
        "1" => "Pas du tout moi", "2" => "Plutôt pas moi", "3" => "Partiellement moi",
        "4" => "Plutôt moi", "5" => "Tout à fait moi"
      }
    end

    def academic_field_name(slug)
      @academic_field_names ||= AcademicField.pluck(:slug, :name).to_h
      @academic_field_names[slug]
    end
  end
end

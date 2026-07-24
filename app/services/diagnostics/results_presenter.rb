module Diagnostics
  class ResultsPresenter
    attr_reader :diagnostic, :primary, :secondary

    def initialize(diagnostic)
      @diagnostic = diagnostic
      @primary = diagnostic.primary_career
      @secondary = diagnostic.complementary_career
      @answers = diagnostic.diagnostic_answers.includes(:diagnostic_question).to_a
    end

    def primary_name
      primary&.title.presence || score_profile(:dominant_profile, "name") || "Profil principal indisponible"
    end

    def primary_description
      primary&.description.presence ||
        score_profile(:dominant_profile, "description") ||
        "Une description détaillée sera ajoutée dès que les informations de ce métier seront complètes."
    end

    def secondary_name
      secondary&.title.presence || score_profile(:secondary_profile, "name") || "Profil secondaire indisponible"
    end

    def secondary_description
      secondary&.description.presence ||
        score_profile(:secondary_profile, "description") ||
        "Une description détaillée sera ajoutée dès que les informations de ce métier seront complètes."
    end

    def sectors
      [ primary&.sector, secondary&.sector ].filter_map(&:presence).uniq
    end

    def key_skills
      labels = Diagnostics::Vocabulary.skill_labels_by_slug
      Array(primary&.required_skills).filter_map { |slug| labels[slug] }.uniq
    end

    def development_axes
      trajectory = primary&.active_trajectory
      return [] unless trajectory

      [ trajectory.axe_1, trajectory.axe_2, trajectory.axe_3 ].filter_map(&:presence)
    end

    def first_action
      primary&.first_action.presence
    end

    def explanation_factors
      factors = []
      score_data = diagnostic.score_data.is_a?(Hash) ? diagnostic.score_data : {}

      dominant_disc = Array(score_data["dominant_disc_types"]).filter_map do |type|
        Diagnostics::Vocabulary::DISC_TYPES[type.to_s]
      end
      if dominant_disc.any?
        factors << {
          key: :disc,
          title: "Votre manière de travailler",
          text: "Votre profil met en avant #{dominant_disc.to_sentence}, ce qui donne une indication sur l’environnement de travail dans lequel vous pouvez être à l’aise."
        }
      end

      if (field = academic_field_name(score_data["dominant_academic_field"]))
        factors << {
          key: :interest,
          title: "Vos centres d’intérêt",
          text: "Votre intérêt pour le domaine « #{field} » a renforcé les métiers qui s’y rattachent."
        }
      end

      skills = key_skills.first(3)
      if skills.any?
        factors << {
          key: :skills,
          title: "Les compétences mobilisées",
          text: "Les compétences associées à ce métier comprennent notamment #{skills.to_sentence}."
        }
      end

      checked_affirmations = Array(score_data.dig("affirmation_breakdown", primary&.id.to_s, "checked_affirmations"))
      if checked_affirmations.any?
        factors << {
          key: :affirmations,
          title: "Votre validation finale",
          text: "Vous avez également reconnu des situations qui vous correspondent dans ce métier."
        }
      end

      factors
    end

    def reading_guide
      "Votre résultat croise plusieurs signaux : il ne s’agit ni d’une note scolaire, ni d’un test où chaque réponse est simplement vraie ou fausse."
    end

    def score_explanation_available?
      score_data = diagnostic.score_data
      score_data.is_a?(Hash) && score_data["top_career_ids"].is_a?(Array) && score_data["top_career_ids"].any? { |entry| entry.is_a?(Hash) && entry.key?("disc_match") }
    end

    def answer_summary
      @answers.sort_by { |answer| answer.diagnostic_question&.position.to_i }.filter_map do |answer|
        question = answer.diagnostic_question
        next unless question

        {
          kind: answer_kind_label(question),
          question: question.text,
          value: answer.answer_value,
          label: response_label(question, answer.answer_value)
        }
      end
    end

    private

    def academic_field_name(slug)
      return nil if slug.blank?

      AcademicField.find_by(slug: slug)&.name || slug.to_s.humanize
    end

    def answer_kind_label(question)
      {
        "disc" => "Profil de travail",
        "interest" => "Intérêt",
        "skill" => "Compétence"
      }.fetch(question.kind.to_s, question.kind.to_s.humanize)
    end

    def response_label(question, value)
      option = Array(question.options).find { |item| item.is_a?(Hash) && item["value"].to_s == value.to_s }
      return option["text"].presence || option["label"].presence || value.to_s if option

      {
        "1" => "Pas du tout moi",
        "2" => "Plutôt pas moi",
        "3" => "Partiellement moi",
        "4" => "Plutôt moi",
        "5" => "Tout à fait moi"
      }.fetch(value.to_s, value.to_s)
    end

    def score_profile(key, attribute)
      score_data = diagnostic.score_data
      return unless score_data.is_a?(Hash)

      profile = score_data[key.to_s] || score_data[key.to_sym]
      return unless profile.is_a?(Hash)

      (profile[attribute] || profile[attribute.to_sym]).presence
    end
  end
end

module Diagnostics
  class ResultsPresenter
    attr_reader :diagnostic, :primary, :secondary

    def initialize(diagnostic)
      @diagnostic = diagnostic
      @primary = diagnostic.primary_career
      @secondary = diagnostic.complementary_career
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
      Array(primary&.key_skills).filter_map { |skill| skill.to_s.presence }.uniq
    end

    def development_axes
      trajectory = primary&.active_trajectory
      return [] unless trajectory

      [ trajectory.axe_1, trajectory.axe_2, trajectory.axe_3 ].filter_map(&:presence)
    end

    def first_action
      primary&.first_action.presence
    end

    private

    def score_profile(key, attribute)
      score_data = diagnostic.score_data
      return unless score_data.is_a?(Hash)

      profile = score_data[key.to_s] || score_data[key.to_sym]
      return unless profile.is_a?(Hash)

      (profile[attribute] || profile[attribute.to_sym]).presence
    end
  end
end

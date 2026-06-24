class Career < ApplicationRecord
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :published
  enum :kind, { behavioral: "behavioral", profession: "profession" }, default: "behavioral"

  scope :diagnostic, -> { where.not(filiere_slug: nil) }

  has_many :trajectories, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :slug, uniqueness: true, presence: true, if: :behavioral?

  validates :filiere_slug,
            inclusion: { in: ->(_record) { Diagnostics::Vocabulary.filiere_slugs }, message: "n'est pas une filière valide" },
            allow_blank: true
  validate :diagnostic_arrays_within_vocabulary

  before_validation :parameterize_slug, if: :behavioral?
  before_validation :normalize_diagnostic_arrays

  def affirmations_text
    Array(affirmations).join("\n")
  end

  def affirmations_text=(value)
    self.affirmations = split_lines(value)
  end

  def key_skills_text
    Array(key_skills).join("\n")
  end

  def key_skills_text=(value)
    self.key_skills = split_lines(value)
  end

  def active_trajectory
    trajectories.active.last
  end

  private

  def parameterize_slug
    self.slug = slug.parameterize if slug.present?
  end

  def split_lines(value)
    value.to_s.split("\n").map(&:strip).reject(&:blank?)
  end

  def normalize_diagnostic_arrays
    self.disc_types           = Array(disc_types).map(&:to_s).reject(&:blank?)
    self.required_competences = Array(required_competences).map(&:to_s).reject(&:blank?)
  end

  def diagnostic_arrays_within_vocabulary
    invalid_disc = disc_types - Diagnostics::Vocabulary.disc_type_slugs
    if invalid_disc.any?
      errors.add(:disc_types, "contient des valeurs invalides : #{invalid_disc.join(', ')}")
    end

    invalid_comp = required_competences - Diagnostics::Vocabulary.competence_slugs
    if invalid_comp.any?
      errors.add(:required_competences, "contient des valeurs invalides : #{invalid_comp.join(', ')}")
    end
  end
end

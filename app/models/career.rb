class Career < ApplicationRecord
  has_paper_trail

  enum :status, { draft: 0, published: 1, archived: 2 }, default: :published
  enum :kind, { behavioral: "behavioral", profession: "profession" }, default: "behavioral"

  scope :diagnostic, -> { where.not(academic_field_slug: nil) }

  has_many :trajectories, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :slug, uniqueness: true, presence: true, if: :behavioral?

  validates :academic_field_slug,
            inclusion: { in: ->(_record) { Diagnostics::Vocabulary.academic_field_slugs }, message: "is not a valid academic field" },
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
    self.required_skills = Array(required_skills).map(&:to_s).reject(&:blank?)
  end

  def diagnostic_arrays_within_vocabulary
    invalid_disc = disc_types - Diagnostics::Vocabulary.disc_type_slugs
    if invalid_disc.any?
      errors.add(:disc_types, "contient des valeurs invalides : #{invalid_disc.join(', ')}")
    end

    invalid_skills = required_skills - Diagnostics::Vocabulary.skill_slugs
    if invalid_skills.any?
      errors.add(:required_skills, "contient des valeurs invalides : #{invalid_skills.join(', ')}")
    end
  end
end

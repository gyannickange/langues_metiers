class Field < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  enum :status, { inactive: 0, active: 1 }, default: :active

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, uniqueness: true, allow_nil: true

  has_many :roadmap_fields, dependent: :destroy
  has_many :roadmaps, through: :roadmap_fields

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end
end

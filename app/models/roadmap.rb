class Roadmap < ApplicationRecord
  has_many :roadmap_fields, dependent: :destroy
  has_many :fields, through: :roadmap_fields

  has_many :roadmap_steps, dependent: :destroy

  accepts_nested_attributes_for :roadmap_steps,
    allow_destroy: true,
    reject_if: proc { |attrs|
      attrs["title"].blank? && attrs["objective"].blank? && attrs["skills"].blank? && attrs["activities"].blank?
    }

  validates :title, presence: true
  validates :description, presence: true

  scope :ordered, -> { order(:created_at) }
end

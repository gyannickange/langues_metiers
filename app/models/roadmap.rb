class Roadmap < ApplicationRecord
  has_many :roadmap_fields, dependent: :destroy
  has_many :fields, through: :roadmap_fields

  has_many :roadmap_steps, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true

  scope :ordered, -> { order(:created_at) }
end

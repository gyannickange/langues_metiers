class Assessment < ApplicationRecord
  has_many :diagnostic_questions, -> { order(:position) }, dependent: :destroy
  has_many :diagnostics, dependent: :nullify

  validates :title, presence: true

  before_save :ensure_single_active, if: -> { active_changed? && active? }

  private

  def ensure_single_active
    Assessment.where.not(id: id).update_all(active: false)
  end
end

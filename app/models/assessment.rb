class Assessment < ApplicationRecord
  has_many :assessment_questions, -> { order(:bloc, :position) }, dependent: :destroy
  has_many :diagnostics, dependent: :nullify

  validates :title, presence: true

  before_save :ensure_single_active, if: -> { active_changed? && active? }

  def total_blocs
    assessment_questions.maximum(:bloc) || 1
  end

  private

  def ensure_single_active
    Assessment.where.not(id: id).update_all(active: false)
  end
end

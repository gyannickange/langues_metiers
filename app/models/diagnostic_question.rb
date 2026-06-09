class DiagnosticQuestion < ApplicationRecord
  belongs_to :assessment
  has_many :diagnostic_answers, dependent: :nullify

  enum :kind, { disc: "disc", interest: "interest", competence: "competence" }

  validates :text,     presence: true
  validates :kind,     presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :disc_type, inclusion: { in: %w[D I S C] }, allow_nil: true
  validate  :kind_specific_fields_present

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position) }

  private

  def kind_specific_fields_present
    case kind
    when "disc"
      errors.add(:disc_type, "ne peut pas être vide") if disc_type.blank?
    when "interest"
      errors.add(:options, "ne peut pas être vide") if options.blank?
    when "competence"
      errors.add(:competence_slug, "ne peut pas être vide") if competence_slug.blank?
    end
  end
end

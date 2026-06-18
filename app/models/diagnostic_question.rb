class DiagnosticQuestion < ApplicationRecord
  attr_writer :options_json

  belongs_to :assessment
  has_many :diagnostic_answers, dependent: :nullify

  enum :kind, { disc: "disc", interest: "interest", competence: "competence" }

  validates :text,     presence: true
  validates :kind,     presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :disc_type, inclusion: { in: %w[D I S C] }, allow_nil: true
  validate  :parse_options_json
  validate  :kind_specific_fields_present

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position) }

  def options_json
    @options_json.nil? ? options.to_json : @options_json
  end

  def competence_label
    return nil unless options.is_a?(Array)

    first = options.first
    first.is_a?(Hash) ? first["label"] : nil
  end

  def competence_label=(value)
    self.options = value.to_s.strip.present? ? [ { "label" => value.to_s.strip } ] : []
  end

  private

  def parse_options_json
    return if @options_json.nil?

    self.options = @options_json.blank? ? [] : JSON.parse(@options_json)
  rescue JSON::ParserError => error
    errors.add(:options_json, "JSON invalide : #{error.message}")
  end

  def kind_specific_fields_present
    case kind
    when "disc"
      errors.add(:disc_type, "ne peut pas être vide") if disc_type.blank?
    when "interest"
      errors.add(:filiere_slug, "ne peut pas être vide") if filiere_slug.blank?
    when "competence"
      errors.add(:competence_slug, "ne peut pas être vide") if competence_slug.blank?
    end
  end
end

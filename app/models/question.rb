class Question < ApplicationRecord
  belongs_to :questionnaire, optional: true
  KINDS = %w[likert mcq].freeze

  attr_writer :options_string
  attr_accessor :parsed_options

  scope :active,   -> { where(active: true) }
  scope :scored,   -> { where(scored: true) }
  scope :by_bloc,  ->(b) { where(bloc: b).order(:position) }

  validates :bloc,     presence: true
  validates :text,     presence: true
  validates :kind,     presence: true, inclusion: { in: KINDS }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 1 }

  before_validation :set_default_position, on: :create
  before_validation :process_options

  def options_string
    @options_string || (options.present? ? JSON.pretty_generate(options) : "")
  end

  private

  def process_options
    if parsed_options.present? && parsed_options.is_a?(Array)
      self.options = parsed_options.reject { |opt| opt[:text].blank? || opt[:label].blank? }.map do |opt|
        {
          "text"         => opt[:text],
          "label"        => opt[:label],
          "value"        => opt[:value].presence || opt[:label],
          "points"       => opt[:points].to_i,
          "profile_slug" => opt[:profile_slug].presence
        }.compact
      end
    elsif @options_string.present?
      begin
        self.options = JSON.parse(@options_string)
      rescue JSON::ParserError
        self.options = @options_string.split(",").map(&:strip).reject(&:blank?)
      end
    end
  end

  def set_default_position
    return if position.present? && position > 0

    max_pos = Question.where(questionnaire_id: questionnaire_id, bloc: bloc).maximum(:position) || 0
    self.position = max_pos + 1
  end
end

class Question < ApplicationRecord
  KINDS = %w[likert mcq].freeze

  scope :active,   -> { where(active: true) }
  scope :scored,   -> { where(scored: true) }
  scope :by_bloc,  ->(b) { where(bloc: b).order(:position) }

  validates :bloc,     presence: true, inclusion: { in: 1..5 }
  validates :text,     presence: true
  validates :kind,     presence: true, inclusion: { in: KINDS }
  validates :position, presence: true
end

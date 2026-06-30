class Trajectory < ApplicationRecord
  has_paper_trail

  belongs_to :career

  scope :active, -> { where(active: true) }
end

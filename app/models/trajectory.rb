class Trajectory < ApplicationRecord
  belongs_to :career

  scope :active, -> { where(active: true) }
end

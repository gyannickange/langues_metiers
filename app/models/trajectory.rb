class Trajectory < ApplicationRecord
  belongs_to :profile

  scope :active, -> { where(active: true) }
end

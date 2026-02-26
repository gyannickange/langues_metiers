class Profile < ApplicationRecord
  has_many :trajectories, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def active_trajectory
    trajectories.active.last
  end
end

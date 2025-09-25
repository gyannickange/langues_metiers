class RoadmapStep < ApplicationRecord
  belongs_to :roadmap

  validates :title, presence: true
  validates :objective, presence: true
  validates :order, presence: true, uniqueness: { scope: :roadmap_id }

  scope :ordered, -> { order(:order) }

  def next_step
    roadmap.roadmap_steps.where("order > ?", order).ordered.first
  end

  def previous_step
    roadmap.roadmap_steps.where("order < ?", order).order(order: :desc).first
  end
end

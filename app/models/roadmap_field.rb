class RoadmapField < ApplicationRecord
  belongs_to :roadmap
  belongs_to :field

  validates :roadmap_id, uniqueness: { scope: :field_id }
end

class AcademicField < ApplicationRecord
  has_paper_trail

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
end

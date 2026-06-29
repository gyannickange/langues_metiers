class AcademicField < ApplicationRecord
  has_paper_trail

  before_create { self.position ||= (AcademicField.maximum(:position) || 0) + 1 }

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
end

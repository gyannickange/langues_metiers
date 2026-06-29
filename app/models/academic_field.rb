class AcademicField < ApplicationRecord
  has_paper_trail

  include Sluggable
  slug_source :name

  before_create { self.position ||= (AcademicField.maximum(:position) || 0) + 1 }

  validates :name, presence: true
end

class Skill < ApplicationRecord
  has_and_belongs_to_many :categories
  has_many :user_skills, dependent: :destroy
  has_many :users, through: :user_skills

  validates :name, presence: true
end

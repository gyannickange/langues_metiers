class UserSkill < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  enum :level, { beginner: 0, intermediate: 1, advanced: 2 }, default: :beginner

  validates :level, presence: true
  validates :user_id, uniqueness: { scope: :skill_id }
end

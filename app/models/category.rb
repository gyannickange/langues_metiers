class Category < ApplicationRecord
  has_and_belongs_to_many :skills

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: %w[soft digital language] }
end

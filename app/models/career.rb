class Career < ApplicationRecord
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  validates :title, presence: true
  validates :status, presence: true
end

class Career < ApplicationRecord
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :published
  enum :kind, { behavioral: "behavioral", profession: "profession" }, default: "behavioral"

  has_many :trajectories, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :slug, uniqueness: true, presence: true, if: :behavioral?

  before_validation :parameterize_slug, if: :behavioral?

  def active_trajectory
    trajectories.active.last
  end

  private

  def parameterize_slug
    self.slug = slug.parameterize if slug.present?
  end
end

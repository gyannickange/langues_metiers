module Sluggable
  extend ActiveSupport::Concern

  included do
    class_attribute :slug_source_attribute
    before_validation :generate_slug
    validates :slug, presence: true, uniqueness: true
  end

  class_methods do
    def slug_source(attribute)
      self.slug_source_attribute = attribute
    end
  end

  private

  def generate_slug
    return if slug.present?

    base = public_send(slug_source_attribute).to_s.parameterize(separator: "_")
    return if base.blank?

    candidate = base
    suffix = 2
    while self.class.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base}_#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end

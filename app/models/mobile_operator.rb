class MobileOperator < ApplicationRecord
  scope :active,     -> { where(active: true) }
  scope :by_country, ->(code) { where(country_code: code.to_s.upcase) }

  validates :name, :code, :country_code, presence: true
end

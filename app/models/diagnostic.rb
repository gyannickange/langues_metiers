class Diagnostic < ApplicationRecord
  belongs_to :user
  belongs_to :primary_profile,       class_name: "Profile", optional: true
  belongs_to :complementary_profile, class_name: "Profile", optional: true
  has_many   :diagnostic_answers, dependent: :destroy
  has_one    :payment, dependent: :destroy
  has_one_attached :pdf_report

  enum :status, {
    pending_payment: 0,
    paid:            1,
    in_progress:     2,
    completed:       3
  }

  enum :payment_provider, {
    stripe:  0,
    pawapay: 1
  }, prefix: :provider

  def self.price
    Rails.env.production? ? 2000 : 0
  end

  def self.formatted_price
    "#{price.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1 ')} F CFA"
  end
end

class Diagnostic < ApplicationRecord
  STANDARD_PRICE = 2_000
  TEST_PRICE = 0

  belongs_to :user
  belongs_to :assessment, optional: true

  belongs_to :primary_career,       class_name: "Career", optional: true
  belongs_to :complementary_career, class_name: "Career", optional: true
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

  after_commit :schedule_abandonment_reminders, on: [ :create, :update ], if: -> { saved_change_to_status? && in_progress? }

  def self.price
    TEST_PRICE
  end

  def self.standard_price
    STANDARD_PRICE
  end

  def self.formatted_amount(amount = price)
    amount.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1 ')
  end

  def self.formatted_price
    "#{formatted_amount} F CFA"
  end

  def self.formatted_standard_price
    "#{formatted_amount(standard_price)} F CFA"
  end

  def pdf_generated?
    pdf_report.attached?
  end

  private

  def schedule_abandonment_reminders
    DiagnosticReminderJob.set(wait: 30.minutes).perform_later(id, "30m")
    DiagnosticReminderJob.set(wait: 1.hour).perform_later(id, "1h")
    DiagnosticReminderJob.set(wait: 1.day).perform_later(id, "1d")
  end
end

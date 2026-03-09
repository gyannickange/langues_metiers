class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :diagnostic

  enum :provider, { stripe: 0, pawapay: 1 }
  enum :status,   { pending: 0, confirmed: 1, failed: 2 }

  validates :provider, presence: true
end

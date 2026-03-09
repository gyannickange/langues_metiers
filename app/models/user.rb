class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :facebook ]

  enum :role, { user: 0, admin: 1 }, default: :user

  has_many :user_skills, dependent: :destroy
  has_many :skills, through: :user_skills
  has_many :diagnostics, dependent: :destroy
  has_many :payments,    dependent: :destroy

  def onboarded?
    return true if admin?

    first_name.present? && last_name.present? && city.present? && country.present? && diploma.present? && employment_status.present?
  end

  def generate_otp!
    self.otp_code = rand(100_000..999_999).to_s
    self.otp_sent_at = Time.current
    save!(validate: false)
  end

  def otp_valid?(code)
    return false if otp_code.blank? || otp_sent_at.nil?
    return false if Time.current > otp_sent_at + 10.minutes

    otp_code == code.to_s
  end

  def clear_otp!
    update_columns(otp_code: nil, otp_sent_at: nil)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create! do |user|
      user.email = auth.info.email
      # If the model has a required password for standard devise registration:
      user.password = Devise.friendly_token[0, 20]
    end
  end
end

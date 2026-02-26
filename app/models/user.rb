class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { user: 0, admin: 1 }, default: :user

  has_many :user_skills, dependent: :destroy
  has_many :skills, through: :user_skills
  has_many :diagnostics, dependent: :destroy
  has_many :payments,    dependent: :destroy
end

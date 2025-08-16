module Api
  module V1
    class ProfilesController < ApplicationController
      before_action :authenticate_user!
      protect_from_forgery with: :null_session

      def show
        user = current_user
        render json: {
          id: user.id,
          email: user.email,
          role: user.role,
          skills: user.user_skills.includes(:skill).map { |us| { id: us.skill.id, name: us.skill.name, level: us.level } }
        }
      end
    end
  end
end

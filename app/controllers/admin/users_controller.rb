module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show update]

    def index
      @pagy, @users = pagy(User.order(created_at: :desc))
    end

    def show
    end

    def update
      requested_role = role_param

      unless User.roles.key?(requested_role)
        @user.errors.add(:role, :inclusion)
        return render :show, status: :unprocessable_content
      end

      @user.role = requested_role

      if @user.save
        redirect_to admin_user_path(@user), notice: "Rôle mis à jour."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_user
      @user = User.includes(:skills, :diagnostics, :payments).find(params[:id])
    end

    def role_param
      params.require(:user).fetch(:role).to_s
    end
  end
end

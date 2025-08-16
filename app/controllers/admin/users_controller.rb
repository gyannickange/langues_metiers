module Admin
  class UsersController < BaseController
    def index
      @pagy, @users = pagy(User.order(created_at: :desc))
    end
  end
end

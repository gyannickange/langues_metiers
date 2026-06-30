module Admin
  class DashboardController < BaseController
    def index
      @diagnostics_count = Diagnostic.count
      @users_count = User.count
      @skills_count = Skill.count
      @careers_count = Career.count
    end
  end
end

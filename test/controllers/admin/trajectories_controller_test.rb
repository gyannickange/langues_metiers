require "test_helper"

class Admin::TrajectoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
    @metier = Career.create!(title: "Métier #{SecureRandom.hex(4)}", status: :published, kind: :profession)
  end

  test "create attaches a trajectory to a profession career" do
    assert_difference "Trajectory.count", 1 do
      post admin_trajectories_path, params: { trajectory: {
        career_id: @metier.id, axe_1: "A1", axe_2: "A2", axe_3: "A3", active: true
      } }
    end
    assert_redirected_to admin_trajectories_path
    assert_equal @metier.id, Trajectory.order(:created_at).last.career_id
  end

  test "new form lists profession careers in the select" do
    get new_admin_trajectory_path
    assert_response :success
    assert_select "select[name='trajectory[career_id]'] optgroup[label='Métiers'] option", text: @metier.title
  end

  test "destroy redirects with see_other so Turbo does not replay the DELETE" do
    trajectory = Trajectory.create!(career: @metier, axe_1: "A1", axe_2: "A2", axe_3: "A3", active: true)

    delete admin_trajectory_path(trajectory)

    assert_response :see_other
    assert_redirected_to admin_trajectories_path
  end

  test "index paginates the trajectories" do
    25.times { |i| Trajectory.create!(career: @metier, axe_1: "A#{i}", axe_2: "A2", axe_3: "A3", active: true) }

    get admin_trajectories_path

    assert_response :success
    assert_select "nav[aria-label='Pagination']"
    assert_no_match "translation missing", response.body
  end
end

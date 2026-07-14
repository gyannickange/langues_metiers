require "test_helper"

class UserTest < ActiveSupport::TestCase
  def omniauth_data(provider:, uid:, email:, first_name:, last_name:)
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, first_name: first_name, last_name: last_name }
    )
  end

  test "from_omniauth sets first_name and last_name on a new user" do
    auth = omniauth_data(provider: "google_oauth2", uid: "12345", email: "new#{SecureRandom.hex(4)}@test.com",
      first_name: "Ada", last_name: "Lovelace")

    user = User.from_omniauth(auth)

    assert_equal "Ada", user.first_name
    assert_equal "Lovelace", user.last_name
  end

  test "from_omniauth does not overwrite an existing user's first_name and last_name" do
    uid = "existing-#{SecureRandom.hex(4)}"
    existing = User.create!(email: "existing#{SecureRandom.hex(4)}@test.com", password: "password123",
      provider: "google_oauth2", uid: uid, first_name: "Original", last_name: "Name")

    auth = omniauth_data(provider: "google_oauth2", uid: uid, email: existing.email,
      first_name: "Different", last_name: "Person")

    user = User.from_omniauth(auth)

    assert_equal existing.id, user.id
    assert_equal "Original", user.first_name
    assert_equal "Name", user.last_name
  end

  test "from_omniauth links an existing passwordless user by email" do
    existing = User.create!(email: "passwordless#{SecureRandom.hex(4)}@test.com", password: "password123",
      first_name: "Existing", last_name: "User")
    auth = omniauth_data(provider: "google_oauth2", uid: "google-#{SecureRandom.hex(4)}", email: existing.email,
      first_name: "Google", last_name: "Profile")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth)

      assert_equal existing.id, user.id
      assert_equal "google_oauth2", user.provider
      assert_equal auth.uid, user.uid
      assert_equal "Existing", user.first_name
      assert_equal "User", user.last_name
    end
  end

  test "from_omniauth creates a user with blank names when the provider omits them" do
    auth = omniauth_data(provider: "google_oauth2", uid: "no-name-#{SecureRandom.hex(4)}",
      email: "noname#{SecureRandom.hex(4)}@test.com", first_name: nil, last_name: nil)

    user = User.from_omniauth(auth)

    assert user.persisted?
    assert_nil user.first_name
    assert_nil user.last_name
  end

  test "versions when role changes" do
    user = User.create!(email: "user#{SecureRandom.hex(4)}@test.com", password: "password123")

    assert_difference -> { user.versions.count }, 1 do
      user.update!(role: :admin)
    end
  end

  test "does not version unrelated attribute changes" do
    user = User.create!(email: "user#{SecureRandom.hex(4)}@test.com", password: "password123")

    assert_no_difference -> { user.versions.count } do
      user.update!(first_name: "Updated")
    end
  end
end

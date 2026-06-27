require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "routes the known statuses to ErrorsController#show" do
    %w[400 404 422 500].each do |status|
      assert_recognizes(
        { controller: "errors", action: "show", status: status },
        path: "/#{status}", method: :get
      )
    end
  end

  test "renders the branded 404 page via exceptions_app for an unrouted path" do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    get "/this-path-does-not-exist"

    assert_response :not_found
    assert_select "h1", "Page introuvable"
  ensure
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = true
  end
end

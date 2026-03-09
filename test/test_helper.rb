ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "minitest/mock"
require "ostruct"

# Provide a modern User-Agent so allow_browser versions: :modern doesn't block requests
class ActionDispatch::IntegrationTest
  setup do
    @default_headers = {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
  end
end

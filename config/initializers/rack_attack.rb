class Rack::Attack
  throttle("otp_verify/ip", limit: 5, period: 5.minutes) do |req|
    req.ip if req.path == "/login/verify_otp" && req.post?
  end

  throttle("otp_verify/email", limit: 5, period: 5.minutes) do |req|
    if req.path == "/login/verify_otp" && req.post?
      req.params["email"].to_s.downcase.strip.presence
    end
  end

  throttle("otp_request/ip", limit: 5, period: 5.minutes) do |req|
    req.ip if req.path == "/login/request_otp" && req.post?
  end

  throttle("otp_request/email", limit: 3, period: 5.minutes) do |req|
    if req.path == "/login/request_otp" && req.post?
      req.params["email"].to_s.downcase.strip.presence
    end
  end

  throttle("admin/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/admin")
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "text/plain" }, [ "Too many requests. Please try again shortly.\n" ] ]
  end
end

Rack::Attack.enabled = !Rails.env.test?

Rails.application.config.middleware.use Rack::Attack

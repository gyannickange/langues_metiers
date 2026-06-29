class ApplicationMailer < ActionMailer::Base
  default from: "alice@insertrix.com"
  layout "mailer"
end

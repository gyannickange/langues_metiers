class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.otp_email.subject
  #
  def otp_email
    @user = params[:user]
    @otp_code = @user.otp_code

    mail(to: @user.email, subject: "Ton code de connexion Insertrice")
  end
end

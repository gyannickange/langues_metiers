class Users::SessionsController < Devise::SessionsController
  layout "auth"

  # GET /login
  def new
    super
  end

  # POST /login/request_otp
  def request_otp
    email = params[:email].to_s.downcase.strip
    redirect_to_url = params[:redirect_to]

    if email.blank?
      flash[:alert] = "L'adresse e-mail est requise."
      return redirect_to new_user_session_path(redirect_to: redirect_to_url)
    end

    user = User.find_by(email: email)

    if user.nil?
      user = User.new(email: email)
      user.password = Devise.friendly_token[0, 20]
      unless user.save
        flash[:alert] = "Impossible de créer le compte pour le moment."
        return redirect_to new_user_session_path(redirect_to: redirect_to_url)
      end
    end

    user.generate_otp!
    UserMailer.with(user: user).otp_email.deliver_now

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("auth_flow", partial: "users/sessions/verify_otp", locals: { email: user.email, redirect_to: redirect_to_url })
      end
      format.html { render :verify_otp, locals: { email: user.email, redirect_to: redirect_to_url } }
    end
  end

  # POST /login/verify_otp
  def verify_otp
    email = params[:email].to_s.downcase.strip
    code = params[:otp_code].to_s.strip
    redirect_to_url = params[:redirect_to]

    user = User.find_by(email: email)

    if user&.otp_valid?(code)
      user.clear_otp!
      sign_in(user)

      # Redirect using the provided param safely, overriding internal tracking
      if redirect_to_url.present? && redirect_to_url.start_with?("/")
        redirect_to redirect_to_url, notice: "Connexion réussie.", status: :see_other
      else
        redirect_to after_sign_in_path_for(user), notice: "Connexion réussie.", status: :see_other
      end
    else
      flash.now[:alert] = "Code incorrect ou expiré."
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("auth_flow", partial: "users/sessions/verify_otp", locals: { email: email, redirect_to: redirect_to_url })
        end
        format.html { render :verify_otp, locals: { email: email, redirect_to: redirect_to_url } }
      end
    end
  end
end

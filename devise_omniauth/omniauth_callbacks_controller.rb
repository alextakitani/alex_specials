class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def create_or_login_from_provider
    user = User.from_omniauth(request.env["omniauth.auth"])
    if user.persisted?
      flash.notice = "Signed in!"
      sign_in_and_redirect user
    else
      session["devise.user_attributes"] = user.attributes
      redirect_to new_user_registration_url, :notice => "Por favor, complete os seus dados."
    end
  end
  
end

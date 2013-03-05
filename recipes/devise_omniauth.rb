prefs[:devise_omniauth_twitter] = yes_wizard?("Use Twitter?") if prefs[:devise_omniauth_twitter].blank?

prefs[:devise_omniauth_facebook] = yes_wizard?("Use Facebook?") if prefs[:devise_omniauth_facebook].blank?

prefs[:devise_omniauth_google] = yes_wizard?("Use Google?") if prefs[:devise_omniauth_google].blank?

gem 'omniauth' if prefs[:devise_omniauth_twitter] || prefs[:devise_omniauth_facebook]

gem 'omniauth-facebook' if prefs[:devise_omniauth_facebook]

gem 'omniauth-twitter' if prefs[:devise_omniauth_twitter]

if prefs[:devise_omniauth_google]
	gem 'oauth2'
	gem 'omniauth-google-oauth2'
end



after_bundler do

	say_wizard "adding oauth database fields to user"
	generate 'migration AddDeviseOauthToUsers provider:string uid:string'

	say_wizard "modifying routes"
	insert_into_file 'config/routes.rb', " ,controllers: {omniauth_callbacks: 'omniauth_callbacks'} " , :after=>"devise_for :users"
	
	say_wizard "setting-up controllers"
	copy_from 'https://raw.github.com/alextakitani/alex_specials/master/devise_omniauth/omniauth_callbacks_controller.rb', 'app/controllers/omniauth_callbacks_controller.rb'
	controller_text = <<TEXT
	\n
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
TEXT

	controller_text << "\n\talias_method :twitter, :create_or_login_from_provider" if prefs[:devise_omniauth_twitter]
	controller_text << "\n\talias_method :facebook, :create_or_login_from_provider" if prefs[:devise_omniauth_facebook]

	insert_into_file 'app/controllers/omniauth_callbacks_controller.rb' , controller_text , :after=>"Devise::OmniauthCallbacksController" 
	 
 	say_wizard "adding methods to the user model"
	methods_text = <<TEXT
	\n\t
	def password_required?
    super && provider.blank?
  end

  def self.new_with_session(params, session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"], without_protection: true) do |user|
        user.attributes = params
        #gambis tuiter
        if session["devise.user_attributes"]["tmp_url"]
          user.remote_avatar_url = session["devise.user_attributes"]["tmp_url"]
        end
        user.valid?
      end
    else
      super
    end
  end

  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid

      if auth.provider == "facebook"
        user.email = auth.info.email
        user.remote_avatar_url = auth.info.image
      end

      if auth.provider == "twitter"
        user.tmp_url = auth.info.image
      end

      user.username = auth.info.nickname
    end
  end
  \n
TEXT

	insert_into_file 'app/models/user.rb', methods_text , :before=>"end"
	insert_into_file 'app/models/user.rb', " :omniauthable, ", :before=>":database_authenticatable"
	insert_into_file 'app/models/user.rb', " :provider, :uid, ", :after=>"attr_accessible"

	say_wizard "configuring devise initializer"
	insert_into_file "config/initializers/devise.rb", "\n\tconfig.omniauth :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']", :before=>"# When using omniauth" if prefs[:devise_omniauth_twitter]
	insert_into_file "config/initializers/devise.rb", "\n\tconfig.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']", :before=>"# When using omniauth" if prefs[:devise_omniauth_facebook]

	say_wizard "adding keys to application.yml"
	append_to_file "config/application.yml", "\nTWITTER_CONSUMER_KEY: xxx\nTWITTER_CONSUMER_SECRET: xxx\n"  if prefs[:devise_omniauth_twitter]
	append_to_file "config/application.yml", "\nFACEBOOK_APP_ID: XXX\nFACEBOOK_APP_SECRET: XXX\n"  if prefs[:devise_omniauth_facebook]

end

__END__

name: devise_omniauth
description: "configure devise to work with omniauth providers"
author: alextakitani

requires: [core]
run_after: [setup, extras, alex_specials]
category: configuration
prefs[:devise_omniauth_twitter] = yes_wizard?("Use Twitter?") unless prefs[:devise_omniauth_twitter]

prefs[:devise_omniauth_facebook] = yes_wizard?("Use Facebook?") unless prefs[:devise_omniauth_facebook]

prefs[:devise_omniauth_google] = yes_wizard?("Use Google?") unless prefs[:devise_omniauth_google]

gem 'omniauth' if prefs[:devise_omniauth_twitter] || prefs[:devise_omniauth_facebook]

gem 'omniauth-facebook' if prefs[:devise_omniauth_facebook]

gem 'omniauth-twitter' if prefs[:devise_omniauth_twitter]

if prefs[:devise_omniauth_google]
	gem 'oauth2'
	gem 'omniauth-google-oauth2'
end

after_bundler do

	say_wizard "setting-up controllers"
	copy_from 'https://raw.github.com/alextakitani/alex_specials/master/devise_omniauth/omniauth_callbacks_controller.rb', 'app/controllers/omniauth_callbacks_controller.rb'

	inject_into_class 'app/controllers/omniauth_callbacks_controller.rb' , OmniauthCallbacksController, "\n\talias_method :twitter, :create_or_login_from_provider" if prefs[:devise_omniauth_twitter]
	inject_into_class 'app/controllers/omniauth_callbacks_controller.rb' , OmniauthCallbacksController, "\n\talias_method :facebook, :create_or_login_from_provider" if prefs[:devise_omniauth_facebook]
 
end

__END__

name: devise_omniauth
description: "configure devise to work with omniauth providers"
author: alextakitani

requires: [core]
run_after: [setup, extras, alex_specials]
category: configuration
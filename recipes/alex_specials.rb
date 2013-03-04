prefs[:hstore] = yes_wizard?("use hstore?") if prefs[:database] == 'postgresql'

prefs[:locale] = multiple_choice "Default Locale?", [["En (default)", "en"],  ["pt-BR", "pt-BR"]] unless prefs.has_key? :locale

say_wizard "recipe setting capistrano for deployment"
gem 'capistrano', '>= 2.14.2', :group => :development
gem 'rvm-capistrano', '>= 1.2.7', :group => :development

say_wizard "recipe setting turbo-sprockets-rails3 for faster deployment"
gem 'turbo-sprockets-rails3' , '>= 0.3.6', :group => :assets

say_wizard "recipe setting development prefs"

gem 'activerecord-postgres-hstore' if prefs[:hstore]

gem_group :development do
  gem 'pry'
  gem 'pry-nav'    
  gem "sextant"
  gem "mailcatcher"
  gem 'guard'  
  gem 'guard-rspec'  
  gem "bullet"
end

gem_group :test do
  gem 'shoulda-matchers'
  gem 'zeus'  
end

after_bundler do

	say_wizard "setting-up capistrano"
	capify!

	say_wizard "setting-up test"
	empty_directory "spec/routing"
	empty_directory "spec/features"
	remove_file 'spec/spec_helper.rb'
	copy_from 'https://raw.github.com/alextakitani/alex_specials/master/spec_helper.rb', 'spec/spec_helper.rb'
	append_to_file '.rspec', '--format documentation'
	copy_from 'https://raw.github.com/alextakitani/alex_specials/master/Guardfile', 'Guardfile'

  generate 'hstore:setup' if prefs[:hstore] 

  say_wizard "use utf-8 for database" 
  gsub_file "config/database.yml", "unicode","utf8"
  
  if prefs[:locale]
    say_wizard "setting-up locales"
    copy_from "https://raw.github.com/alextakitani/alex_specials/master/locales/#{prefs[:locale]}.yml", "config/locales/#{prefs[:locale]}.yml"
    copy_from "https://raw.github.com/alextakitani/alex_specials/master/locales/devise.#{prefs[:locale]}.yml", "config/locales/devise.#{prefs[:locale]}.yml"
    copy_from "https://raw.github.com/alextakitani/alex_specials/master/locales/simple-form.#{prefs[:locale]}.yml", "config/locales/simple-form.#{prefs[:locale]}.yml"

    insert_into_file "config/application.rb", "\n\t\tconfig.time_zone = '#{prefs[:time_zone]}'" ,:after => "# config.i18n.default_locale = :de" if prefs[:time_zone]
    gsub_file "config/application.rb", "# config.i18n.default_locale = :de" , "config.i18n.default_locale = '#{prefs[:locale]}'"   
  end



  bullet_text = <<-TEXT 
  \n\t\t
  config.after_initialize do
    Bullet.enable = true    
    Bullet.rails_logger = true  
  end
TEXT

  insert_into_file "config/environments/development.rb",  bullet_text ,:after => "config.assets.debug = true"
  
  case HOST_OS
  when /darwin/i
    gem 'rb-fsevent', :group => :development
    gem 'terminal-notifier-guard', :group => :development
  when /linux/i
    gem 'libnotify', :group => :development
    gem 'rb-inotify', :group => :development
  when /mswin|windows/i
    gem 'rb-fchange', :group => :development
    gem 'win32console', :group => :development
    gem 'rb-notifu', :group => :development
  end


  if prefer :email, 'gmail'
    gmail_configuration_text = <<-TEXT
\n
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "example.com",
    authentication: "plain",
    enable_starttls_auto: true,
    user_name: ENV["GMAIL_USERNAME"],
    password: ENV["GMAIL_PASSWORD"]
  }
TEXT

  gsub_file 'config/environments/development.rb', gmail_configuration_text, "\n\tconfig.action_mailer.smtp_settings = { :address => 'localhost', :port => 1025 }"


  end


end

__END__

name: alex_specials
description: "Install my initial setup."
author: alextakitani

requires: [core]
run_after: [setup, extras]
category: configuration
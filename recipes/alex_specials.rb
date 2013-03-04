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
  gem 'rb-fsevent'  
  gem "bullet"
end

gem_group :test do
  gem 'shoulda-matchers'
  gem 'zeus'
  gem 'rb-inotify', '~> 0.9'
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
  
  unless prefs[:locale].nil?
    say_wizard "setting-up locales"
    copy_from "https://raw.github.com/alextakitani/alex_specials/master/locales/devise.#{prefs[:locale]}.yml", 'config/locales/devise.#{prefs[:locale]}.yml'
  end

end

__END__

name: alex_specials
description: "Install my initial setup."
author: alextakitani

requires: [core]
run_after: [setup, extras]
category: configuration
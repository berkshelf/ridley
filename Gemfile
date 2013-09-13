source 'https://rubygems.org'

gemspec

platforms :jruby do
  gem 'jruby-openssl'
end

group :development do
  gem 'yard'
  gem 'spork'
  gem 'guard', '>= 1.5.0'
  gem 'guard-yard'
  gem 'guard-rspec'
  gem 'guard-spork', platforms: :ruby
  gem 'coolline'
  gem 'redcarpet', platforms: :ruby
  gem 'kramdown', platforms: :jruby

  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'growl', require: false
    gem 'rb-fsevent', require: false

    if `uname`.strip == 'Darwin' && `sw_vers -productVersion`.strip >= '10.8'
      gem 'terminal-notifier-guard', '~> 1.5.3', require: false
    end rescue Errno::ENOENT

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify',  '~> 0.8.0', require: false
    gem 'rb-inotify', require: false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', require: false
    gem 'rb-notifu', '>= 0.0.4', require: false
    gem 'wdm', require: false
  end
end

group :test do
  gem 'thor'
  gem 'rake', '>= 0.9.2.2'
  gem 'rspec', '~> 2.14.0'
  gem 'fuubar'
  gem 'json_spec'
  gem 'webmock'
  gem 'chef-zero', '~> 1.5.0'
end

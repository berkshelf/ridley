# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ridley/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Jamie Winsor", "Kyle Allan"]
  s.email         = ["jamie@vialstudios.com", "kallan@riotgames.com"]
  s.description   = %q{A reliable Chef API client with a clean syntax}
  s.summary       = s.description
  s.homepage      = "https://github.com/RiotGames/ridley"
  s.license       = "Apache 2.0"

  s.files         = `git ls-files`.split($\)
  s.executables   = Array.new
  s.test_files    = s.files.grep(%r{^(spec)/})
  s.name          = "ridley"
  s.require_paths = ["lib"]
  s.version       = Ridley::VERSION
  s.required_ruby_version = ">= 1.9.1"

  s.add_dependency 'addressable'
  s.add_dependency 'varia_model',             '~> 0.4'
  s.add_dependency 'buff-config',             '~> 1.0'
  s.add_dependency 'buff-extensions',         '~> 1.0'
  s.add_dependency 'buff-ignore',             '~> 1.1'
  s.add_dependency 'buff-shell_out',          '~> 0.1'
  s.add_dependency 'celluloid',               '~> 0.16.0.pre'
  s.add_dependency 'celluloid-io',            '~> 0.16.0.pre'
  s.add_dependency 'erubis'
  s.add_dependency 'faraday',                 '~> 0.9.0'
  s.add_dependency 'hashie',                  '>= 2.0.2', '< 3.0.0'
  s.add_dependency 'json',                    '>= 1.7.7'
  s.add_dependency 'mixlib-authentication',   '>= 1.3.0'
  s.add_dependency 'net-http-persistent',     '>= 2.8'
  s.add_dependency 'retryable'
  s.add_dependency 'semverse',                '~> 1.1'

  s.add_development_dependency 'buff-ruby_engine', '~> 0.1'
end

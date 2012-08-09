# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ridley/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Jamie Winsor"]
  s.email         = ["jamie@vialstudios.com"]
  s.description   = %q{A reliable Chef API client with a clean syntax}
  s.summary       = s.description
  s.homepage      = "https://github.com/reset/ridley"

  s.files         = `git ls-files`.split($\)
  s.executables   = Array.new
  s.test_files    = s.files.grep(%r{^(spec)/})
  s.name          = "ridley"
  s.require_paths = ["lib"]
  s.version       = Ridley::VERSION

  s.add_runtime_dependency 'mixlib-authentication'
  s.add_runtime_dependency 'addressable'
  s.add_runtime_dependency 'faraday'
  s.add_runtime_dependency 'multi_json'
  s.add_runtime_dependency 'activemodel'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fuubar'
  s.add_development_dependency 'spork'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-spork'
  s.add_development_dependency 'guard-yard'
  s.add_development_dependency 'coolline'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'json_spec'
  s.add_development_dependency 'webmock'
end

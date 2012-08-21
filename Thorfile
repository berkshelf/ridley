# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require 'bundler'
require 'bundler/setup'

require 'ridley'
require 'thor/rake_compat'

class Default < Thor
  include Thor::RakeCompat
  Bundler::GemHelper.install_tasks

  desc "build", "Build berkshelf-#{Ridley::VERSION}.gem into the pkg directory"
  def build
    Rake::Task["build"].execute
  end

  desc "install", "Build and install berkshelf-#{Ridley::VERSION}.gem into system gems"
  def install
    Rake::Task["install"].execute
  end

  desc "release", "Create tag v#{Ridley::VERSION} and build and push berkshelf-#{Ridley::VERSION}.gem to Rubygems"
  def release
    Rake::Task["release"].execute
  end

  class Spec < Thor
    namespace :spec
    default_task :all

    desc "all", "run all tests"
    def all
      exec "rspec --color --format=documentation spec"
    end

    desc "unit", "run only unit tests"
    def unit
      exec "rspec --color --format=documentation spec --tag ~type:acceptance" 
    end

    desc "acceptance", "run only acceptance tests"
    def acceptance
      exec "rspec --color --format=documentation spec --tag type:acceptance"
    end
  end
end

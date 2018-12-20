$:.unshift File.expand_path("../lib", __FILE__)
require 'rangefinder/webhook/version'
require 'date'

Gem::Specification.new do |s|
  s.name              = "puppet-community-rangefinder-webhook"
  s.version           = Rangefinder::Webhook::VERSION
  s.date              = Date.today.to_s
  s.summary           = "Provides impact analysis for Puppet modules PRs on GitHub."
  s.homepage          = "https://github.com/puppetlabs/puppet-community-rangefinder-webhook"
  s.email             = "ben.ford@puppet.com"
  s.authors           = ["Ben Ford"]
  s.license           = "Apache-2.0"
  s.require_path      = "lib"
  s.executables       = %w( rangefinder-webhook )
  s.files             = %w( README.md LICENSE CHANGELOG.md )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("doc/**/*")
  s.files            += Dir.glob("views/**/*")
  s.files            += Dir.glob("public/**/*")
  s.add_dependency      "sinatra",      "~> 2.0"
  s.add_dependency      "octokit",      "~> 4.0"
  s.add_dependency      "jwt",          "~> 2.1"
  s.add_dependency      "puppet-community-rangefinder"

  s.description       = <<-desc
    Rangefinder is a tool that helps predict the downstream impact of breaking
    file changes. This GitHub integration allows us to tie it to pull requests
    and provide impact prediction reports as comments when a PR is filed.
  desc
end

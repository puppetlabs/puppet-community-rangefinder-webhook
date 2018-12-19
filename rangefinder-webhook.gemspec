$:.unshift File.expand_path("../lib", __FILE__)
require 'rangefinder/webhook/version'
require 'date'

Gem::Specification.new do |s|
  s.name              = "driftwood"
  s.version           = Rangefinder::Webhook::VERSION
  s.date              = Date.today.to_s
  s.summary           = "Simple Sinatra based Slack logbot."
  s.homepage          = "https://github.com/puppetlabs/driftwood"
  s.email             = "ben.ford@puppet.com"
  s.authors           = ["Ben Ford"]
  s.license           = "Apache-2.0"
  s.has_rdoc          = false
  s.require_path      = "lib"
  s.executables       = %w( rangefinder-webhook )
  s.files             = %w( README.md LICENSE CHANGELOG.md )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("doc/**/*")
  s.files            += Dir.glob("views/**/*")
  s.files            += Dir.glob("public/**/*")
  s.add_dependency      "sinatra",      "~> 1.3"
  s.add_dependency      "rangefinder"

  s.description       = <<-desc
    The Slack logging service isn't very complete, especially if you're on the free
    tier. For example, messages expire far too soon on an active channel and users
    don't include creation times. This tool provides those missing features, and soon
    will also provide features for building a positive team culture.
  desc
end

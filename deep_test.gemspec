# -*- encoding: utf-8 -*-
require File.expand_path("../lib/deep_test/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "deep_test"
  s.version     = DeepTest::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["onyx"]
  s.email       = []
  s.homepage    = ""
  s.summary     = "DeepTest enables tests to run in parallel using multiple processes."
  s.description = "Processes may spawned locally to take advantage of multiple processors on a single machine or distributed across many machines to take advantage of distributed processing."

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "mocha", "0.13.3"
  s.add_development_dependency "dust", "0.1.6"
  s.add_runtime_dependency "rspec", "1.1.12"
  s.add_runtime_dependency "rake", "10.1.1"
  s.add_runtime_dependency "test-unit", "2.5.5"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'pagerbot/version'

Gem::Specification.new do |spec|
  spec.name          = 'pagerbot'
  spec.version       = '0.2.0'
  spec.authors       = ['Karl-Aksel Puulmann']
  spec.email         = ['oxymaccy@gmail.com']
  spec.summary       = %q{IRC and Slackbot for PagerDuty.}
  spec.description   = %q{This bot connects Slack or IRC to PagerDuty.}
  spec.homepage      = 'https://github.com/stripe-contrib/pagerbot'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'chronic'
  spec.add_dependency 'chronic_duration'
  spec.add_dependency 'cinch'
  spec.add_dependency 'configatron'
  spec.add_dependency 'mailgun-ruby'
  spec.add_dependency 'method_decorators'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'thin'
  spec.add_dependency 'mongo'
  spec.add_dependency 'bson_ext'

  spec.add_development_dependency 'minitest', '< 5.0'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'pry'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rerun'

end

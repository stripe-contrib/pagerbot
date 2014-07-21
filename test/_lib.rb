require 'rubygems'
require 'bundler/setup'

require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/setup'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib')))
require 'pagerbot'

module Critic
  class Test < ::MiniTest::Spec
    def setup
      PagerBot.log.level = Logger::WARN
    end
  end
end
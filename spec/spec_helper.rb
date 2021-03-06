# frozen_string_literal: true

CUPRITE_ROOT = File.expand_path("..", __dir__)
$:.unshift(CUPRITE_ROOT + "/lib")

require "bundler/setup"

require "rspec"
require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"

Capybara.register_driver(:cuprite) do |app|
  driver = Capybara::Cuprite::Driver.new(app, {})
  puts `#{driver.browser.process.path.gsub(" ", "\\ ")} -version`
  driver
end

module TestSessions
  Cuprite = Capybara::Session.new(:cuprite, TestApp)
end

module Cuprite
  module SpecHelper
    class << self
      def set_capybara_wait_time(t)
        Capybara.default_max_wait_time = t
      rescue StandardError
        Capybara.default_wait_time = t
      end
    end
  end
end

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
    #check when checkbox hidden with Capybara.automatic_label_click == true should check via clicking the label with :for attribute if locator nil
    #check when checkbox hidden with Capybara.automatic_label_click == true should check self via clicking the wrapping label if locator nil
    #check when checkbox hidden with Capybara.automatic_label_click == false with allow_label_click == true should not wait the full time if label can be clicked
    #choose with hidden radio buttons with Capybara.automatic_label_click == true should select self by clicking the label if no locator specified
    #reset_session! handles already open modals
    #click_link can download a file
    node #drag_to should drag and drop an object
    node #drag_to should drag and drop if scrolling is needed
    node #drag_to should drag a link
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match(/#{regexes}/)
  end

  Capybara::SpecHelper.configure(config)

  config.before(:each) do
    Cuprite::SpecHelper.set_capybara_wait_time(0)
  end

  %i[js modals windows].each do |cond|
    config.before(:each, requires: cond) do
      Cuprite::SpecHelper.set_capybara_wait_time(1)
    end
  end
end

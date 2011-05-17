require 'simplecov'
SimpleCov.start

require 'net/ldap'
require 'action_controller'
require 'active_record'
require 'rails'
require 'rspec/rails'
require 'sso_sap'
require 'sso_sap/ldap_store'

require "#{File.dirname(__FILE__)}/fixtures"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.

RSpec.configure do |config|
  config.mock_with :mocha

end
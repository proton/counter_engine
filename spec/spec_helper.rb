require 'bundler/setup'
require 'rack/test'
require 'json'
require 'counter_engine'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Rack::Test::Methods
end

class SimpleApp
  def call(_env)
    return 200, {}, ['hello']
  end
end
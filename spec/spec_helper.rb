require 'bundler/setup'
require 'rack/test'
require 'json'
require 'database_cleaner'
require 'counter_engine'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Rack::Test::Methods

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

class SimpleApp
  def call(_env)
    return 200, {}, ['hello']
  end
end
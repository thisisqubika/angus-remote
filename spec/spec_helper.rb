require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'rspec'
require 'rspec/its'

require 'simplecov-rcov'
require 'simplecov-rcov-text'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter,
  SimpleCov::Formatter::RcovTextFormatter
]

require 'redis'
require 'mock_redis'

RSpec.configure do |config|

  redis = MockRedis.new

  config.before do
    Redis.stub(:new => redis)
  end

  config.after do
    redis.flushdb
  end

end
# frozen_string_literal: true

require 'bundler/setup'

require 'simplecov'

require 'rspec'
require 'rspec/its'

require 'simplecov-rcov'
require 'simplecov-rcov-text'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter,
  SimpleCov::Formatter::RcovTextFormatter
]

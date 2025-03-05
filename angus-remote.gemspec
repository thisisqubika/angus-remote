# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'angus/remote/version'

Gem::Specification.new do |spec|
  spec.name          = 'angus-remote'
  spec.version       = Angus::Remote::VERSION
  spec.platform      = Gem::Platform::RUBY

  spec.authors       = ['Qubika']
  spec.email         = %w[angus@qubika.com]
  spec.summary       = 'Client for building service objects.'
  spec.description   = <<-DESCRIPTION
    Provides a client for making requests and building responses to remote services.
  DESCRIPTION
  spec.homepage      = 'https://github.com/thisisqubika/angus-remote'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.5.0'

  spec.files         = Dir.glob('{lib}/**/*')
  spec.require_paths = %w[lib]

  spec.add_dependency('angus-sdoc', '~> 0.0', '>= 0.0.6')
  spec.add_dependency('bigdecimal', '~> 3.1')
  spec.add_dependency('concurrent-ruby', '~> 1.3')

  spec.add_dependency('persistent_http', '~> 2.0.3')

  spec.metadata['rubygems_mfa_required'] = 'true'
end

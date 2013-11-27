lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'angus/remote/version'

Gem::Specification.new do |spec|
  spec.name          = 'angus-remote'
  spec.version       = Angus::Remote::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Adrian Gomez', 'Gianfranco Zas']
  spec.email         = %W[angus@moove-it.com]
  spec.summary       = 'Client for building service objects.'
  spec.description   = <<-DESCRIPTION
    Provides a client for making requests and building responses to remote services.
  DESCRIPTION
  spec.homepage      = 'http://mooveit.github.io/angus-remote'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{lib}/**/*')
  spec.test_files    = Dir.glob('{spec/angus}/**/*')
  spec.require_paths = %W[lib]

  spec.add_dependency('angus-sdoc', '~> 0.0', '>= 0.0.4')
  spec.add_dependency('persistent_http', '~> 1.0')
  spec.add_dependency('multipart-post', '~> 1.2')
  spec.add_dependency('redis')

  spec.add_development_dependency('rake')
  spec.add_development_dependency('fakefs', '~> 0.4')
  spec.add_development_dependency('rspec', '~> 2.14')
  spec.add_development_dependency('mock_redis')
  spec.add_development_dependency('simplecov', '~> 0.7')
  spec.add_development_dependency('simplecov-rcov', '~> 0.2')
  spec.add_development_dependency('simplecov-rcov-text', '~> 0.0')
  spec.add_development_dependency('ci_reporter', '~> 1.9')
end
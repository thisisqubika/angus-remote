lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'angus/remote/version'

Gem::Specification.new do |spec|
  spec.name          = 'angus-remote'
  spec.version       = Angus::Remote::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Adrian Gomez', 'Gianfranco Zas']
  spec.email         = %w[angus@moove-it.com]
  spec.summary       = 'Client for building service objects.'
  spec.description   = <<-DESCRIPTION
    Provides a client for making requests and building responses to remote services.
  DESCRIPTION
  spec.homepage      = 'http://mooveit.github.io/angus-remote'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{lib}/**/*')
  spec.test_files    = Dir.glob('{spec/angus}/**/*')
  spec.require_paths = %w[lib]

  spec.add_dependency('angus-sdoc', '~> 0.0', '>= 0.0.6')
  spec.add_dependency('multipart-post', '>= 2.2')
  spec.add_dependency('persistent_http', '~> 2.0.3')
  spec.add_dependency('activesupport')

  spec.add_development_dependency('ci_reporter', '~> 2.0.0')
  spec.add_development_dependency('fakefs')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec', '~> 3.11.0')
  spec.add_development_dependency('rspec-its')
  spec.add_development_dependency('simplecov', '~> 0.17.1')
  spec.add_development_dependency('simplecov-rcov', '~> 0.3.1')
  spec.add_development_dependency('simplecov-rcov-text', '~> 0.0.3')
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'picasso/remote/version'

Gem::Specification.new do |spec|
  spec.name          = 'picasso-remote'
  spec.version       = Picasso::Remote::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Adrian Gomez', 'Gianfranco Zas']
  spec.email         = %W[picasso@moove-it.com]
  spec.summary       = 'Client for building service objects.'
  spec.description   = 'Provides support code for accepting requests, building responses, caching, mailing, versioning and documentation'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = %W[lib]

  spec.add_dependency 'persistent_http', '~> 1.0'
  spec.add_dependency 'multipart-post', '~> 1.2'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'fakefs', '~> 0.4'
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'simplecov', '~> 0.7'
  spec.add_development_dependency 'simplecov-rcov', '~> 0.2'
  spec.add_development_dependency 'simplecov-rcov-text', '~> 0.0'
  spec.add_development_dependency 'ci_reporter', '~> 1.9'
end
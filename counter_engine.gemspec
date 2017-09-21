# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'counter_engine/version'

Gem::Specification.new do |spec|
  spec.name          = 'counter_engine'
  spec.version       = CounterEngine::VERSION
  spec.authors       = ['Peter Savichev (proton)']
  spec.email         = ['psavichev@gmail.com']

  spec.summary       = 'Simple rack mountable visits counter'
  spec.homepage      = 'https://github.com/proton/counter_engine'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '>= 0.4'
  spec.add_dependency 'redis', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rack-test', '~> 0.7.0'
  spec.add_development_dependency 'database_cleaner', '~> 1.6.1'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prepare_indices/version'

Gem::Specification.new do |spec|
  spec.name          = "prepare_indices"
  spec.version       = PrepareIndices::VERSION
  spec.authors       = ["Ondrejkova"]
  spec.email         = ["408256@mail.muni.cz"]

  spec.summary       = %q{Gem for prepare indices from elasticsearch}
  spec.description   = %q{Gem for prepare indices (delete, create, update) from
    elasticsearch.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "pry"
  spec.add_development_dependency 'webmock'
end

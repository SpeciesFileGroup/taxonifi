# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'taxonifi/version'

Gem::Specification.new do |s|
  s.name = "taxonifi"
  s.version = Taxonifi::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Yoder"]
  s.date = "2013-03-27"
  
  s.summary = "A general purpose framework for scripted handling of taxonomic names or other heirarchical metadata."
  s.description = 'Taxonifi contains simple models and utilties of use in for parsing lists of taxonomic name (life) related metadata or other heirarchically defined data.'
  s.email = 'diapriid@gmail.com'
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
 
  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "https://github.com/SpeciesFile/taxonifi"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.4.5"
  s.metadata = { "source_code_uri" => "https://github.com/SpeciesFileGroup/taxonifi" }

  s.add_dependency "require_all", "~> 3.0"
  s.required_ruby_version = '>= 2.6', '< 4'

  s.add_development_dependency "rake", '~> 13.0'
  s.add_development_dependency "byebug", "~> 11"
  s.add_development_dependency "bundler", "~> 2.1"
  s.add_development_dependency 'awesome_print', '~> 1.8'
  s.add_development_dependency 'test-unit', '~> 3.3.5'
  s.add_development_dependency "rdoc", "~> 6.2"
  s.add_development_dependency "builder", "~> 3.2"

end

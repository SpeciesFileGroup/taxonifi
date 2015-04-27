# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'taxonifi/version'

Gem::Specification.new do |s|
  s.name = "taxonifi"
  s.version = Taxonifi::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mjy"]
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
  s.homepage = "http://github.com/SpeciesFile/taxonifi"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.4.5"

  s.add_dependency "rake", '~> 10.4'
  s.add_dependency "byebug", "~> 4.0"

  s.add_development_dependency "bundler", "~> 1.9"
  s.add_development_dependency 'awesome_print', '~> 1.6'
  s.add_development_dependency 'did_you_mean', '~> 0.9'
  s.add_development_dependency "rdoc", "~> 4.2"
  s.add_development_dependency "builder", "~> 3.2"


  # Travis



end


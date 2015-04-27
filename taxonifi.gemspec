# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'taxonifi/version'



Gem::Specification.new do |s|
  s.name = "taxonifi"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mjy"]
  s.date = "2013-03-27"
  s.description = "Taxonifi contains simple models and utilties of use in for parsing lists of taxonomic name (life) related metadata"
  s.email = "diapriid@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/assessor/assessor.rb",
    "lib/assessor/base.rb",
    "lib/assessor/row_assessor.rb",
    "lib/export/export.rb",
    "lib/export/format/base.rb",
    "lib/export/format/obo_nomenclature.rb",
    "lib/export/format/prolog.rb",
    "lib/export/format/species_file.rb",
    "lib/lumper/clump.rb",
    "lib/lumper/lumper.rb",
    "lib/lumper/lumps/parent_child_name_collection.rb",
    "lib/model/author_year.rb",
    "lib/model/base.rb",
    "lib/model/collection.rb",
    "lib/model/generic_object.rb",
    "lib/model/geog.rb",
    "lib/model/geog_collection.rb",
    "lib/model/name.rb",
    "lib/model/name_collection.rb",
    "lib/model/person.rb",
    "lib/model/ref.rb",
    "lib/model/ref_collection.rb",
    "lib/model/shared_class_methods.rb",
    "lib/model/species_name.rb",
    "lib/splitter/builder.rb",
    "lib/splitter/lexer.rb",
    "lib/splitter/parser.rb",
    "lib/splitter/splitter.rb",
    "lib/splitter/tokens.rb",
    "lib/taxonifi.rb",
    "lib/utils/array.rb",
    "lib/utils/hash.rb",
    "taxonifi.gemspec",
    "test/file_fixtures/Fossil.csv",
    "test/file_fixtures/Lygaeoidea.csv",
    "test/file_fixtures/names.csv",
    "test/helper.rb",
    "test/test_export_prolog.rb",
    "test/test_exporter.rb",
    "test/test_lumper_clump.rb",
    "test/test_lumper_geogs.rb",
    "test/test_lumper_hierarchical_collection.rb",
    "test/test_lumper_names.rb",
    "test/test_lumper_parent_child_name_collection.rb",
    "test/test_lumper_refs.rb",
    "test/test_obo_nomenclature.rb",
    "test/test_parser.rb",
    "test/test_splitter.rb",
    "test/test_splitter_tokens.rb",
    "test/test_taxonifi.rb",
    "test/test_taxonifi_accessor.rb",
    "test/test_taxonifi_base.rb",
    "test/test_taxonifi_geog.rb",
    "test/test_taxonifi_name.rb",
    "test/test_taxonifi_name_collection.rb",
    "test/test_taxonifi_ref.rb",
    "test/test_taxonifi_ref_collection.rb",
    "test/test_taxonifi_species_name.rb"
  ]
  s.homepage = "http://github.com/SpeciesFile/taxonifi"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.4.5"
  s.summary = "A general purpose framework for scripted handling of taxonomic names"

  s.add_development_dependency "byebug", "~> 4.0"
  s.add_development_dependency "builder", "~> 3.2"
  s.add_development_dependency "rdoc", "~> 4.2"
  s.add_development_dependency "bundler", "~> 1.9"
 #  s.add_development_dependency "jeweler", "~> 2.0"

  # Travis
  s.add_dependency "rake"


end


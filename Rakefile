# encodang: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "taxonifi"
  gem.homepage = "http://github.com/mjy/taxonifi"
  gem.license = "MIT"
  gem.summary = %Q{A general purpose framework for scripted handling of tayhxonomic names}
  gem.description = %Q{Taxonifi contains simple models and utilties of use in for parsing lists of taxonomic name (life) related metadata}
  gem.email = "diapriid@gmail.com"
  gem.authors = ["mjy"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

# require 'rcov/rcovtask'
# Rcov::RcovTask.new do |test|
#  test.libs << 'test'
#  test.pattern = 'test/**/test_*.rb'
#  test.verbose = true
#  test.rcov_opts << '--exclude "gems/*"'
# end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

 rdoc.rdoc_dir = 'rdoc'
 rdoc.title = "taxonifi #{version}"
 rdoc.rdoc_files.include('README*')
 rdoc.rdoc_files.include('lib/**/*.rb')
end

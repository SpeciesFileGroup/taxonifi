require 'rubygems'
require 'bundler'
require 'debugger'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
#require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'taxonifi'

class Test::Unit::TestCase
end


def generic_csv_with_names
  @headers = %W{identifier parent child rank synonyms}
  @csv_string = CSV.generate() do |csv|
    csv <<  @headers
    csv << [0, nil, "Root", "class", nil ]
    csv << [1, "0", "Aidae", "Family", nil ]
    csv << [2, "1", "Foo", "Genus", nil ]
    csv << [3, "2", "Foo bar", "species", nil ]                                          # case testing
    csv << [4, "2", "Foo bar stuff (Guy, 1921)", "species", "Foo bar blorf (Guy, 1921)"] # initial subspecies rank data had rank blank, assuming they will be called species
    csv << [5, "0", "Bidae", "Family", nil ]
  end

  @csv = CSV.parse(@csv_string, {headers: true})
end


require 'rubygems'

require 'bundler/setup'
Bundler.setup

require 'byebug'
require 'test/unit'

# require File.expand_path(File.join(File.dirname(__FILE__), '../lib/taxonifi.rb'))

# begin
#   Bundler.setup(:default, :development)
# rescue Bundler::BundlerError => e
#   $stderr.puts e.message
#   $stderr.puts "Run `bundle install` to install missing gems"
#   exit e.status_code
# end


#require 'shoulda'


# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))

# class Test::Unit::TestCase
# end

# TODO: rename to reflect format
def generic_csv_with_names
  @headers = %W{identifier parent child rank synonyms}
  @csv_string = CSV.generate() do |csv|
    csv <<  @headers
    csv << [0, nil, "Root", "class", nil ]
    csv << [1, "0", "Aidae", "Family", nil ]
    csv << [2, "0", "Bidae", "Family", nil ]
    csv << [3, "1", "Foo", "Genus", nil ]
    csv << [4, "3", "Foo bar", "species", nil ]                                          # case testing
    csv << [5, "4", "Foo bar bar", "species", nil ]                                      
    csv << [6, "3", "Foo bar stuff (Guy, 1921)", "species", "Foo bar blorf (Guy, 1921)"] # initial subspecies rank data had rank blank, assuming they will be called species
  end

  @csv = CSV.parse(@csv_string, {headers: true})
end

def names
    file = File.expand_path(File.join(File.dirname(__FILE__), 'file_fixtures/names.csv'))

    csv = CSV.read(file, { 
      headers: true,
      col_sep: ",",
      header_converters: :downcase
    } ) 
    nc = Taxonifi::Lumper.create_name_collection(:csv => csv, :initial_id => 1) 
end



require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/lumper/lumper')) 

# Builder construction

class Test_TaxonifiLumper < Test::Unit::TestCase

  def setup
    @headers = ["family", "genus", "species", "author", "year"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Fooidae", "Foo", "bar", "Smith", "1854"]
    end

    @csv = CSV.parse(@csv_string, {headers: true})
  end

  def test_that_setup_setups
    assert_equal @headers, @csv.headers
  end

  def test_available_lumps_raise_without_arrays
    assert_raises Taxonifi::Lumper::LumperError do
      Taxonifi::Lumper.available_lumps( "foo" )
    end
  end

  def test_available_lumps
    assert Taxonifi::Lumper.available_lumps( Taxonifi::Lumper::QUAD ).include?(:quadrinomial)
    assert Taxonifi::Lumper.available_lumps( Taxonifi::Lumper::AUTHOR_YEAR + Taxonifi::Lumper::QUAD ).include?(:quad_author_year)
    assert (not Taxonifi::Lumper.available_lumps( Taxonifi::Lumper::AUTHOR_YEAR + Taxonifi::Lumper::QUAD ).include?(:names) )
  end

end 


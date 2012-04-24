require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/lumper/lumper')) 

# Builder construction

class Test_TaxonifiLumperRefs < Test::Unit::TestCase

  def setup
    @headers = ["authors", "year", "title", "publication", "pg_start", "pg_end",  "pages", "cited_page"  ,"volume", "number", "volume_number"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-5, 190", nil, "2", "4", "2(4)" ]
    end

    @csv = CSV.parse(@csv_string, {headers: true})
  end

  def test_available_lumps
     assert_equal [:citation_basic, :citation_small], Taxonifi::Lumper.available_lumps(@csv.headers)
  end

  def test_intersecting_lumps
    headers = ["authors"]
      csv_string = CSV.generate() do |csv|
        csv <<  headers
        csv << ["Smith J. and Barnes S."]
      end

     csv = CSV.parse(csv_string, {headers: true})

     assert_equal [:citation_basic, :citation_small], Taxonifi::Lumper.intersecting_lumps(csv.headers)
     assert_equal [], Taxonifi::Lumper.available_lumps(csv.headers)
  end

  def test_create_ref_collection
    assert_equal Taxonifi::Model::RefCollection, Taxonifi::Lumper.create_ref_collection(@csv).class
  end

  def test_creates_refs
    assert_equal 1, Taxonifi::Lumper.create_ref_collection(@csv).collection.size
  end

  def test_assigns_attributes_to_instantiated_refs
    rc = Taxonifi::Lumper.create_ref_collection(@csv)
    assert_equal ["J"], rc.collection.first.authors.first.initials
    assert_equal "Smith", rc.collection.first.authors.first.last_name
  end



end 


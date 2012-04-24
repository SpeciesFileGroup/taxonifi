require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/lumper/lumper')) 

# Builder construction

class Test_TaxonifiLumperRefs < Test::Unit::TestCase

  def setup
    @headers = ["authors", "year", "title", "publication", "pg_start", "pg_end",  "pages", "cited_page"  ,"volume", "number", "volume_number"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
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
    assert_equal "2012", rc.collection.first.year
    assert_equal "Bar and foo", rc.collection.first.title
    assert_equal "Journal of Foo", rc.collection.first.publication
    assert_equal "2", rc.collection.first.volume
    assert_equal "4", rc.collection.first.number
    assert_equal "2", rc.collection.first.pg_start
    assert_equal "3", rc.collection.first.pg_end
  end

  def test_indexes_unique_refs
    csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
    end
    csv = CSV.parse(csv_string, {headers: true})
    rc = Taxonifi::Lumper.create_ref_collection(csv)
    assert_equal 1, rc.collection.size
  end

  def test_indexes_unique_refs2
    csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
      csv << ["Smith J. and Bartes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
    end
    csv = CSV.parse(csv_string, {headers: true})
    rc = Taxonifi::Lumper.create_ref_collection(csv)
    assert_equal 2, rc.collection.size
  end

  def test_that_refs_can_be_returned_by_row
   csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Smith J. and Barnes S.", "2012", "Bar and foo", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
      csv << ["Smith J.", "2012", "Foo and bar", "Journal of Foo", "2", "3", "2-3, 190", nil, "2", "4", "2(4)" ]
    end
    csv = CSV.parse(csv_string, {headers: true})
    rc = Taxonifi::Lumper.create_ref_collection(csv)
    assert_equal "Foo and bar", rc.object_from_row(1).title
  end

end 


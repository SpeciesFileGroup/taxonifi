require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/ref')) 

class TestTaxonifiRef < Test::Unit::TestCase

  def test_new_ref
    assert n = Taxonifi::Model::Ref.new() 
  end

  def test_that_a_ref_has_authors
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:authors)
  end

  def test_that_a_ref_has_title
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:title)
  end

  def test_that_a_ref_has_year
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:year)
  end

  def test_that_a_ref_has_publication
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:publication)
  end

  def test_that_a_ref_has_volume_year
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:volume)
    assert n.respond_to?(:year)
  end

  def test_that_a_ref_has_page_fields
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:pg_start)
    assert n.respond_to?(:pg_end)
    assert n.respond_to?(:pages)
    assert n.respond_to?(:cited_page)
  end

  def create_a_ref
    @ref = Taxonifi::Model::Ref.new(
                                 :authors => [Taxonifi::Model::Person.new(:last_name => "Foo", :initials => "AC")],  
                                 :year => 2012,
                                 :title => "Place to be",
                                 :publication => "Journal Du Jour",
                                 :pg_start => 1,
                                 :pg_end => 2,
                                 :volume => 3,
                                 :number => 4
                                )
  end

  def test_identical?
    create_a_ref
    foo = @ref.clone
    bar = @ref.clone
    assert foo.identical?(bar)
    bar.title = "Foo"
    assert !foo.identical?(bar)
  end

  def test_that_ref_assigns_passed_options
    create_a_ref
    assert_equal "Place to be", @ref.title
    assert_equal 4, @ref.number
  end

  def test_that_compact_string_is_compact
    create_a_ref
    assert_equal '|ac|foo||2012|placetobe|journaldujour|3|4||1|2|', @ref.compact_string
  end

  def test_that_author_year_strings_translate_to_author_years
    r = Taxonifi::Model::Ref.new(:author_year => 'Smith and Jones, 1920')
    assert_equal 2, r.authors.size 
    assert_equal 1920, r.year
  end

  def test_compact_author_year_index
    r = Taxonifi::Model::Ref.new(:author_year => 'Smith and Jones, 1920')
    assert_equal '1920-||smith|-||jones|', r.compact_author_year_index
  end



end

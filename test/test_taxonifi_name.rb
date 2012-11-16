require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/name')) 

class TestTaxonifiName < Test::Unit::TestCase

  def test_truth
    assert(true)
  end

  def test_new_name
    assert n = Taxonifi::Model::Name.new() 
  end

  def test_that_name_has_a_name
    n = Taxonifi::Model::Name.new() 
    assert n.respond_to?(:name)
  end

  def test_that_name_has_an_id
    n = Taxonifi::Model::Name.new() 
    assert n.respond_to?(:id)
  end

  def test_that_name_has_a_parent
    n = Taxonifi::Model::Name.new() 
    assert n.respond_to?(:parent) 
  end

  def test_that_name_has_a_rank
    n = Taxonifi::Model::Name.new() 
    assert n.respond_to?(:rank) 
  end
 
  def test_that_name_has_an_author
    n = Taxonifi::Model::Name.new() 
    assert n.respond_to?(:author) 
  end
  
  def test_that_name_has_a_year
    n = Taxonifi::Model::Name.new() 
    assert n.respond_to?(:year) 
  end

  def test_that_name_returns_false_with_bad_rank
    n = Taxonifi::Model::Name.new() 
    assert_raise Taxonifi::NameError do
      n.rank = "FOO"
    end 
  end

  def test_that_name_allows_legal_rank
    n = Taxonifi::Model::Name.new() 
    assert n.rank = "genus"
  end

  def test_that_name_rank_is_case_insensitive
    n = Taxonifi::Model::Name.new() 
    assert n.rank = "Genus"
    assert n.rank = "GENUS"
  end

  def test_that_rank_is_required_before_parent
    n = Taxonifi::Model::Name.new() 
    assert_raise Taxonifi::NameError do
      n.parent = Taxonifi::Model::Name.new() 
    end
  end

  def test_that_parent_is_a_taxonifi_name
    n = Taxonifi::Model::Name.new() 
    n.rank = "genus" # avoid that raise
    assert_raise Taxonifi::NameError do
      n.parent = "foo"
    end
  end

 def test_that_rank_can_be_set
    n = Taxonifi::Model::Name.new() 
    n.rank = "family"
    assert_equal "family", n.rank
  end


  def test_that_parent_is_higher_rank_than_child
    n = Taxonifi::Model::Name.new() 
    n.rank = "genus"
    p = Taxonifi::Model::Name.new() 
    p.rank = "species"
    assert_raise Taxonifi::NameError do
      n.parent = p
    end
  end

  def test_that_parent_can_be_set
    n = Taxonifi::Model::Name.new() 
    n.rank = "genus"
    p = Taxonifi::Model::Name.new() 
    p.rank = "species"
    assert p.parent = n
    assert_equal "genus", p.parent.rank
  end

  def test_that_attributes_can_be_assigned_on_new
    n0 = Taxonifi::Model::Name.new(:name => "Baridae", :rank => "Family")
    n = Taxonifi::Model::Name.new(:name => "Foo", :rank => "Genus", :author => "Frank", :year => 2020, :parent => n0)
    assert_equal "Foo", n.name
    assert_equal "genus", n.rank
    assert_equal 2020, n.year
    assert_equal "Frank", n.author
    assert_equal n0, n.parent
  end

  def create_a_few_names
   @n0 = Taxonifi::Model::Name.new(:name => "Baridae", :rank => "Family", :id => 2)
   @n1 = Taxonifi::Model::Name.new(:name => "Barinae", :rank => "Subfamily", :id => 15, :parent => @n0)
   @n2 = Taxonifi::Model::Name.new(:name => "Foo", :rank => "Genus", :author => "Frank", :year => 2020, :id => 14,  :parent => @n1 )
   @n3 = Taxonifi::Model::Name.new(:name => "Bar", :rank => "Subgenus", :author => "Frank", :year => 2020, :id => 19,  :parent => @n2 )
   @n4 = Taxonifi::Model::Name.new(:name => "boo", :rank => "Species", :author => "Frank", :year => 2020, :id => 11,  :parent => @n3 )
  end

  def test_prologify
    create_a_few_names
    n0 = [
      "rank(#{@n0.id}, #{@n0.rank})",
      "edge(#{@n0.id}, #{@n0.parent ? @no.parent.id : "_"})",
      "name({@n0.id}, #{@n0.name})"
    ]
    assert_equal n0.join("\n") , @n0.prologify
  end

  def test_name_author_year_string
    create_a_few_names
    assert_equal 'Baridae', @n0.name_author_year_string
    assert_equal 'Barinae', @n1.name_author_year_string
    assert_equal 'Foo Frank, 2020', @n2.name_author_year_string
    assert_equal 'Bar Frank, 2020', @n3.name_author_year_string
    assert_equal 'boo Frank, 2020', @n4.name_author_year_string
  end

  def test_nomenclator_name
    create_a_few_names
    n5 = Taxonifi::Model::Name.new(:name => "beep", :rank => "Subspecies", :author => "Frank", :year => 2020, :id => 11,  :parent => @n4 )
    
    assert_equal 'Foo', @n2.nomenclator_name 
    assert_equal 'Foo (Bar)', @n3.nomenclator_name
    assert_equal 'Foo (Bar) boo', @n4.nomenclator_name
    assert_equal 'Foo (Bar) boo beep', n5.nomenclator_name
  end

  def test_ancestors
    create_a_few_names 
    assert_equal [@n0, @n1], @n2.ancestors
  end

  def test_ancestor_ids
    create_a_few_names 
    assert_equal [2,15], @n2.ancestor_ids
  end

  # TODO: fix to inject valid id to confirm to SF
  def test_parent_ids_sf_style
    create_a_few_names 
    assert_equal '2-15-14g-19s-11', @n4.parent_ids_sf_style
    assert_equal '2-15-14g-19s', @n3.parent_ids_sf_style
    assert_equal '2-15-14g', @n2.parent_ids_sf_style
    assert_equal '2-15', @n1.parent_ids_sf_style
  end 
 
  def test_author_year_index
    n = Taxonifi::Model::Name.new(author_year: 'Smith and Jones, 1920')
    assert_equal '1920-||smith|-||jones|', n.author_year_index
  end

  def test_genus_group_parent
    n1 = Taxonifi::Model::Name.new(name: "Fooidae", rank: "family",     author: nil ,    year: nil)                      # 
    n2 = Taxonifi::Model::Name.new(name: "Foo",     rank: "genus",      author: nil ,    year: nil,   :parent => n1)     # Foo
    n3 = Taxonifi::Model::Name.new(name: "Bar",     rank: "subgenus",   author: nil ,    year: nil,   :parent => n2)     # Foo (Bar)
    n4 = Taxonifi::Model::Name.new(name: "aus",     rank: "species",    author: nil ,    year: nil,   :parent => n3)     # Foo (Bar) aus 
    n5 = Taxonifi::Model::Name.new(name: "bus",     rank: "subspecies", author: 'Smith', year: 1920,  :parent => n4)     # Foo (Bar) aus bus

    assert_equal n3, n4.genus_group_parent
    assert_equal n3, n5.genus_group_parent
  end

  # 
  # ICZN Subclass
  #
  
  def test_that_iczn_family_ends_in_idae
    n = Taxonifi::Model::IcznName.new
    assert_raise Taxonifi::NameError do
      n.rank = "family"
      n.name = "Foo"
    end
  end

  def test_that_iczn_subfamily_ends_in_inae
    n = Taxonifi::Model::IcznName.new
    assert_raise Taxonifi::NameError do
      n.rank = "subfamily"
      n.name = "Foo"
    end
  end

  def test_that_iczn_tribe_ends_in_ini
    n = Taxonifi::Model::IcznName.new
    assert_raise Taxonifi::NameError do
      n.rank = "tribe"
      n.name = "Foo"
    end
  end

  def test_that_iczn_subtribe_ends_in_ina
    n = Taxonifi::Model::IcznName.new
    assert_raise Taxonifi::NameError do
      n.rank = "subtribe"
      n.name = "Foo"
    end

    assert n.name = "Fooina"
  end

end

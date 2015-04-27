require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
# require File.expand_path(File.join(File.dirname(__FILE__), '../lib/model/species_name')) 

class TestTaxonifiSpeciesName < Test::Unit::TestCase

  def test_truth
    assert(true)
  end

  def test_new_name
    assert n = Taxonifi::Model::SpeciesName.new() 
  end

  def test_that_name_has_a_genus
    assert n = Taxonifi::Model::SpeciesName.new() 
    assert n.respond_to?(:genus)
  end

  def test_that_name_has_a_subgenus
    assert n = Taxonifi::Model::SpeciesName.new() 
    assert n.respond_to?(:subgenus)
  end

  def test_that_name_has_a_species
    assert n = Taxonifi::Model::SpeciesName.new() 
    assert n.respond_to?(:species)
  end

  def test_that_name_has_a_sub_species
    assert n = Taxonifi::Model::SpeciesName.new() 
    assert n.respond_to?(:subspecies)
  end

  def test_that_parent_is_a_taxonifi_name
    n = Taxonifi::Model::SpeciesName.new() 
    assert_raise Taxonifi::SpeciesNameError do
      n.parent = "foo"
    end
  end

  def test_that_parent_rank_must_be_higher_than_genus
    n = Taxonifi::Model::SpeciesName.new() 
    p = Taxonifi::Model::Name.new() 
    p.rank = "species"
    assert_raise Taxonifi::SpeciesNameError do
      n.parent = p
    end
  end

  def test_that_names_are_taxonifi_names
    p = Taxonifi::Model::Name.new() 
  end

  def test_that_genus_must_be_assigned_before_species
    n = Taxonifi::Model::Name.new(:rank => 'species', :name => "foo")

    assert_raise Taxonifi::SpeciesNameError do
      sn = Taxonifi::Model::SpeciesName.new(:species => n) 
    end

    n.rank = 'genus'
    n.name = 'Foo'

    assert sn = Taxonifi::Model::SpeciesName.new(:genus => n) 
  end

  def test_that_species_must_be_assigned_before_subspecies
    n = Taxonifi::Model::Name.new(:rank => 'subspecies', :name => "foo")
    g = Taxonifi::Model::Name.new(:rank => 'genus', :name => "species")

    assert_raise Taxonifi::SpeciesNameError do
      sn = Taxonifi::Model::SpeciesName.new(:subspecies => n, :genus => g) 
    end
  end

  def test_display_name_formatting
    g  = Taxonifi::Model::Name.new(:rank => 'genus', :name => "Foo")
    sg = Taxonifi::Model::Name.new(:rank => 'subgenus', :name => "Bar")
    s  = Taxonifi::Model::Name.new(:rank => 'species', :name => "stuff")
    ss = Taxonifi::Model::Name.new(:rank => 'subspecies', :name => "things", :author => "Jones", :year => 2012 )
   
    sn1 = Taxonifi::Model::SpeciesName.new(:genus => g, :species => s) 
    assert_equal "Foo stuff", sn1.display_name

    sn2 = Taxonifi::Model::SpeciesName.new(:genus => g, :subgenus => sg, :species => s) 
    assert_equal "Foo (Bar) stuff", sn2.display_name

    sn3 = Taxonifi::Model::SpeciesName.new(:genus => g, :subgenus => sg, :species => s, :subspecies => ss) 
    assert_equal "Foo (Bar) stuff things Jones, 2012", sn3.display_name
  
    ss.parens = true 
    assert_equal "Foo (Bar) stuff things (Jones, 2012)", sn3.display_name
  end

  def test_new_from_string_for_simple_species_name
    string = "Foo bar Smith, 1920"
    sn = Taxonifi::Model::SpeciesName.new_from_string(string)
    assert_equal "Foo", sn.genus.name
    assert_equal "bar", sn.species.name
    assert_equal 1920, sn.species.year
    assert_equal "Smith", sn.species.authors.first.last_name
  end

  def test_new_from_string_for_more_complex_species_name
    string = 'Aus (Cus) bus dus (Smith, 1920)'
    sn = Taxonifi::Model::SpeciesName.new_from_string(string)
    assert_equal "Aus", sn.genus.name
    assert_equal "Cus", sn.subgenus.name
    assert_equal "bus", sn.species.name
    assert_equal "dus", sn.subspecies.name
    assert_equal 1920, sn.subspecies.year
    assert_equal "Smith", sn.subspecies.authors.first.last_name
    assert_equal true, sn.subspecies.parens
  end

  def test_new_from_simple_ampersand_authors
    string = 'Pericoma deceptrix Quate & Brown, 2004'
    sn = Taxonifi::Model::SpeciesName.new_from_string(string)
    assert_equal "Pericoma", sn.genus.name
    assert_equal nil, sn.subgenus
    assert_equal "deceptrix", sn.species.name
    assert_equal nil, sn.subspecies
    assert_equal 2004, sn.species.year 
    assert_equal "Quate", sn.species.authors.first.last_name
    assert_equal "Brown", sn.species.authors.last.last_name
    assert_equal false, sn.species.parens
  end

  def test_new_from_simple_ampersand_parened_authors
    string = 'Pericoma deceptrix (Quate & Brown, 2004)'
    sn = Taxonifi::Model::SpeciesName.new_from_string(string)
    assert_equal "Pericoma", sn.genus.name
    assert_equal nil, sn.subgenus
    assert_equal "deceptrix", sn.species.name
    assert_equal nil, sn.subspecies
    assert_equal 2004, sn.species.year 
    assert_equal "Quate", sn.species.authors.first.last_name
    assert_equal "Brown", sn.species.authors.last.last_name
    assert_equal true, sn.species.parens
  end




end

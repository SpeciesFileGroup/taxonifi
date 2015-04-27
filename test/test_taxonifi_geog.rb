require 'helper'

class TestTaxonifiGeog < Test::Unit::TestCase

  def test_new_name
    assert n = Taxonifi::Model::Geog.new() 
  end

  def test_that_geog_has_a_name
    n = Taxonifi::Model::Geog.new() 
    assert n.respond_to?(:name)
  end

  def test_that_geog_has_a_rank
    n = Taxonifi::Model::Geog.new() 
    assert n.respond_to?(:rank)
  end

  def test_that_geog_rank_is_checked
    n = Taxonifi::Model::Geog.new() 
    assert_raise Taxonifi::GeogError do
      n.rank = 'Foo'
    end
    assert n.rank = 'country' 
  end

  def test_that_setting_a_parent_checks_for_nil
    p = Taxonifi::Model::Geog.new() 
    c = Taxonifi::Model::Geog.new() 
    c.rank = 'state'
    assert_raise Taxonifi::GeogError do
      c.parent = nil
    end
  end

  def test_that_geog_rank_for_parents_is_checked
    p = Taxonifi::Model::Geog.new() 
    c = Taxonifi::Model::Geog.new() 

    c.rank = 'state'
    p.rank = 'country'

    assert_raise Taxonifi::GeogError do
      p.parent = c
    end

    assert c.parent = p 
  end

end

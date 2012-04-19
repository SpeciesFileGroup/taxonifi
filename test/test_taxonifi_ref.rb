require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/ref')) 

class TestTaxonifiRef < Test::Unit::TestCase

  def test_new_ref
    assert n = Taxonifi::Model::Ref.new() 
  end

  def test_that_a_ref_has_authors
    n = Taxonifi::Model::Ref.new() 
    assert n.respond_to?(:authors)
  end

end

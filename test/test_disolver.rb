require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/disolver/disolver')) 

class DisolverTest < Test::Unit::TestCase
  def test_truth
    assert true
  end
end

# Builder construction

class Test_AuthorYearBuilder < Test::Unit::TestCase
  def test_builder
    b = Taxonifi::Disolver::Model::AuthorYearBuilder.new
  end
end

class Test_TaxonifiDisolverLexer < Test::Unit::TestCase

  def test_that_vanilla_new_succeed
    assert lexer = Taxonifi::Disolver::Lexer.new("foo")
  end

  def test_that_lexer_can_only_be_passed_valid_token_lists
    assert_raises Taxonifi::Disolver::DisolverError do
      lexer = Taxonifi::Disolver::Lexer.new("foo", :bar)
    end
  end

  def test_that_lexer_can_be_created_with_token_list_subsets
    assert lexer = Taxonifi::Disolver::Lexer.new("foo")
  end

  # Token Tests

end 


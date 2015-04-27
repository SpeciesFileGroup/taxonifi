require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
# require File.expand_path(File.join(File.dirname(__FILE__), '../lib/splitter/splitter')) 

class SplitterTest < Test::Unit::TestCase
  def test_truth
    assert true
  end
end

class Test_TaxonifiSplitterLexer < Test::Unit::TestCase

  def test_that_vanilla_new_succeed
    assert lexer = Taxonifi::Splitter::Lexer.new("foo")
  end

  def test_that_lexer_can_only_be_passed_valid_token_lists
    assert_raises Taxonifi::Splitter::SplitterError do
      lexer = Taxonifi::Splitter::Lexer.new("foo", :bar)
    end
  end

  def test_that_lexer_can_be_created_with_token_list_subsets
    assert lexer = Taxonifi::Splitter::Lexer.new("foo")
  end

end 


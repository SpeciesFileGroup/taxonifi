require 'helper'

class Test_TaxonifiSplitterLexer < Test::Unit::TestCase

  def test_lexer_raises_when_not_hit
    lexer = Taxonifi::Splitter::Lexer.new("123a")
    assert_raises Taxonifi::Splitter::SplitterError do
      lexer.pop(Taxonifi::Splitter::Tokens::Year)
    end
  end

end

class Test_TaxonifiSplitterTokens < Test::Unit::TestCase

  def test_variety
    lexer = Taxonifi::Splitter::Lexer.new("var. blorf")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Variety)

    lexer = Taxonifi::Splitter::Lexer.new(" var. blorf")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Variety)

    lexer = Taxonifi::Splitter::Lexer.new("v. blorf")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Variety)
  
    lexer = Taxonifi::Splitter::Lexer.new("  v. blorf ")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Variety)
  end


  def test_year
    lexer = Taxonifi::Splitter::Lexer.new("1235")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Year)

    lexer = Taxonifi::Splitter::Lexer.new(" 1235")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Year)
 
    lexer = Taxonifi::Splitter::Lexer.new(" 1235  ")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Year)
 
    lexer = Taxonifi::Splitter::Lexer.new("1235  ")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Year)
 
    lexer = Taxonifi::Splitter::Lexer.new("1235\n  ")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Year)
  end

  def test_left_paren
    lexer = Taxonifi::Splitter::Lexer.new("(")
    assert lexer.pop(Taxonifi::Splitter::Tokens::LeftParen)
  
    lexer = Taxonifi::Splitter::Lexer.new(" (")
    assert lexer.pop(Taxonifi::Splitter::Tokens::LeftParen)

    lexer = Taxonifi::Splitter::Lexer.new(" ( ")
    assert lexer.pop(Taxonifi::Splitter::Tokens::LeftParen)
  end

  def test_right_paren
    lexer = Taxonifi::Splitter::Lexer.new(")")
    assert lexer.pop(Taxonifi::Splitter::Tokens::RightParen)
  
    lexer = Taxonifi::Splitter::Lexer.new(" )")
    assert lexer.pop(Taxonifi::Splitter::Tokens::RightParen)

    lexer = Taxonifi::Splitter::Lexer.new(" ) ")
    assert lexer.pop(Taxonifi::Splitter::Tokens::RightParen)
  end

  def test_comma
    lexer = Taxonifi::Splitter::Lexer.new(",")
    assert lexer.pop(Taxonifi::Splitter::Tokens::Comma)
  end

  def test_author_year
    # let's try some combinations
    authors = ["Foo", "Foo ", "Kukalova-Peck", "Grimaldi, Michalski & Schmidt", "Smith and Adams", "Smith, J.H.", "Smith, J.H. and Jones, Y.K.", "Lin."]
    comma = [true, false]
    years = ["", " 1993" ]
    parens = [true, false]

    authors.each do |a|
      years.each do |y|
        comma.each do |c|
          parens.each do |p|
            s = a.to_s + (comma ? "," : "") + y.to_s
            s = "(#{s})" if p
            lexer = Taxonifi::Splitter::Lexer.new(s)
            assert t = lexer.pop(Taxonifi::Splitter::Tokens::AuthorYear)
            assert_equal a.strip, t.authors
            assert_equal (y.size > 0 ? y.strip.to_i : nil), t.year # bad test
            assert_equal p, t.parens
            s = nil
          end
        end
      end
    end
  end

  def test_quadrinomial
    ["Foo"].each do |genus|
      ["(Bar)", nil].each do |subgenus|
        sg = nil
        sg = $1
        ["stuff"].each do |species|
          ["things", nil].each do |subspecies|
            str = [genus, subgenus, species, subspecies].compact.join(" ")
            if subgenus 
              sg = subgenus[-(subgenus.size-1)..-2] 
            else
              sg = nil
            end
            lexer = Taxonifi::Splitter::Lexer.new(str)
            t = lexer.pop(Taxonifi::Splitter::Tokens::Quadrinomial)
            assert_equal genus,      t.genus
            assert_equal sg,         t.subgenus
            assert_equal species,    t.species
            assert_equal subspecies, t.subspecies
          end
        end
      end
    end

    lexer = Taxonifi::Splitter::Lexer.new("Foo")
    t = lexer.pop(Taxonifi::Splitter::Tokens::Quadrinomial)
    assert_equal "Foo",      t.genus

    lexer = Taxonifi::Splitter::Lexer.new("Foo stuff")
    t = lexer.pop(Taxonifi::Splitter::Tokens::Quadrinomial)
    assert_equal "Foo",      t.genus
    assert_equal "stuff",      t.species

    lexer = Taxonifi::Splitter::Lexer.new('Foo (Bar) stuff things (Smith, 1912) and some other...')
    t = lexer.pop(Taxonifi::Splitter::Tokens::Quadrinomial)
    assert_equal "Foo",      t.genus
    assert_equal "Bar",      t.subgenus
    assert_equal "stuff",    t.species
    assert_equal "things",   t.subspecies
  end


  # Token is very flexible.  
  def test_authors
    auths = [
        "Jepson, J.E.,Makarkin, V.N., & Jarzembowski, E.A.",    # 0
        "Ren, D & Meng, X-m.",                                  # 1
        "Ren, D and Meng, X-m.",                                # 2
        "Smith, J.H. and Jones, Y.K.",                          # 3 
        "Thomas jr. D.B.",                                      # 4
        "Wighton, D.C., & Wilson, M.V.H.",                      # 5
        "Heyden, C.H.G. von & Heyden, L.F.J.D. von",            # 6 
        "Zhang, B., et al.",                                    # 7
        " Zhang, J.F. ",                                        # 8
        "Hong, Y-C.",                                           # 9 
        "Yan, E.V.",                                            # 10
        "Foo A, Bar ZA, Smith-Blorf A",                         # 11
        "Smith and Barnes",                                     # 12
        "Smith & Barnes",                                       # 13 
        "Smith",                                                # 14 
        "Smith, Jones and Simon",                               # 15
        "Van Duzee",                                            # 16
        "Walker, F.",                                           # 17
        "Watson, T. F., D. Langston, D. Fullerton, R. Rakickas, B. Engroff, R. Rokey, and L. Bricker",  # 18
        "Wheeler, A. G., Jr. and T. J. Henry.",                 # 19
        "Wheeler, A. G., Jr., B. R. Stinner, and T. J. Henry",  # 20
        "Wilson, L. T. and A. P. Gutierrez",                    # 21
        "Torre-Bueno, J. R. de la",                             # 22
        "Vollenhoven, S. C. S.",                                # 23
        "Usinger, R. L. and P. D. Ashlock",                     # 24
        "van den Bosch, R. and K. Hagen",                       # 25
        "Slater, J. A. and J. E. O'Donnell",                    # 26
        "O'Donnell, J.E. and Slater, J. A.",                    # 27
        "Van Steenwyk, R. A., N. C. Toscano, G. R. Ballmer, K. Kido, and H. T. Reynolds",                             # 28
        "Ward, C. R., C. W. O'Brien, L. B. O'Brien, D. E. Foster, and E. W. Huddleston",                              # 29
        "McPherson, R. M., J. C. Smith, and W. A. Allen",                                                             # 30
        "Oatman, E. R., J. A. McMurty, H. H. Shorey, and V. Voth",                                                    # 31
        "Ferrari, E. von ",                                                                                           # 32
        "Whitaker J. O., Jr., D. Rubin and J. R. Munsee",                                                             # 33
        "Palisot de Beauvois, A. M. F. J.",                                                                           # 34
        "Maa, T.-C. and K.-S. Lin",                                                                                   # 35
        "Costa Lima, A. M. da, C. A. Campos Seabra, and C. R. Hathaway",                                              # 36
        "Falcon, L. A., R. van den Bosch, C. A. Ferris, L. K. Stromberg, L. K. Etzel, R. E. Stinner, and T. F. Leigh",  # 37
        "Kinzer, R. E., J. W. Davis, Jr., J. R. Coppedge, and S. L. Jones",                                           # 38
        "Doesburg, P. H. van, Jr. ",                                                                                  # 39
        "Arias J. R., Young D. G."                                                                                    # 40 
    ]

    lexer = Taxonifi::Splitter::Lexer.new(auths[40])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Arias', 'Young'], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{J R}, %w{D G}] , t.names[0..1].collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[39])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Doesburg'], t.names.collect{|n| n[:last_name] }
    assert_equal "van Jr.", t.names[0][:suffix]

    lexer = Taxonifi::Splitter::Lexer.new(auths[38])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Kinzer', 'Davis', 'Coppedge', 'Jones'], t.names.collect{|n| n[:last_name] }
    assert_equal "Jr.", t.names[1][:suffix]

    lexer = Taxonifi::Splitter::Lexer.new(auths[37])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Falcon', 'van den Bosch', 'Ferris', 'Stromberg', 'Etzel', 'Stinner', 'Leigh'], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{L A}, %w{R}, %w{C A}] , t.names[0..2].collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[36])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Costa Lima', 'Campos Seabra', 'Hathaway'], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{A M}, %w{C A}, %w{C R}] , t.names.collect{|n| n[:initials] }
    assert_equal "da" , t.names.first[:suffix]

    lexer = Taxonifi::Splitter::Lexer.new(auths[35])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Maa', 'Lin'], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{T -C}, %w{K -S}] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[32])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Ferrari'], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{E}] , t.names.collect{|n| n[:initials] }
    assert_equal ['von'] , t.names.collect{|n| n[:suffix] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[31])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ['Oatman', 'McMurty', 'Shorey', 'Voth'], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{E R}, %w{J A}, %w{H H}, %w{V}] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[30])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["McPherson", "Smith", "Allen"], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{R M}, %w{J C}, %w{W A}] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[29])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Ward", "O'Brien", "O'Brien", "Foster", "Huddleston" ], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{C R}, %w{C W}, %w{L B}, %w{D E}, %w{E W}] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[28])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Van Steenwyk", "Toscano", "Ballmer", "Kido", "Reynolds" ], t.names.collect{|n| n[:last_name] }
    assert_equal [%w{R A}, %w{N C}, %w{G R}, %w{K}, %w{H T}] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[27])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["O'Donnell", "Slater" ], t.names.collect{|n| n[:last_name] }
    assert_equal [["J", "E"],["J", "A"]] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[26])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Slater", "O'Donnell"], t.names.collect{|n| n[:last_name] }
    assert_equal [["J", "A"],["J", "E"]] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[25])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["van den Bosch", "Hagen"], t.names.collect{|n| n[:last_name] }
    assert_equal [["R"],["K"]] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[24])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Usinger", "Ashlock"], t.names.collect{|n| n[:last_name] }
    assert_equal [["R", "L"],["P", "D"]] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[23])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Vollenhoven"], t.names.collect{|n| n[:last_name] }
    assert_equal [["S", "C", "S"]] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[22])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Torre-Bueno"], t.names.collect{|n| n[:last_name] }
    assert_equal [["J", "R"]] , t.names.collect{|n| n[:initials] }
    assert_equal "de la", t.names.first[:suffix]

    lexer = Taxonifi::Splitter::Lexer.new(auths[21])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Wilson", "Gutierrez"], t.names.collect{|n| n[:last_name] }
    assert_equal [["L", "T"], ["A", "P"]] , t.names.collect{|n| n[:initials] }

    lexer = Taxonifi::Splitter::Lexer.new(auths[20])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Wheeler", "Stinner", "Henry"], t.names.collect{|n| n[:last_name] }
    assert_equal [["A", "G"], ["B", "R"], ["T", "J"]] , t.names.collect{|n| n[:initials] }
    assert_equal "Jr.", t.names.first[:suffix]

    lexer = Taxonifi::Splitter::Lexer.new(auths[19])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Wheeler", "Henry"], t.names.collect{|n| n[:last_name] }
    assert_equal [["A", "G"], ["T", "J"]] , [t.names.first[:initials], t.names.last[:initials]]
    assert_equal "Jr.", t.names.first[:suffix]

    lexer = Taxonifi::Splitter::Lexer.new(auths[18])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal ["Watson", "Langston", "Fullerton", "Rakickas", "Engroff", "Rokey", "Bricker"], t.names.collect{|n| n[:last_name] }
    assert_equal [["T", "F"], ["L"]] , [t.names.first[:initials], t.names.last[:initials]]

    lexer = Taxonifi::Splitter::Lexer.new(auths[17])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 1, t.names.size
    assert_equal "Walker", t.names[0][:last_name]
    assert_equal ["F"], t.names[0][:initials]

    lexer = Taxonifi::Splitter::Lexer.new(auths[16])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 1, t.names.size
    assert_equal "Van Duzee", t.names[0][:last_name]

    lexer = Taxonifi::Splitter::Lexer.new(auths[15])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 3, t.names.size
    assert_equal "Smith", t.names[0][:last_name]
    assert_equal "Jones", t.names[1][:last_name]
    assert_equal "Simon", t.names[2][:last_name]

    lexer = Taxonifi::Splitter::Lexer.new(auths[14])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 1, t.names.size
    assert_equal "Smith", t.names[0][:last_name]

    lexer = Taxonifi::Splitter::Lexer.new(auths[13])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 2, t.names.size
    assert_equal "Smith", t.names[0][:last_name]
    assert_equal "Barnes", t.names[1][:last_name]

    lexer = Taxonifi::Splitter::Lexer.new(auths[12])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 2, t.names.size
    assert_equal "Smith", t.names[0][:last_name]
    assert_equal "Barnes", t.names[1][:last_name]

    lexer = Taxonifi::Splitter::Lexer.new(auths[0])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 3, t.names.size
    assert_equal "Jepson", t.names[0][:last_name]
    assert_equal "JE", t.names[0][:initials].join
    assert_equal "Jarzembowski", t.names[2][:last_name]
    assert_equal "EA", t.names[2][:initials].join

    lexer = Taxonifi::Splitter::Lexer.new(auths[1])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 2, t.names.size
    assert_equal "Ren", t.names[0][:last_name]
    assert_equal "D", t.names[0][:initials].join
    assert_equal "Meng", t.names[1][:last_name]
    assert_equal "X-m", t.names[1][:initials].join

    lexer = Taxonifi::Splitter::Lexer.new(auths[9])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 1, t.names.size
    assert_equal "Hong", t.names[0][:last_name]
    assert_equal "Y-C", t.names[0][:initials].join

    lexer = Taxonifi::Splitter::Lexer.new(auths[11])
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
    assert_equal 3, t.names.size
    assert_equal "Foo", t.names[0][:last_name]
    assert_equal "A", t.names[0][:initials].join
    assert_equal "Bar", t.names[1][:last_name]
    assert_equal "ZA", t.names[1][:initials].join
    assert_equal "Smith-Blorf", t.names[2][:last_name]
    assert_equal "A", t.names[2][:initials].join
  end

  def test_volume_number
    lexer = Taxonifi::Splitter::Lexer.new("42(123)", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "42", t.volume
    assert_equal "123", t.number

    lexer = Taxonifi::Splitter::Lexer.new("42:123", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "42", t.volume
    assert_equal "123", t.number

    lexer = Taxonifi::Splitter::Lexer.new("42", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "42", t.volume
    assert_equal nil, t.number

    lexer = Taxonifi::Splitter::Lexer.new("II(5)", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "II", t.volume
    assert_equal "5", t.number
 
    lexer = Taxonifi::Splitter::Lexer.new("99A", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "99A", t.volume
    assert_equal nil, t.number

    lexer = Taxonifi::Splitter::Lexer.new("99(2-3)", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "99", t.volume
    assert_equal "2-3", t.number

    lexer = Taxonifi::Splitter::Lexer.new("8(c4)", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "8", t.volume
    assert_equal "c4", t.number

    lexer = Taxonifi::Splitter::Lexer.new("74 (1/2)", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "74", t.volume
    assert_equal "1/2", t.number

    lexer = Taxonifi::Splitter::Lexer.new("74(1/2)", :volume_number)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
    assert_equal "74", t.volume
    assert_equal "1/2", t.number
  end

  def test_pages
    ["1-10", "1-10.", "1-10, something", "1-10. something"].each do |p|
      lexer = Taxonifi::Splitter::Lexer.new(p, :pages)
      assert t = lexer.pop(Taxonifi::Splitter::Tokens::Pages)
      assert_equal "1", t.pg_start
      assert_equal "10", t.pg_end
    end

    str = '12-33. ix 14, 19'
    lexer = Taxonifi::Splitter::Lexer.new(str, :pages)
    assert t = lexer.pop(Taxonifi::Splitter::Tokens::Pages)
    assert_equal "12", t.pg_start
    assert_equal "33", t.pg_end
    assert_equal "ix 14, 19", t.remainder

  end
end 


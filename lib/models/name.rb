module Taxonifi
  class NameError < StandardError; end

  # A taxonomic name.
  class Model::Name < Taxonifi::Model::Base

    # String
    attr_accessor  :name      
   
    # String 
    attr_accessor  :rank   
  
    # String
    attr_accessor  :author        
 
    # String, authors as originally read 
    attr_accessor  :year         

    # Boolean, true if parens present (i.e. _not_ in original combination) 
    attr_accessor  :parens       

    # A Taxonifi::Model::Name 
    attr_accessor  :parent      

    # A Taxonifi::Model::Name 
    # A general purpose relationship, typically used to indicate synonymy.
    attr_accessor  :related_name 

    # A Taxonifi::Model::Reference 
    # The original description. 
    attr_accessor :original_description_reference

    # An Array, contains assignable properties in Taxonifi::Model::Name#new()
    @@ATTRIBUTES = [:name, :rank, :year, :parens, :author, :related_name ]

    # An Array of Taxonifi::Model::Person 
    # Optionally parsed/index
    attr_accessor :authors                    

    # Optionally parsed/index
    attr_accessor :author_year_index    

    def initialize(options = {})
      super
      opts = {
        id: nil
      }.merge!(options)

      @parent = nil
      @authors ||= []

      build(@@ATTRIBUTES, opts)
      assign_author_year(opts)


      @id = opts[:id] 
      @parent = opts[:parent] if (!opts[:parent].nil? && opts[:parent].class == Taxonifi::Model::Name)
      @original_description_reference = opts[:original_description_reference] if (!opts[:original_description_reference].nil? && opts[:original_description_reference].class == Taxonifi::Model::Ref)

      true
    end 

    # Returns an Array of Taxonifi::Model::Person
    def add_author_year(string) # :yields: Array of Taxonifi::Model::Person
      auth_yr = Taxonifi::Splitter::Builder.build_author_year(string)
      @year = auth_yr.year
      @authors = auth_yr.people
    end

    # Translates the String representation of author year to an Array of People.
    # Used in indexing, when comparing Name microtations to Ref microcitations.
    def derive_authors_year
      add_author_year(author_year_string) 
    end

    # Set the rank.
    def rank=(rank)
      r = rank.to_s.downcase.strip
      if !RANKS.include?(r) 
        raise NameError, "#{r} is not a valid rank."
      end
      @rank = r
    end

    # Return a string indicating at what level this name 
    # is indexed within a NameCollection.
    # TODO: Family group extension; ICZN specific 
    def index_rank
      case rank
      when 'species', 'subspecies', 'variety'
        'species_group'
      when 'genus', 'subgenus'
        'genus_group'
      when nil, ""
        'unknown'
      else
        rank.downcase
      end
    end

    # Set the parent (a Taxonifi::Model::Name) 
    # Passing "true" allows you to bypass the parent level restriction, do so
    # with great caution.
    def parent=(parent)
      if @rank.nil?
        raise Taxonifi::NameError, "Parent of name can not be set if rank of child is not set." 
      end

      # TODO: ICZN class over-ride
      if parent.class != Taxonifi::Model::Name
        raise NameError, "Parent is not a Taxonifi::Model::Name."
      end

      if (RANKS.index(parent.rank) >= RANKS.index(self.rank))
        #  warn "WARNING:: Assigning parent to Name at same or lower rank than self (#{rank})."
        raise NameError, "Parent is same or lower rank than self (#{rank})."
      end

      @parent = parent
    end

    # Returns a formatted string, including parens for the name
    # TODO: rename to reflect parens
    def author_year
      au = author_year_string
      return nil if au.nil?
      (self.parens == true) ? "(#{au})" : au
    end


    # Return the author year string. 
    def author_year_string
      # Build based on People 

      auth = nil
      if authors.size > 0
        case authors.size
        when 1
          auth = self.author
        when 2 
          auth = authors.map(&:last_name).join(" & ")
        when 2...100
          auth =  authors[0..-1].map(&:last_name).join(", ") + " & " + authors.last.last_name
        end
        # Build based on string
      else
        auth = self.author
      end
      au = [auth, self.year].compact.join(", ")
      return nil if au.size == 0
      au
    end

    # Return a String, the human readable version of this name (genus, subgenus, species, subspecies, variety author, year)
    def display_name
      [nomenclator_name, author_year].compact.join(" ")
    end

    # Return a String, the human readable version of this name (genus, subgenus, species, subspecies)
    def nomenclator_name 
      case @rank
      # TODO: update for infrasubspecifics if we start tracking those
      when 'species', 'subspecies', 'genus', 'subgenus', 'variety'
        nomenclator_array.compact.join(" ")
      else
        @name
      end
    end

    # Return a Boolean, True if @rank is one of 'genus', 'subgenus', 'species', 'subspecies' 
    # TODO: update for infrasubspecifics if we start tracking those
    def nomenclator_name?
      %w{genus subgenus species subspecies variety}.include?(@rank)
    end

    # Return an Array of lenght 4 of Names representing a Species or Genus group name
    # [genus, subgenus, species, subspecies, infrasubspecific]
    def nomenclator_array
      case @rank
      when 'variety'
        return [parent_name_at_rank('genus'), (parent_name_at_rank('subgenus') ? "(#{parent_name_at_rank('subgenus')})" : nil), parent_name_at_rank('species'),  parent_name_at_rank('subspecies'), "var. #{@name}"]
      when 'species', 'subspecies'
        return [parent_name_at_rank('genus'), (parent_name_at_rank('subgenus') ? "(#{parent_name_at_rank('subgenus')})" : nil), parent_name_at_rank('species'),  parent_name_at_rank('subspecies'), nil]
      when 'subgenus'
        return [parent_name_at_rank('genus'), "(#{@name})", nil, nil, nil]
      when 'genus'
        return [@name, nil, nil, nil, nil]
      else
        return false
      end
       
    end

    # Return a Taxonifi::Model::Name representing the finest genus_group_parent.
    # TODO: ICZN specific(?)
    def genus_group_parent
      [ parent_at_rank('subgenus'), parent_at_rank('genus')].compact.first
    end
  
    # Returns just the name and author year, no parens, no parents. 
    # Like:
    #   foo Smith, 1927
    #   Foo Smith, 1927
    #   Fooidae
    def name_author_year_string
      [name, author_year_string].compact.join(" ")
    end

    # Return the name of a parent at a given rank.
    # TODO: move method to Base? 
    def parent_name_at_rank(rank)
      return self.name if self.rank == rank
      p = @parent
      i = 0
      while !p.nil?
        return p.name if p.rank == rank
        p = p.parent
        i+= 1
        raise NameError, "Loop detected among parents for [#{self.display_name}]." if i > 75 
      end
      nil 
    end

    # Return the parent at a given rank.
    # TODO: move method to Base? 
    def parent_at_rank(rank)
      return self if self.rank == rank
      p = @parent
      i = 0
      while !p.nil?
        return p if p.rank == rank
        p = p.parent
        raise NameError, "Loop detected among parents fo [#{self.display_name}]" if i > 75 
      end
      nil 
    end

        # Return a dashed "vector" of ids representing the ancestor parent closure, like:
    #  0-1-14-29g-45s-99-100.
    #  Postfixed g means "genus", postifed s means "subgenus.  As per SpecieFile usage.
    #  TODO: !! malformed because the valid name is not injected.  Note that this can be generated internally post import.
    def parent_ids_sf_style
      ids = [] 
      (ancestors.push self).each do |a|
        case a.rank
        when 'genus'
          ids.push "#{a.id}g"
        when 'subgenus'
          ids.push "#{a.id}s"
        else
          ids.push a.id.to_s
        end
      end
      ids.join("-")
    end

    # Return a Taxonifi::Model::AuthorYear representing author/year
    # !! Identical to method in Taxonifi::Model::Ref
    # !! *Not* necessarily unique.
    def author_year_index
      @author_year_index ||= generate_author_year_index
    end

    # Generate and return (String) the author year index.
    def generate_author_year_index
      @author_year_index = Taxonifi::Model::AuthorYear.new(people: @authors, year: @year).compact_index
    end

    # TODO: test
    # Returne True of False based on @rank
    def species_group?
      true if @rank == 'species' || @rank == 'subspecies'
    end

    # TODO: test
    # Returne True of False based on @rank
    def genus_group?
      true if @rank == 'genus' || @rank == 'subgenus'
    end

    # Return a String of Prolog rules representing this Name
    def prologify
      "false"
    end

  protected

  # Generate @authors = [People], @year = 1999 from incoming initialization options.
  def assign_author_year(opts)
    # If for some reason already set get out
    raise NameError, "Name initialization error, @authors set prior to conversionf from @author_year." if @year && !@authors.nil? && @authors.size > 0
    author_year = nil
    if !opts[:author_year].nil? && (opts[:author_year].size > 0)
      author_year = opts[:author_year]
    elsif !opts[:author].nil? && !@year.nil? && (opts[:author].size > 0) && (@year.size > 0)
      author_year = opts[:author] + ", " + @year.to_s
    end

    if !author_year.nil?
      if ay = Taxonifi::Splitter::Builder.build_author_year(author_year) 
        @year = ay.year
        @authors = ay.people
        true
      else
        false
      end
    end
  end



  end 

  # ICZN specific sublassing of a taxonomic name.
  # !! Minimally tested and not broadly implmented.
  class Model::IcznName < Taxonifi::Model::Name
    def initialize
      super
    end
    
    # Set the name, checks for family group restrictions. 
    def name=(name)
      case @rank
      when 'superfamily'
        raise NameError, "ICZN superfamily name does not end in 'oidae'." if name[-5,5] != 'oidae'
      when 'family'
        raise NameError, "ICZN family name does not end in 'idae'." if name[-4,4] != 'idae'
      when 'subfamily'
        raise NameError, "ICZN subfamily name does not end in 'inae'." if name[-4,4] != 'inae'
      when 'tribe'
        raise NameError, "ICZN tribe name does not end in 'ini'." if name[-3,3] != 'ini'
      when 'subtribe'
        raise NameError, "ICZN subtribe name does not end in 'ina'." if name[-3,3] != 'ina'
      end
      @name = name
    end
  end

end

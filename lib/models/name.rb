module Taxonifi

  class NameError < StandardError; end

  module Model
    class Name < Taxonifi::Model::Base

      ATTRIBUTES = [
        :name,         # String                                                  
        :rank,         # String
        :year,         # String, authors as originally read
        :parens,       # String
        :parent,       # Boolean, true if original combination, false if not
        :author,       # Model::Name
        :related_name  # Model::Name                                              
      ]

      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      # optionally parsed/index
      attr_accessor :authors               
      attr_accessor :author_year_index

      def initialize(options = {})
        opts = {
          id: nil
        }.merge!(options)
        @parent = nil
        build(ATTRIBUTES, opts)
        add_author_year(opts[:author_year]) if !opts[:author_year].nil? && opts[:author_year].size > 0
        @parent = opts[:parent] if (!opts[:parent].nil? && opts[:parent].class == Taxonifi::Model::Name)
        @id = opts[:id] # if !opts[:id].nil? && opts[:id].size != 0
        @authors ||= []
        true
      end 

      def add_author_year(string)
        auth_yr = Taxonifi::Splitter::Builder.build_author_year(string)
        @year = auth_yr.year
        @authors = auth_yr.people
      end

      def derive_authors_year
        add_author_year(author_year_string) 
      end

      def rank=(rank)
        r = rank.to_s.downcase.strip
        if !RANKS.include?(r) 
          raise NameError, "#{r} is not a valid rank."
        end
        @rank = r
      end

      def parent=(parent)
        if @rank.nil?
          raise Taxonifi::NameError, "Parent of name can not be set if rank of child is not set." 
        end

        # todo: ICZN class over-ride
        if parent.class != Taxonifi::Model::Name
          raise NameError, "Parent is not a Taxonifi::Model::Name."
        end

        if RANKS.index(parent.rank) >= RANKS.index(self.rank)
          raise NameError, "Parent is same or lower rank than self (#{rank})."
        end

        @parent = parent
      end

      # TODO: Build row-wise instantiation?
      def self.new_from_row(csv_row)
        n = self.new
        n.rank = Taxonifi::Assessor::RowAssessor.lump_rank
      end

      # Returns a formatted string, including parens for the name
      # TODO: rename to reflect parens
      def author_year
        au = author_year_string
        if self.parens == false
          "(#{au})"        
        else
          au.size == 0 ? nil : au
        end
      end

      # No parens
      def author_year_string
        au = [self.author, self.year].compact.join(", ")
      end

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

      def display_name
        [nomenclator_name, author_year].compact.join(" ")
      end

      def nomenclator_name 
        case @rank
        when 'species', 'subspecies'
          [parent_name_at_rank('genus'), (parent_name_at_rank('subgenus') ? "({parent_name_at_rank('subgenus')})" : nil), parent_name_at_rank('species'), @name].compact.join(" ")
        when 'subgenus'
          [parent_name_at_rank('genus'), "(#{@name})"].compact.join(" ")
        else
          [@name].compact.join(" ")
        end
      end

      def parent_ids_sf_style
        ids = [] 
        ancestors.each do |a|
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
  
      def author_year_index
        @author_year_index ||= generate_author_year_index
      end

      def generate_author_year_index
        @author_year_index = Taxonifi::Model::AuthorYear.new(people: @authors, year: @year).compact_index
      end

    end 


    # Candidates for IcznName < Taxonify::Model::Name
    class IcznName < Taxonifi::Model::Name

      def initialize
        super
      end

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



end

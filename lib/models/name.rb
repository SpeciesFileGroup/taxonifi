module Taxonifi

  class NameError < StandardError; end

  module Model
    class Name < Taxonifi::Model::Base

      ATTRIBUTES = [:name, :rank, :year, :original_combination, :parent, :author]
      attr_accessor :name                  # String
      attr_accessor :rank                  # String
      attr_accessor :author                # String
      attr_accessor :year                  # String
      attr_accessor :original_combination  # Boolean = parens check on author year, perhaps subclass in SpeciesName < Name
      attr_accessor :parent                # Model::Name

      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      def initialize(options = {})
        opts = {
        }.merge!(options)
        @parent = nil
        build(ATTRIBUTES, opts)
        @parent = opts[:parent] if (!opts[:parent].nil? && opts[:parent].class == Taxonifi::Model::Name)
        true
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
      def author_year
        au = [self.author, self.year].compact.join(", ")
        if self.original_combination == false
          "(#{au})"        
        else
          au.size == 0 ? nil : au
        end
      end

      def parent_name_at_rank(rank)
        p = @parent
        while !p.nil?
          return p.name if p.rank == rank
          p = p.parent
        end
        nil 
      end

      def display_name
        case @rank
        when 'species', 'subspecies'
          [parent_name_at_rank('genus'), parent_name_at_rank('subgenus'), parent_name_at_rank('species'), @name, author_year].compact.join(" ")
        else
          [@name, author_year].compact.join(" ")
        end
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

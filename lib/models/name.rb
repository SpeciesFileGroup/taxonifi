module Taxonifi

  module Model
    class Name
      attr_accessor :name, :parent, :id, :rank, :author, :year
      def initialize(options = {})
        @parent = nil
        true
      end 

      def rank=(rank)
        r = rank.downcase.strip
        if !RANKS.include?(r) 
          raise NameError,  "#{r} is not a valid rank."
        end
        @rank = r
      end

      def parent=(parent)
        if @rank.nil?
          raise Taxonifi::NameError 
        end

        if parent.class != Taxonifi::Model::Name
          raise NameError, "Parent is not a Taxonifi::Model::Name."
        end

        if RANKS.index(parent.rank) >= RANKS.index(self.rank)
          raise NameError, "Parent is same or lower rank than self (#{rank})."
        end

        @parent = parent
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

  class NameError < StandardError
  end

end

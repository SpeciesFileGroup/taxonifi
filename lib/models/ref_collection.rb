module Taxonifi
  class RefCollectionError < StandardError; end

  module Model

    # A collection of references.
    class RefCollection < Taxonifi::Model::Collection

      # An options index when there is one reference per row.
      # A Hash.  {:row_number => Ref
      attr_accessor :row_index
     
      # Points a Ref#id to an array of Person#ids.  
      # Built on request.
      attr_accessor :author_index 

      def initialize(options = {})
        super
        @row_index = []
        @author_index = {}
        @fingerprint_index = {}
        true
      end 

      # The instance collection class.
      def object_class
        Taxonifi::Model::Ref  
      end
        
      # The object at a given row.
      # TODO: inherit from Collection? 
      def object_from_row(row_number)
        return nil if row_number.nil?
        @row_index[row_number]
      end

      # Incrementally (re-)assigns the id of every associated author (Person) 
      # This is only useful if you assume every author is unique.
      def enumerate_authors(initial_id = 0)
        i = initial_id 
        collection.each do |r|
          r.authors.each do |a|
            a.id = i
            i += 1
          end
        end
      end

      # Finds unique authors, and combines them, then 
      # rebuilds author lists using references to the new unique set.
      def uniquify_authors(initial_id = 0)
        auth_index = {}
        unique_authors.each_with_index do |a, i|
          a.id = i + initial_id
          auth_index.merge!(a.compact_string => a)
        end
        
        collection.each do |r|
          new_authors = []
          r.authors.inject(new_authors){|ary, a| ary.push(auth_index[a.compact_string])}
          r.authors = new_authors
        end
        true 
      end

      # Build the author index. 
      #   {Ref#id => [a1#id, ... an#id]}
      def build_author_index
        collection.each do |r|
          @author_index.merge!(r.id => r.authors.collect{|a| a.id ? a.id : -1})
        end
      end

      # Return an array the unique author strings in this collection.
      def unique_author_strings
        auths = {}
        collection.each do |r|
          r.authors.each do |a|
            auths.merge!(a.display_name => nil)
          end
        end
        auths.keys.sort
      end

      # Returns Array of Taxonifi::Model::Person
      # Will need better indexing on big lists?
      def unique_authors
        auths = []
        collection.each do |r|
          r.authors.each do |a|
            found = false
            auths.each do |x|
              if a.identical?(x)
                found = true 
                next           
              end
            end
            if not found
              auths.push a.clone
            end
          end
        end
        auths
      end

    end
  end

end

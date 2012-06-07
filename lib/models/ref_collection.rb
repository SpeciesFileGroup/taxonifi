module Taxonifi
  class RefCollectionError < StandardError; end

  module Model

    class RefCollection < Taxonifi::Model::Collection
    
      attr_accessor :row_index
      attr_accessor :author_index # Built on request, keep from ATTRIBUTES

      def initialize(options = {})
        super
        @row_index = []
        @author_index = {}
        true
      end 

      def object_class
        Taxonifi::Model::Ref  
      end
         
      def object_from_row(row_number)
        @row_index[row_number]
      end

      # (Re) Assigns the id of every associated author (Person).
      # This is only really useful if you assume every author is unique.
      def enumerate_authors(initial_id = 0)
        i = initial_id 
        collection.each do |r|
          r.authors.each do |a|
            a.id = i
            i += 1
          end
        end
      end

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

      def build_author_index
        collection.each do |r|
          @author_index.merge!(r.id => r.authors.collect{|a| a.id ? a.id : -1})
        end
      end

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

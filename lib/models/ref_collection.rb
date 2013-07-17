module Taxonifi
  class RefCollectionError < StandardError; end

  module Model

    # A collection of references.
    class RefCollection < Taxonifi::Model::Collection

      # An options index when there is one reference per row.
      # A Hash.  {:row_number => Ref
      attr_accessor :row_index
     
      # A Hash. Keys are  Ref#id, values are an Array of Person#ids.  
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
        collection.each do ||r
          r.authors.each do |a|
            a.id = i
            i += 1
          end
        end
      end

      # Finds unique authors, and combines them, then 
      # rebuilds author lists using references to the new unique set.
      def uniquify_authors(initial_id = 0)

        matching_index = {
          # ref_id => { 'ref_string_fingerprint' => [author_position in Ref.authors]} 
        }

        author_fingerprints = {}

        # First pass, build matching array
        collection.each do |r|
          # Check for, and modify where necessary, Authors that are clearly not unique because
          # they are replicated names in a author string, e.g. "Sweet and Sweet". 
          matching_index[r.id] = {}
          r.authors.each_with_index do |a,i|
            id = a.compact_string
            if matching_index[r.id][id]
              matching_index[r.id][id].push(i)
            else
              matching_index[r.id][id] = [i]
            end
          end
        end

        # Next pass, modify names of necessarily unique authors so
        # their fingerprint is unique.  Note we do not differentiate
        # b/w sequential sets.
        # E.g. if we have 5 names like so:
        # Quate [1] and Quate [2]
        # Quate [3], Smith [4] and Quate [5]
        # Then [1,3], [2,5] become the same Person in this process.  We can not
        # of course differentiate order, or if a 3rd "Quate" is present here given
        # only this information.  Later on we might use Year of publication, or something
        # similar to further "guess".
        collection.each do |r|
          matching_index[r.id].keys.each do |i|
            if matching_index[r.id][i].size > 1
              matching_index[r.id][i].each_with_index do |j,k|
                # puts "uniquifying:" + "\_#{k}\_#{r.authors[j].last_name}"
                r.authors[j].last_name = "\_#{k}\_#{r.authors[j].last_name}"
              end
            end
          end
        end

        # Generate new authors based on identity 
        authors = [] 
        collection.each do |r|
          r.authors.each do |a|
            found = false
            authors.each do |x|
              if a.identical?(x)
                found = true 
                next           
              end
            end
            if not found
              authors.push a.clone
            end
          end
        end

        # Sequentially number the new authors, and index them.
        auth_index = {}
        authors.each_with_index do |a, i|
          a.id = i + initial_id
          auth_index.merge!(a.compact_string => a)
        end
       
        # Replace old authors with newly built/sequntially id'ed authors 
        collection.each do |r|
          new_authors = []
          r.authors.inject(new_authors){|ary, a| ary.push(auth_index[a.compact_string])}
          r.authors = new_authors
        end

        # Remove the modifications that made authors unique 
        # Crude to loop those unnecessary, but clean
        authors.each do |a|
          a.last_name.gsub!(/\_\d+\_/, '')
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

      # Return an Array the unique author strings in this collection. 
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
      # !! Runs uniquify first. Careful, you might not want to do this
      # !! unless you understand the consequences.
      def unique_authors
        uniquify_authors
        all_authors
      end    


      # Returns Array of Taxonifi::Model::Person
      def all_authors
        @collection.collect{|r| r.authors}.flatten.compact.uniq
      end 

    end
  end

end

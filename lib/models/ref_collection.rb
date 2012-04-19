module Taxonifi
  

  class RefCollectionError < StandardError; end

  module Model

    class RefCollection < Taxonifi::Model::Collection
      attr_reader :refs
      
      def initialize(options = {})
        super
        @refs = []
        true
      end 

      # Method also indexes refs
      def add_ref(ref)
        raise RefCollectionError, "Taxonifi::Model::Ref not passed to RefCollection.add_ref." if !(ref.class == Taxonifi::Model::Ref)
        raise RefCollectionError, "Taxonifi::Model::Ref#id may not be pre-initialized if used in a RefCollection." if !ref.id.nil?

        ref.id = @current_free_id
        @current_free_id += 1

        @refs.push(ref)

        @by_id_index.merge!(ref.id => ref)
        return ref.id
      end
          
    end
  end

end

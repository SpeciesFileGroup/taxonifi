module Taxonifi
  class RefCollectionError < StandardError; end

  module Model

    class RefCollection < Taxonifi::Model::Collection
      
      def initialize(options = {})
        super
        true
      end 

      def object_class
        Taxonifi::Model::Ref  
      end
          
    end
  end

end

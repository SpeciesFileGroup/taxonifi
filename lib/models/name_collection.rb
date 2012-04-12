module Taxonifi
  module Model

    class NameCollection
      attr_accessor :names
      def initialize(options = {})
        @names = []
        true
      end 
    end
  end

end

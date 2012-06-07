module Taxonifi
  class ModelError < StandardError; end
  module Model

    # A generic object, has name, parent, rank properties. 
    class GenericObject < Base 
      # String
      attr_accessor :name
      # Parent object, same class as self
      attr_accessor :parent
      # String, arbitrarily assignable rank
      attr_accessor  :rank
    end
  end
end

module Taxonifi

  class ModelError < StandardError; end

  module Model
    class GenericObject < Base # < Struct.new(:id, :row_number)

      attr_accessor :name, :parent, :rank

        # Check for valid opts in subclass prior to building
    end
  end
end

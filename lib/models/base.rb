module Taxonifi

  class ModelError < StandardError; end

  module Model
    class Base # < Struct.new(:id, :row_number)

      attr_accessor :id, :row_number

        # Check for valid opts in subclass prior to building

        def build(attributes, opts)
          attributes.each do |c|
            self.send("#{c}=",opts[c]) if !opts[c].nil?
          end
        end

    end
  end
end

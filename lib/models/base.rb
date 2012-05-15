module Taxonifi

  class ModelError < StandardError; end

  module Model
    class Base # < Struct.new(:id, :row_number)

      attr_accessor :id, :row_number, :external_id

        # Check for valid opts in subclass prior to building

        def build(attributes, opts)
          attributes.each do |c|
            self.send("#{c}=",opts[c]) if !opts[c].nil?
          end
        end

        def id=(id)
          raise Taxonifi::ModelError, "Base model objects must have Fixnum ids." if !id.nil? && id.class != Fixnum
          @id = id
        end

        # Immediate parent id [].last
        def parent_ids
          i = 0 # check for recursion
          ids = []
          p = parent 
          while !p.nil?
            ids.unshift p.id
            p = p.parent
            i += 1
            raise Taxonifi::ModelError, "Infite recursion in parent string detected for Base model object #{id}." if i > 100
          end
          ids
        end

    end
  end
end

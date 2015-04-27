module Taxonifi::Model::SharedClassMethods
  def self.included(base)
    base.class_eval do

      # Return an array of the classes derived from the base class.
      # TODO: DRY with collection code.
      def self.subclasses
        classes = []
        ObjectSpace.each_object do |klass|
          next unless Module === klass
          classes << klass if self > klass
        end
        classes
      end

      # Determines identity base ONLY
      # on attributes in ATTRIBUTES.
      def identical?(obj)
        raise Taxonifi::ModelError, "Objects are not comparible." if obj.class != self.class
        self.class::ATTRIBUTES.each do |a|
          next if a == :id # don't compare
          return false if obj.send(a) != self.send(a)
        end
        return true
      end

    end
  end
end

module Taxonifi
  module Model
    class Person < Taxonifi::Model
      attr_accessor :first_name, :last_name, :initials, :suffix
      def initialize
      end
    end
  end
end

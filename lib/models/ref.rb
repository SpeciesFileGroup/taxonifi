module Taxonifi

  class RefError < StandardError; end

  module Model
    class Ref
      attr_accessor :id, :parent
      attr_accessor :authors
      attr_accessor :year
      def initialize(options = {})
        opts = {
        }.merge!(options)
        @parent = nil

        self.name = opts[:name] if !opts[:name].nil?
        self.parent = opts[:parent] if !opts[:parent].nil?

        true
      end 
    end
  end
end

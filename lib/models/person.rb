require File.expand_path(File.join(File.dirname(__FILE__), "../models/base.rb"))

module Taxonifi
  module Model
    class Person < Taxonifi::Model::Base
      ATTRIBUTES = [:first_name, :last_name, :initials, :suffix]
      
      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      def initialize(options = {})
        opts = {
        }.merge!(options)

        # Check for valid opts prior to building

        build(ATTRIBUTES, opts)
        
        true
      end

      def compact_string
        s = [ATTRIBUTES.sort.collect{|a| send(a)}].join("|").downcase.gsub(/\s/, '')
      end
    end
  end
end

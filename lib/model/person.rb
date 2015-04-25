require File.expand_path(File.join(File.dirname(__FILE__), "../model/base.rb"))

module Taxonifi
  module Model

    # Simple Person class. 
    # You can store multiple initials and suffixes.
    class Person < Taxonifi::Model::Base
      ATTRIBUTES = [
        :first_name,
        :last_name,
        :initials,    # an Array, no periods.
        :suffix       # an Array
      ]
      
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

      # Returns a string with data delimited by pipes.
      # Used in identity comparisons.
      def compact_string
        s = [ATTRIBUTES.sort.collect{|a| send(a)}].join("|").downcase.gsub(/\s/, '')
      end

      # Nothing fancy, just the data.
      def display_name
        [@last_name, @first_name, @initials, @suffix].compact.flatten.join(" ")
      end

      # Return a string representing the initials, periods added.
      def initials_string
        if @initials.nil? 
          nil
        else 
          @initials.join(".") + "." 
        end 
      end
    end
  end
end

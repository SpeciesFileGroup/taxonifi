require File.expand_path(File.join(File.dirname(__FILE__), '../taxonifi'))

# Generic Array methods
module Taxonifi::Utils
  module Hash 

    # Return an Array of length size of black Arrays
    def self.build_hash_of_hashes_with_keys(keys)
      h = {} 
      keys.each do |k|
        h[k] = {}
      end
      h
    end

  end # end Taxonifi::Utils::Array Module 
end 

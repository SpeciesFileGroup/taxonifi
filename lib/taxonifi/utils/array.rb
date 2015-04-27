# Generic Array methods
module Taxonifi::Utils
  module Array

    # Return an Array of length size of black Arrays
    def self.build_array_of_empty_arrays(size)
      a = []
      (0..(size-1)).each do |i|
        a[i] = []
      end
      a
    end

  end # end Taxonifi::Utils::Array Module 
end 

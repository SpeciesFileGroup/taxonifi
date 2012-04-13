# The Lumper lumps!

module Taxonifi
  module Lumper 

    class LumperError < StandardError; end

    QUAD =  ['genus', 'subgenus', 'species', 'subspecies']
    AUTHOR_YEAR = ['author', 'year']

    LUMPS = {
      quadrinomial: QUAD,
      quad_author_year: QUAD + AUTHOR_YEAR,
      names:  Taxonifi::RANKS + AUTHOR_YEAR
    }

    def self.available_lumps(columns)
      raise Taxonifi::Lumper::LumperError, 'Array not passed to Lumper.available_lumps.' if !(columns.class == Array)
      lumps = LUMPS.keys.select{|k| (LUMPS[k] - columns) == []}
    end

   end # end Lumper Module 
end # Taxonifi module


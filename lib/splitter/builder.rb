
module Taxonifi::Splitter::Builder

    # Load all builders (= models)
    #  TODO: perhaps use a different scope that doesn't require loading all at once
    Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "../models/*.rb") )) do |file|
      require file
    end

end

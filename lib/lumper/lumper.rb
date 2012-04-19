# Define groups of columns/fields and include
# functionality to determine whether your
# columns match a given set.


module Taxonifi
  module Lumper 

    class LumperError < StandardError; end

    QUAD =  ['genus', 'subgenus', 'species', 'subspecies']
    AUTHOR_YEAR = ['author', 'year']

    LUMPS = {
      quadrinomial: QUAD,
      quad_author_year: QUAD + AUTHOR_YEAR,
      names:  Taxonifi::RANKS + AUTHOR_YEAR,
      higher: Taxonifi::RANKS - [QUAD + AUTHOR_YEAR],
      species: ['species', 'subspecies'],
      genera: ['genus', 'subgenus']
    }

    def self.available_lumps(columns)
      raise Taxonifi::Lumper::LumperError, 'Array not passed to Lumper.available_lumps.' if !(columns.class == Array)
      LUMPS.keys.select{|k| (LUMPS[k] - columns) == []}
    end

    def self.create_name_collection(csv)
      raise Taxonifi::Lumper::LumperError, 'Something that is not a CSV::Table was passed to Lumper.create_name_collection.' if csv.class != CSV::Table
      nc = Taxonifi::Model::NameCollection.new

      # TODO: index, start with higher

      #root = Taxonifi::Model::Name.new
      #root.name = 'root' 
      #nc.names << root 

      # The row index contains a vector of parent ids like
      # [0, 4, 29]
      # This implies that Name with #id 29 has Parent with #id 4
      row_size = csv.size
      row_index = []
      (0..(row_size-1)).each do |i|
        row_index[i] = []
      end

      # name_index keeps track of unique names  
      name_index = {} 

      # First pass, create and index names
      Taxonifi::Assessor::RowAssessor.rank_headers(csv.headers).each do |rank|
        name_index[rank] = {}
        csv.each_with_index do |row, i|
          name = row[rank] 

          if !name.nil?  # cell has data
            n = nil         # a Name if necessary
            name_id = nil   # index to a Name if necessary

            if name_index[rank][name] # name exists

              exists = false 
              name_index[rank][name].each do |id|
                if nc.parent_id_vector(id) == row_index[i]
                  # name is present
                  exists = true
                  name_id = id
                  break # don't need to check further
                end 
              end

              if !exists
                n = Taxonifi::Model::Name.new(:rank => rank, :name => row[rank])
              end

            else # no version of the name exists

              n = Taxonifi::Model::Name.new(:rank => rank, :name => row[rank])

            end # end name exists

            if !n.nil?
              n.parent = nc.name_by_id(row_index[i].last) if row_index[i].size > 0 # it's parent is the previous in this row 
              name_id = nc.add_name(n) 
              name_index[rank][name] = [] if !name_index[rank][name] 
              name_index[rank][name].push name_id    # build an index of unique names
            end

            # add the index
            row_index[i].push name_id                       # build a vector of parent child relationships
          end # end cell has data

        end
      end

      nc
    end 


  end # end Lumper Module 
end # Taxonifi module


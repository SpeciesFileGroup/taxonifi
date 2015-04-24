require File.expand_path(File.join(File.dirname(__FILE__), '../taxonifi'))

# The lumper lumps! Tools for recognizing and using 
# combinations of column types. 
module Taxonifi::Lumper 

  # Define groups of columns/fields and include
  # functionality to determine whether your
  # columns match a given set.
  module Lumps
    Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "lumps/*.rb") )) do |file|
      require file
    end
  end

  class LumperError < StandardError; end

  # Columns used for species epithets.
  # !! Todo: map DwC URIs to these labels (at present they largely correllate with Tokens,
  # perhaps map URIs to tokens!?)
  QUAD =  ['genus', 'subgenus', 'species', 'subspecies']
  
  # Columns representing author and year 
  AUTHOR_YEAR = ['author', 'year']

  # A Hash of named column combinations
  LUMPS = {
    quadrinomial: QUAD,
    quad_author_year: QUAD + AUTHOR_YEAR,
    names:  Taxonifi::RANKS + AUTHOR_YEAR,
    higher: Taxonifi::RANKS - [QUAD + AUTHOR_YEAR],
    species: ['species', 'subspecies', 'variety'],
    genera: ['genus', 'subgenus'],
    citation_basic: %w{authors year title publication volume number pages pg_start pg_end},
    citation_small: %w{authors year title publication volume_number pages},
    basic_geog: %w{country state county}, # add 'continent'
    eol_basic: %w{identifier parent child rank synonyms}
  }

  # Authors, Year, Title, Publication, Volume_Number Pages Cited_Page

  # Lumps for which all columns are represented 
  # TODO: This is really an assessor method 
  def self.available_lumps(columns)
    raise Taxonifi::Lumper::LumperError, 'Array not passed to Lumper.available_lumps.' if !(columns.class == Array)
    LUMPS.keys.select{|k| (LUMPS[k] - columns) == []}
  end

  # Lumps for which any column is represented 
  # # TODO: This is really an assessor method 
  def self.intersecting_lumps(columns)
    raise Taxonifi::Lumper::LumperError, 'Array not passed to Lumper.intersecting_lumps.' if !(columns.class == Array)
    intersections = []
    LUMPS.keys.each do |k|
      intersections.push k if (LUMPS[k] & columns).size > 0
    end
    intersections
  end

 
  # Return a Taxonifi::Model::NameCollection from a csv file.
  def self.create_name_collection(options = {})
    opts = {
      :csv => [],
      :initial_id => 0,
      :capture_related_fields => true   # Stores other column values in (column_header => value) pairs in Name#properties
    }.merge!(options)
    
    csv = opts[:csv]
    raise Taxonifi::Lumper::LumperError, 'Something that is not a CSV::Table was passed to Lumper.create_name_collection.' if csv.class != CSV::Table
    
    nc = Taxonifi::Model::NameCollection.new(:initial_id => opts[:initial_id])
    row_size = csv.size

    # The row index contains a vector of parent ids like
    # [0, 4, 29]
    # This implies that Name with #id 29 has Parent with #id 4
    # Initialize an empty index. 
    row_index = Taxonifi::Utils::Array.build_array_of_empty_arrays(row_size)

    # The name_index keeps track of unique name per rank like
    # :genus => {'Foo' => [0,2]}
    # This says that "Foo" is instantiated two times in the
    # name collection, with id 0, and id 2.
    name_index = {} # Taxonifi::Lumper::NameIndex.new # {} 

    has_ref_fields = ([:citation_basic, :citation_small] & Taxonifi::Lumper.intersecting_lumps(csv.headers)).size > 0
    unused_fields = csv.headers - Taxonifi::Lumper::LUMPS[:names]

    # First pass, create and index names
    Taxonifi::Assessor::RowAssessor.rank_headers(csv.headers).each do |rank|
      # name_index.new_rank(rank)
      name_index[rank] = {}
      csv.each_with_index do |row, i|
        shares_rank = (rank == Taxonifi::Assessor::RowAssessor.lump_name_rank(row).to_s)
        name = row[rank] 

        if !name.nil?     # cell has data
          n = nil         # a Name if necessary
          name_id = nil   # index the new or existing Name 

          exists = false
          if name_index[rank][name] # A matching name (String) has been previously added
            name_index[rank][name].each do |id|
              # Compare vectors of parent_ids for name presence
              if nc.parent_id_vector(id) == row_index[i]      
                exists = true
                name_id = id
                break 
              end 
            end
          end # end name exists

          n = Taxonifi::Model::Name.new() if !exists

          unused_data = row.to_hash.select{|f| unused_fields.include?(f)}
          row_identifier = (row['identifier'] ? row['identifier'] : i)

          # Populate the new name if created.  Previously matched names are not effected. 
          if !n.nil? 
            n.rank = rank
            n.name = name
            n.parent = nc.object_by_id(row_index[i].last) if row_index[i].size > 0 # it's parent is the previous id in this row 
            n.row_number = i

            # Name/year needs to be standardized / cased out
            # headers are overlapping at times

            # Check to see if metadata (e.g. author year) apply to this rank, attach if so.
            if shares_rank 
              if row['author_year'] 
                builder = Taxonifi::Splitter::Builder.build_author_year(row['author_year'])                
                n.authors              = builder.people  # was author!?
                n.year                 = builder.year 
                n.parens               = builder.parens
              end

              n.add_property(:link_to_ref_from_row, i) if has_ref_fields # TODO: update this
              n.add_properties(unused_data) if opts[:capture_related_fields]
            end

            name_id = nc.add_object(n).id
            name_index[rank][name] ||= []
            name_index[rank][name].push name_id                

            $DEBUG && $stderr.puts("added #{nc.collection.size - 1} | #{n.name} | #{n.rank} | #{n.parent ? n.parent.name : '-'} | #{n.parent ? n.parent.id : '-'}")
          else
            $DEBUG && $stderr.puts("already present #{rank} | #{name}")
            if shares_rank 
              # original:: 
              nc.add_duplicate_entry_metadata(name_id, row_identifier, unused_data)

              # hack 
              # nc.add_duplicate_entry_metadata(name_id, row_identifier, row.to_hash) 
            
            end
          end

          # build a by row vector of parent child relationships
          row_index[i].push name_id                       
        end # end cell has data

      end
    end
    nc
  end 

  # Return a Taxonifi::Model::RefCollection from a CSV file.
  def self.create_ref_collection(options = {})
    opts = {
      :csv => nil,
      :inital_id => 1,
      :capture_related_fields => true   # Stores other column values in (column_header => value) pairs in Ref#related
    }.merge!(options)
    csv = opts[:csv]

    raise Taxonifi::Lumper::LumperError, 'Something that is not a CSV::Table was passed to Lumper.create_ref_collection.' if csv.class != CSV::Table
    rc = Taxonifi::Model::RefCollection.new(opts)

    unused_fields = csv.headers - (Taxonifi::Lumper::LUMPS[:citation_basic] | Taxonifi::Lumper::LUMPS[:citation_small])

    ref_index = {}
    csv.each_with_index do |row, i|
      if Taxonifi::Assessor::RowAssessor.intersecting_lumps_with_data(row, [:citation_small]).include?(:citation_small)
        r = Taxonifi::Model::Ref.new(
          :year => row['year'],
          :title => row['title'],
          :publication => row['publication']
        ) 

        # TODO: break out each of these lexes to a builder
        if row['authors'] && !row['authors'].empty?
          lexer = Taxonifi::Splitter::Lexer.new(row['authors'])
          authors = lexer.pop(Taxonifi::Splitter::Tokens::Authors)
          authors.names.each do |a|
            n = Taxonifi::Model::Person.new()
            n.last_name = a[:last_name]
            n.initials = a[:initials]
            r.authors.push n
          end
        end

        if row['volume_number'] && !row['volume_number'].empty?
          lexer = Taxonifi::Splitter::Lexer.new(row['volume_number'], :volume_number)
          t = lexer.pop(Taxonifi::Splitter::Tokens::VolumeNumber)
          r.volume = t.volume
          r.number = t.number
        end

        if row['pages'] && !row['pages'].empty?
          # If our regex doesn't match dump the field into pages
          lexer = Taxonifi::Splitter::Lexer.new(row['pages'], :pages)
          begin
          if t = lexer.pop(Taxonifi::Splitter::Tokens::Pages)
            r.pg_start = t.pg_start
            r.pg_end = t.pg_end
            r.pages = t.remainder
          else
            r.pages = row['pages']
          end
          rescue
            r.pages = row['pages']
          end
        end
       
        r.add_properties(row.to_hash.select{|f| unused_fields.include?(f)}) if opts[:capture_related_fields]

        # Do some indexing.
        ref_str = r.compact_string 
        if !ref_index.keys.include?(ref_str)
          ref_id = rc.add_object(r).id
          ref_index.merge!(ref_str => ref_id)
          # puts "#{i} : #{ref_id}"
          rc.row_index[i] = r 
        else
          rc.row_index[i] = rc.object_by_id(ref_index[ref_str])
          # puts "#{i} : #{ref_index[ref_str]}"
        end
      end
    end
    rc
  end

  # def self.link_name_and_ref_collections_by_row(nc, rc)
  # end

  # Creates a generic Collection with Objects of GenericObject
  # Objects are assigned to parents (rank) according to the order provided in headers.
  # Objects are considered the same if they have the same name and the same parents closure, e.g.
  #
  #   a b c
  #   a b d
  #   e b f
  #
  #   Will return 7 objects named in order a,b,c,d,e,b,f
  #
  # a,b b,c b,d e,b b,f are the unique parent/child relationships stored
  #
  #
  def self.create_hierarchical_collection(csv, headers)
    raise Taxonifi::Lumper::LumperError, 'Something that is not a CSV::Table was passed to Lumper.create_name_collection.' if csv.class != CSV::Table
    raise Taxonifi::Lumper::LumperError, 'No headers provided to create_hierarchical_collection.' if headers.size == 0

    c = Taxonifi::Model::Collection.new
    row_size = csv.size

    # See create_name_collection
    row_index = Taxonifi::Utils::Array.build_array_of_empty_arrays(row_size)
    name_index = Taxonifi::Utils::Hash.build_hash_of_hashes_with_keys(headers)

    csv.each_with_index do |row, i|
      headers.each do |rank|
        name = row[rank]
        if !name.nil? && !name.empty?  # cell has data
          o = nil                      # a Name if necessary
          name_id = nil                # index the new or existing name 

          if name_index[rank][name] # Matching name is found 

            exists = false
            name_index[rank][name].each do |id|
              if c.parent_id_vector(id) == row_index[i]
                exists = true
                name_id = id
                break
              end
            end

            if !exists
              o = Taxonifi::Model::GenericObject.new()
            end
          else
            o = Taxonifi::Model::GenericObject.new()
          end

          if !o.nil? 
            o.name = name
            o.rank = rank
            o.row_number = i
            o.parent = c.object_by_id(row_index[i].last) if row_index[i].size > 0 # it's parent is the previous id in this row 

            name_id = c.add_object(o).id 
            name_index[rank][name] ||= []
            name_index[rank][name].push name_id                
          end

          row_index[i].push name_id                       
        end
      end
    end
    c
  end

  # Return a geog collection from a csv file. 
  def self.create_geog_collection(csv)
    raise Taxonifi::Lumper::LumperError, 'Something that is not a CSV::Table was passed to Lumper.create_geog_collection.' if csv.class != CSV::Table
    gc = Taxonifi::Model::GeogCollection.new

    row_size = csv.size
    row_index = Taxonifi::Utils::Array.build_array_of_empty_arrays(row_size)

    name_index = {}
    geog_headers =  Taxonifi::Assessor::RowAssessor.geog_headers(csv.headers)
    geog_headers.each do |h|
      name_index[h] = {}
    end

    # We don't have the same problems as with taxon names, i.e.
    # boo in 
    #  Foo nil boo
    #  Foo bar boo
    # is the same thing wrt geography, not the case for taxon names.
    # We can use a row first loop to build as we go

    csv.each_with_index do |row, i|
      geog_headers.each do |level|
        name = row[level]
        if !name.nil? && !name.empty?  # cell has data
          g = nil         # a Name if necessary
          name_id = nil   # index the new or existing name 

          if name_index[level][name] # name exists
            name_id  = name_index[level][name] 
          else
            g = Taxonifi::Model::Geog.new()
            name_id = gc.add_object(g).id
          end

          if !g.nil? 
            g.name = name
            g.rank = level
            g.parent = gc.object_by_id(row_index[i].last) if row_index[i].size > 0 # it's parent is the previous id in this row 
          end

          name_index[level][name] = name_id
          row_index[i].push name_id                       
        end
      end
    end
    gc
  end 

end # end Lumper Module 


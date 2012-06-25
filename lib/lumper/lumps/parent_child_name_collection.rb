# Handles DwC-esque files (e.g. as dumped by EoL), i.e. a file with columns like: 
#   [identifier parent child rank synonyms] 
# Instantiates individual names for all names (including synonym lists) into a NameCollection.
# See 'test/test_lumper_parent_child_name_collection' for example use.
module Taxonifi::Lumper::Lumps::ParentChildNameCollection

  def self.name_collection(csv)
    raise Taxonifi::Lumper::LumperError, "CSV does not have the required headers (#{Taxonifi::Lumper::LUMPS[:eol_basic].join(", ")})." if  !Taxonifi::Lumper.available_lumps(csv.headers).include?(:eol_basic)

    nc = Taxonifi::Model::NameCollection.new(:initial_id => 1)

    # identifier => Taxonifi::Name
    external_index = {} 

    # Array of Hashes {:synonyms => "Name|Name1|Name2", :external_index => external_index[parent_id], :valid_species_id => valid_species_id}, {} ...
    synonym_list = [] 

    csv.each_with_index do |row,i|
      name = row['child']
      rank = row['rank'].downcase if !row['rank'].nil?
      parent_id = row['parent'].to_i
      external_id = row['identifier'].to_i
      valid_species_id = nil

      # Fix me
      index_rank = 'species_group' if rank == 'species' || rank == 'subspecies'
      index_rank = 'genus_group' if rank == 'subgenus' || rank == 'genus'
      index_rank ||= rank

      case rank
      when 'species', nil
       valid_species_id = add_species_names_from_string(nc, name, external_index[parent_id])
       external_index.merge!(external_id => nc.object_by_id(valid_species_id))
      else  # Just a single string, we don't have to break anything down.
        n = nil

        if nc.by_name_index[index_rank][name]
          exists = false
          # TODO: this hasn't been hit yet
          nc.by_name_index[index_rank][name].each do |id|
            if nc.parent_id_vector(id).pop == nc.parent_id_vector(parent_id)
              exists = true
              break
            end
          end
          if !exists
            n = Taxonifi::Model::Name.new()
          end 
        else 
          n = Taxonifi::Model::Name.new()
        end

        # Build the name
        if !n.nil?
          # TODO: No author, year have yet been observed for genus and higher names
          n.rank = rank
          n.name = name
          n.external_id = external_id
          n.row_number = i
    
          if parent = external_index[parent_id] 
            n.parent = parent
          end

          if !nc.name_exists?(n)
            nc.add_object(n)
            external_index.merge!(external_id => n) 
          end
        end
      end

      if !row['synonyms'].nil? && row['synonyms'].size > 0 
        #  puts n.name if external_index[parent_id].nil?
        synonym_list.push({:synonyms => row['synonyms'], :valid_species_id => valid_species_id, :external_index => external_index[parent_id]})
      end

    end # end row

    # parse the synonyms last, because names might have been mixed
    synonym_list.each do |s|
      other_names = s[:synonyms].split("|")
      other_names.each do |n|
        # puts ":: #{n} :: #{s[:external_index]} :: #{s[:valid_species_id]}" if s[:external_index].nil?
        add_species_names_from_string(nc, n, s[:external_index], s[:valid_species_id]) 
      end
    end

    nc 
  end

  # Add the last name in a species epithet string if new, record a new combination otherwise.  
  # Assumes ALL parents have been previously added, including those used in Synonym combinations.
  # For example, given a row with name, synonym fields like:
  #    'Neortholomus scolopax (Say, 1832)', 'Lygaeus scolopax Say, 1832']
  # The names Neortholomus and Lygaeus must exist.
  #
  def self.add_species_names_from_string(nc, string, parent = nil, synonym_id = nil)
    names = Taxonifi::Splitter::Builder.build_species_name(string) # A Taxonifi::Model::SpeciesName instance
    if !parent.nil?                                                # nc.object_by_id(parent_id)
      names.names.last.parent = parent                             # swap out the parent with the id referenced by the parent_id 
    else
      raise Taxonifi::Lumper::LumperError, "Parent of [#{names.names.last.name}] within [#{names.display_name}] not yet instantiated. \n !! To resolve: \n\t 1) If this is not a species name your file may be missing a value in the 'Rank' column (nil values are assumed to be species, all other ranks must be populated). \n\t 2) Parent names must be read before children, check that this is the case."
    end

    last_id = nil
    if !nc.name_exists?(names.names.last)
      last_id = nc.add_object(names.names.last).id
      nc.object_by_id(last_id).related_name = nc.object_by_id(synonym_id) if !synonym_id.nil?
    else

      tmp_genus = names.genus.clone
      tmp_subgenus = names.subgenus.clone if !names.subgenus.nil?
      tmp_species = names.species.clone
      tmp_subspecies = names.subspecies.clone if !names.subspecies.nil?

      case parent.rank
      when 'genus' 
        tmp_genus.parent = parent.parent # OK
      when 'subgenus'
        tmp_genus.parent = parent.parent # OK
      when 'species'
        tmp_genus.parent = parent.parent.parent
        tmp_species = parent
        tmp_subspecies.parent = tmp_species
      end
      
      # tmp_subgenus.parent = tmp_genus if !tmp_subgenus.nil?
      # real_subgenus = nc.object_by_id(nc.name_exists?(tmp_subgenus)) if !tmp_subgenus.nil? 

      real_genus = nc.object_by_id(nc.name_exists?(tmp_genus)) 
      real_species = nc.object_by_id(nc.name_exists?(tmp_species)) 

      # !! Existing demo data Lygaeoidea have synonyms in which the genus name is not instantiated.  This might be a problem with DwC file 
      # validation in general, something to look at, for now, throw up our hands and move on.
      return last_id if (real_genus.nil? || real_species.nil?)

      real_subgenus = nil # revisit
      real_subspecies = nc.object_by_id(nc.name_exists?(tmp_subspecies))  if !tmp_subspecies.nil?
    
      rc = [real_genus, real_subgenus, real_species, real_subspecies]
      nc.combinations.push rc
    end

    last_id
  end

end 

module Taxonifi::Lumper::Lumps::EolNameCollection

  def self.add_species_names_from_string(nc, string, parent_id)
    names = Taxonifi::Splitter::Builder.build_species_name(string)
    # Attempt to assign the genus to its parent.  
    if p = nc.object_by_id(parent_id)
      names.genus = p # swap out the genus to the id referenced # parent = p
    else
      raise Taxonifi::Lumper::LumperError, "Parent genus #{names.genus.name} for species name #{names.display_name} not yet instantiated, you may have resort your import."
    end

    nc.add_species_name(names)
    true
  end


  def self.name_collection(csv)
    raise Taxonifi::Lumper::LumperError, "CSV does not have the required headers (#{Taxonifi::Lumper::LUMPS[:eol_basic].join(", ")})." if  !Taxonifi::Lumper.available_lumps(csv.headers).include?(:eol_basic)

    nc = Taxonifi::Model::NameCollection.new
    external_index = {} # identifier => Taxonifi::Name

    csv.each_with_index do |row,i|
      name = row['child']
      rank = row['rank'].downcase
      parent_id = row['parent'].to_i
      external_id = row['identifier'].to_i

      case rank
      when 'species', nil
        add_species_names_from_string(nc, name, parent_id) 
      else  # Just a single string, we don't have to break anything down.
        n = nil

        if nc.by_name_index[rank][name]
          exists = false
          # TODO: this hasn't been hit yet
          nc.by_name_index[rank][name].each do |id|
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

          if parent = nc.object_by_id(parent_id) 
            n.parent = parent
          end

          nc.add_object(n)
          external_index.merge!(external_id => n) 
        end
      end # end case

      if !row['synonyms'].nil? && row['synonyms'].size > 0 
        other_names = row['synonyms'].split("|")
        other_names.each do |n|
          add_species_names_from_string(nc, n, parent_id) 
        end
      end

    end # end row
    nc 
  end

end 

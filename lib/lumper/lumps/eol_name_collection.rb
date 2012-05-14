module Taxonifi::Lumper::Lumps::EolNameCollection

  def self.name_collection(csv)
    raise Taxonifi::Lumper::LumperError, "CSV does not have the required headers (#{Taxonifi::Lumper::LUMPS[:eol_basic].join(", ")})." if  !Taxonifi::Lumper.available_lumps(csv.headers).include?(:eol_basic)

    nc = Taxonifi::Model::NameCollection.new
    external_index = {} # identifier => Taxonifi::Name

    csv.each_with_index do |row,i|
      name = row['child']
      rank = row['rank'].downcase
      parent_id = row['parent'].to_i

      case rank
      when 'species', nil
        names = Taxonifi::Splitter::Builder.build_species_name(name)
        # Attempt to assign the genus to its parent.  TODO: make this order independent
        if p = nc.object_by_id(parent_id)
          names.genus = p # swap out the genus to the id referenced # parent = p
        else
          raise Taxonifi::Lumper::LumperError, "Parent genus for species name not yet instantiated."
        end

        nc.add_species_name_unindexed(names)
      else  # Just a single string, we don't have to break anything down.
        n = nil
        if nc.by_name_index[rank][name]
          exists = false
          nc.name_index[rank][name].each do |id|
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

        if !n.nil?
          # TODO: No author, year have yet been observed for genus and higher names
          n.rank = rank
          if parent =  nc.object_by_id(parent_id) 
            n.parent = parent
          end

          n.name = name
          n.id = row['identifier'].to_i
          n.row_number = i

          nc.add_object_pre_indexed(n)
          external_index.merge!(row['identifier'].to_i => n) 
        end
      end
    end # end row
    nc 
  end

end 

module Taxonifi
  module Assessor 

    # Code to assess the metadata properties of a csv row.
    #
    # !! Note that there are various
    # !! CSV methods for returning row columns
    # !! that have particular attributes
    module RowAssessor

      class RowAssessorError < StandardError; end

      # Pass a CSV (require "csv") row as read with the following 
      # parameters: 
      #   headers: true
      #   header_converters: :symbol
      class RowAssessor < Taxonifi::Assessor::Base
        attr_reader :lumps # the lumps present in this row
        def initialze(csv_row)
          cols = []
          cols = csv_row.entries.select{|c,v| !v.nil?}.collect{|c| c[0]}
          @lumps = Taxonifi::Lumper.available_lumps(cols)
        end
      end

      # Return the first column with data, scoped by lump if provided. 
      def self.first_available(csv_row, lump = nil)
        if lump.nil?
          csv_row.entries.each do |c,v| 
            return [c,v] if !csv_row[c].nil?
          end
        else
          lump.each do |l|
            return [l, csv_row[l.to_s]] if !csv_row[l.to_s].nil?
          end
        end
      end
      
      # Return an Array of ["header", value] for the last column with data, scoped by lump if provided.
      # If there is nothing available in the scope provided return [nil, nil] 
      def self.last_available(csv_row, lump = nil)
        if lump.nil?
          csv_row.entries.reverse.each do |c,v| 
            return [c,v] if !csv_row[c].nil?
          end
        else
          lump.reverse.each do |l|
            return [l, csv_row[l.to_s]] if !csv_row[l.to_s].nil?
          end
        end
        [nil, nil]
      end

      # Return the rank (symbol) of the taxon name rank.  Raises
      # if no name detected.
      def self.lump_name_rank(csv_row)
        # Rather than just check individual columns for data ensure a complete lump is present      
        lumps = intersecting_lumps_with_data(csv_row, [:species, :genera, :higher])
        if lumps.include?(:species) # has to be a species name
          if !csv_row['variety'].nil?
            return :variety
          else
            if csv_row['subspecies'].nil?
              return :species
            else
              return :subspecies
            end
          end
        elsif lumps.include?(:genera)
          if csv_row['subgenus'].nil?
            return :genus
          else
            return :subgenus
          end
        elsif lumps.include?(:higher)
          return Taxonifi::Assessor::RowAssessor.last_available(csv_row, Taxonifi::Lumper::LUMPS[:higher]).first.to_sym
        end

        # this far? bad
        # raise RowAssessor::RowAssessorError

        raise RowAssessorError
      end

      # Return the column representing the parent of the name
      # represented in this row.
      # TODO: DEPRECATE, same f(n) as last_available when scoped properly
      # def self.parent_taxon_column(csv_row)
      #   last = last_available(csv_row, Taxonifi::RANKS)
      #   last_available(csv_row, Taxonifi::RANKS[0..Taxonifi::RANKS.index(last[0])-1])
      # end

      # Return an Array of headers that represent taxonomic ranks.
      def self.rank_headers(headers)
        Taxonifi::RANKS & headers
      end

      # Return an Array of headers that represent geographic columns.
      def self.geog_headers(headers)
        Taxonifi::Lumper::LUMPS[:basic_geog] & headers
      end

      # Return lumps for which at least one column has data.
      def self.intersecting_lumps_with_data(csv_row, lumps_to_try = nil)
        lumps_to_try ||= Taxonifi::Lumper.intersecting_lumps(csv_row.headers) 
        lumps = [] 
        lumps_to_try.each do |l|  
          has_data = false 
          Taxonifi::Lumper::LUMPS[l].each do |c|
            if !csv_row[c].nil? && !csv_row[c].empty?
              has_data = true 
              break
            end
          end
          has_data && lumps.push(l) 
        end
        lumps
      end

      # Return lumps that have data for all columns.
      def self.lumps_with_data(csv_row, lumps_to_try = nil)
        lumps_to_try ||= Taxonifi::Lumper.available_lumps(csv_row.headers) # Taxonifi::Lumper::LUMPS.keys 
        lumps = [] 
        lumps_to_try.each do |l|  
          has_data = true 
          Taxonifi::Lumper::LUMPS[l].each do |c|
            if csv_row[c].nil? || csv_row[c].empty?
              has_data = false 
              break
            end
          end
          has_data && lumps.push(l) 
        end
        lumps
      end

    end
  end 
end 


# The assessor assesses!

module Taxonifi
  module Assessor 

    module RowAssessor

      # Pass a CSV (require "csv") row as read with the following 
      # parameters: 
      #   headers: true
      #   header_converters: :symbol

      class RowAssessorError < StandardError; end

      class RowAssessor

        # !! Note that there are various
        # !! CSV methods for returning row columns
        # !! that have particular attributes

        attr_reader :lumps # the lumps present in this row

        def initialze(csv_row)
          cols = []
          cols = csv_row.entries.select{|c,v| !v.nil?}.collect{|c| c[0]}
          @lumps = Taxonifi::Lumper.available_lumps(cols)
        end
      end

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
      end

      def self.lump_rank(csv_row)
        lumps = Taxonifi::Lumper.available_lumps(csv_row.headers)        
        if lumps.include?(:species) # has to be a species name
          if csv_row[:subspecies].nil?
            return :species
          else
            return :subspecies
          end
        elsif lumps.include?(:genera)
          if csv_row[:subgenus].nil?
            return :genus
          else
            return :subgenus
          end
        else
          return Taxonifi::Assessor::RowAssessor.last_available(csv_row, Taxonifi::Lumper::LUMPS[:higher]).first.to_sym
        end

        # this far? bad
        raise RowAssessor::RowAssessorError
      end

      def self.parent_taxon_column(csv_row)
        lumps = Taxonifi::Lumper.available_lumps(csv_row.headers)
        last = last_available(csv_row, Taxonifi::RANKS)
        last_available(csv_row, Taxonifi::RANKS[0..Taxonifi::RANKS.index(last[0])-1])
      end

      def self.rank_headers(headers)
        Taxonifi::RANKS & headers
      end

      def self.intersecting_lumps_with_data(row, lumps_to_try = nil)
        lumps_to_try ||= Taxonifi::Lumper::LUMPS.keys 
        lumps = [] 
        lumps_to_try.each do |l|  
          has_data = false 
          Taxonifi::Lumper::LUMPS[l].each do |c|
            if !row[c].nil? && !row[c].empty?
              has_data = true 
              break
            end
          end
          has_data && lumps.push(l) 
        end
        lumps
      end

      def self.lumps_with_data(row, lumps_to_try = nil)
        lumps_to_try ||= Taxonifi::Lumper::LUMPS.keys 
        lumps = [] 
        lumps_to_try.each do |l|  
          has_data = true 
          Taxonifi::Lumper::LUMPS[l].each do |c|
            if row[c].nil? || row[c].empty?
              has_data = false 
              break
            end
          end
          has_data && lumps.push(l) 
        end
        lumps
      end

    end
  end # end Splitter module
end # Taxonifi module


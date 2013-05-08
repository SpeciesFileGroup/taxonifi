module Taxonifi::Export

  # All export classes inherit from Taxonifi::Export::Base
  class Base

    # Hash.  An index of taxonomic ranks.
    # See https://phenoscape.svn.sourceforge.net/svnroot/phenoscape/trunk/vocab/taxonomic_rank.obo
    # Site: https://www.phenoscape.org/wiki/Taxonomic_Rank_Vocabulary
    # Values of -1 have no correspondance in that ontology. 
    # Not all values are supported. Not all values are included.
    TAXRANKS = {
      'taxonomic_rank' =>          0,
      'variety'        =>          16,
      'bio-variety'    =>          32,
      'subspecies' =>              23,
      'form' =>                    26,
      'species' =>                 5,
      'species complex' =>         12,
      'species subgroup' =>        11,      
      'species group' =>           10,     
      'species series' =>          -1,      
      'series'  =>                 31,
      'infragenus' =>              43,  
      'subgenus' =>                9,
      'genus' =>                   5,
      'genus group' =>             -1,   
      'subtribe' =>                28,
      'tribe' =>                   25,
      'supertribe' =>              57,  
      'infrafamily' =>             41,   
      'subfamily' =>               24, 
      'subfamily group' =>         -1,       
      'family' =>                  4,
      'epifamily' =>               -1, 
      'superfamily' =>             18,  
      'superfamily group' =>       -1,         
      'subinfraordinal group' =>   -1,             
      'infraorder' =>              13,  
      'suborder' =>                14,
      'order' =>                   3,
      'mirorder' =>                -1,
      'superorder' =>              20,  
      'magnorder' =>               -1,
      'parvorder' =>               21, 
      'cohort' =>                  -1,
      'supercohort' =>             -1,   
      'infraclass' =>              19,  
      'subclass' =>                7,
      'class' =>                   2,
      'superclass' =>              15,  
      'infraphylum' =>             40,   
      'subphylum' =>               8, 
      'phylum' =>                  1,
      'superphylum' =>             27,   
      'infrakingdom' =>            44,   
      'subkingdom' =>              29,  
      'kingdom' =>                 17,
      'superkingdom' =>            22,    
      'life' =>                    -1,
      'unknown' =>                 -1,
      'section' =>                 30
    }

    EXPORT_BASE =  File.expand_path(File.join(Dir.home(), 'taxonifi', 'export')) 

    # String. Defaults to EXPORT_BASE. 
    attr_accessor :base_export_path

    # String. The folder to dump output files to, subclassess contain a reasonably named default.
    attr_accessor :export_folder

    def initialize(options = {})
      opts = {
        :base_export_path => EXPORT_BASE,
        :export_folder => '.'
      }.merge!(options)

      @base_export_path = opts[:base_export_path]  
      @export_folder = opts[:export_folder] 
    end

    # Return the path to which exported files will be written.
    def export_path
      File.expand_path(File.join(@base_export_path, @export_folder))
    end 
      
    # Subclassed models expand on this method, typically writing files
    # to the folders created here.
    def export
      configure_folders
    end

    # Recursively (over)write the the export path.
    def configure_folders
      FileUtils.mkdir_p export_path
    end

    # Write the string to a file in the export path.
    def write_file(filename = 'foo', string = nil)
      raise ExportError, 'Nothing to export for #{filename}.' if string.nil? || string == ""
      f = File.new( File.expand_path(File.join(export_path, filename)), 'w+')
      f.puts string
      f.close
    end

    # TODO: Used?!
    # Returns a new writeable File under the 
    def new_output_file(filename = 'foo')
      File.new( File.expand_path(File.join(export_path, filename)), 'w+')
    end


    # TODO: Move to a SQL library.
    # Returns a String, an INSERT statement derived from the passed values Hash.
    def sql_insert_statement(tbl = nil, values = {})
      return "nope" if tbl.nil?
      "INSERT INTO #{tbl} (#{values.keys.sort.join(",")}) VALUES (#{values.keys.sort.collect{|k| sqlize(values[k])}.join(",")});"
    end

    # TODO: Move to a SQL library.
    # Returns a String that has been SQL proofed based on its class.
    def sqlize(value)
      case value.class.to_s
      when 'String'
        "'#{sanitize(value)}'"
      else
        value
      end
    end

    # TODO: Move to SQL/String library.
    # Returns a String with quotes handled for SQL.
    def sanitize(value)
      value.to_s.gsub(/'/,"''")
    end

  end
end

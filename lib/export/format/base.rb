module Taxonifi::Export

  # All export classes inherit from Taxonifi::Export::Base
  class Base
    EXPORT_BASE =  File.expand_path(File.join(Dir.home(), 'taxonifi', 'export')) 
    attr_accessor :base_export_path, :export_folder

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

    def sql_insert_statement(tbl = nil, values = {})
      return "nope" if tbl.nil?
      "INSERT INTO #{tbl} (#{values.keys.sort.join(",")}) VALUES (#{values.keys.sort.collect{|k| sqlize(values[k])}.join(",")});"
    end

    def sqlize(value)
      case value.class.to_s
      when 'String'
        "'#{sanitize(value)}'"
      else
        value
      end
    end

    def sanitize(value)
      value.to_s.gsub(/'/,"''")
    end

  end
end

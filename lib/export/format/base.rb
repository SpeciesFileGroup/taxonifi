module Taxonifi::Export

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

    def export_path
      File.expand_path(File.join(@base_export_path, @export_folder))
    end 
      
    # Subclassed models expand on this method, typically writing files
    # to the folders created here.
    def export
      configure_folders
    end

    def configure_folders
      FileUtils.mkdir_p export_path
    end

    def write_file(filename = 'foo', string = nil)
      raise ExportError, 'Nothing to export for #{filename}.' if string.nil? || string == ""
      f = File.new( File.expand_path(File.join(export_path, filename)), 'w+')
      f.puts string
      f.close
    end

  end
end

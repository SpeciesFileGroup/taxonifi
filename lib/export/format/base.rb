module Taxonifi::Export

  class Base

    EXPORT_PATH = ''

    attr_accessor :export_path

    def initialize(options = {})
      opts = {
        :export_path => EXPORT_PATH
      }.merge!(options)

      @export_path = opts[:export_path]  
    end

    def export
      # TODO: some tmp file configuration here
    end

    def configure
    end

  end
end

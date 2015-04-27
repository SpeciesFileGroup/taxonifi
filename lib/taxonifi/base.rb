module Taxonifi
  class ModelError < StandardError; end
  module Model
    require File.expand_path(File.join(__dir__, 'model/shared_class_methods'))
  end
end

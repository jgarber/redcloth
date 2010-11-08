module Rake
  class RagelExtensionTask < ExtensionTask
    
    attr_accessor :source_files
    
    def init(name = nil, gem_spec = nil)
      super
    end
    
    
    def source_files
      @source_files ||= FileList["#{@ext_dir}/#{@source_pattern}"]
    end
  end
end
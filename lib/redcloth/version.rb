module RedCloth
  module VERSION
    MAJOR = 4
    MINOR = 2
    TINY  = 3
    RELEASE_CANDIDATE = nil

    STRING = [MAJOR, MINOR, TINY].join('.')
    TAG = "REL_#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('_')}".upcase.gsub(/\.|-/, '_')
    FULL_VERSION = "#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('.')}"
    
    class << self
      def to_s
        STRING
      end
      
      def ==(arg)
        STRING == arg
      end
    end
  end
  
  NAME = "RedCloth"
  GEM_NAME = NAME
  URL  = "http://redcloth.org/"
  description = "Textile parser for Ruby."

  if RedCloth.const_defined?(:EXTENSION_LANGUAGE)
    DESCRIPTION = "#{NAME}-#{VERSION::FULL_VERSION}-#{EXTENSION_LANGUAGE} - #{description}\n#{URL}"
  else
    DESCRIPTION = "#{NAME}-#{VERSION::FULL_VERSION} - #{description}\n#{URL}"
  end
end

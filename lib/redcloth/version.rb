module RedCloth
  module VERSION
    MAJOR = 4
    MINOR = 2
    TINY  = 4
    RELEASE_CANDIDATE = "pre3"

    STRING = [MAJOR, MINOR, TINY, RELEASE_CANDIDATE].join('.')
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
    SUMMARY = "#{NAME}-#{VERSION::FULL_VERSION}-#{EXTENSION_LANGUAGE}"
  else
    SUMMARY = "#{NAME}-#{VERSION::FULL_VERSION}"
  end
  DESCRIPTION = SUMMARY + " - #{description}\n#{URL}"
end

class RedCloth #:nodoc:
  module VERSION #:nodoc:
    MAJOR = 4
    MINOR = 0
    TINY  = 0
    RELEASE_CANDIDATE = 1

    STRING = [MAJOR, MINOR, TINY].join('.')
    TAG = "REL_#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('_')}".upcase.gsub(/\.|-/, '_')
    FULL_VERSION = "#{[MAJOR, MINOR, TINY, RELEASE_CANDIDATE].compact.join('.')}"
  end
  
  NAME = "RedCloth"
  GEM_NAME = NAME
  URL  = "http://redcloth.org/"

  DESCRIPTION = "#{NAME}-#{VERSION::FULL_VERSION} - Textile parser for Ruby.\n#{URL}"
end
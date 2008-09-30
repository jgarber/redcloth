module RedCloth
  module ERB
    module Util
      def included(base)
        base.send :alias_method, :r, :redcloth_escape
        base.send :module_function, :r # this voodoo makes the method available to instances of ERB as a private method
        base.send :module_function, :redcloth_escape # ditto for the textile method
      end
      
      def redcloth_escape( s )
        if s && s.respond_to?(:to_s) && s = s.to_s
          RedCloth.new( s ).to_html
        end
      end


    end
  end
end
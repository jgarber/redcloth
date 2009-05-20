require "spec/runner/differs/load-diff-lcs"
require 'pp'

module RedClothDiffers
  unless defined?(Inline)
    class Inline
      def initialize(options)
        @options = options
      end
      
      DIFF_ASCII_COLORS = {
        "=" => "\e[0m",
        "+" => "\e[42m",
        "-" => "\e[41m",
        "!" => "\e[43m"
      }

      def diff_as_string(data_new, data_old)
        output = "\e[0m"
        last_action = nil
        sdiff = Diff::LCS.sdiff(data_old, data_new)
        sdiff.each do |change|
          unless change.action == last_action
            output << DIFF_ASCII_COLORS[change.action]
            last_action = change.action
          end
          output << case change.action
          when "+"
            change.new_element
          when "-"
            change.old_element
          when "="
            change.old_element
          when "!"
            change.old_element
          end
        end
        
        output
      end  

      def diff_as_object(target,expected)
        diff_as_string(PP.pp(target,""), PP.pp(expected,""))
      end
    end

  end
end

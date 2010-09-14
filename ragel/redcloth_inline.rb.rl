# 
# redcloth_inline.rb.rl
# 
# Copyright (C) 2009 Jason Garber
# 

%%{

  machine redcloth_inline;
  include redcloth_common "redcloth_common.rb.rl";
  include redcloth_inline "redcloth_inline.rl";

}%%
module RedCloth
  class RedclothInline < BaseScanner
    def self.redcloth_inline2(textile_doc, data, refs)
      self.new.redcloth_inline(textile_doc, data, refs)
    end
    
    def red_parse_attr(regs, ref)
      txt = regs[ref.to_sym]
      new_regs = redcloth_attributes(txt)
      return regs.merge!(new_regs)
    end

    def red_parse_link_attr(regs, ref)
      txt = regs[ref.to_sym]
      new_regs = red_parse_title(redcloth_link_attributes(txt), ref)
      return regs.merge!(new_regs)
    end

    def red_parse_image_attr(regs, ref)
      return red_parse_title(regs, ref);
    end

    def red_parse_title(regs, ref)
      # Store title/alt
      name = regs[ref.to_sym]
      if ( !name.nil? )
        s = name.to_s
        p = s.length
        if (s[p - 1,1] == ')')
          level = -1
          p -= 1
          while (p > 0 && level < 0) do
            case s[p - 1, 1]
              when '('; level += 1
              when ')'; level -= 1
            end
            p -= 1
          end
          title = s[p + 1, (s.length - 1) - (p + 1)]
          p -= 1 if (p > 0 && s[p - 1, 1] == ' ')
          if (p != 0)
            regs[ref.to_sym] = s[0, p]
            regs[:title] = title
          end
        end
      end
      return regs;
    end

    def red_pass_code(regs, ref, meth)
      txt = regs[ref.to_sym]
      if (!txt.nil?)
        txt2 = ""
        rb_str_cat_escaped_for_preformatted(txt2, txt)
        regs[ref.to_sym] = txt2
      end
      return @textile_doc.send(meth, regs)
    end

    def redcloth_inline(textile_doc, data, refs)
      @textile_doc = textile_doc
      @data = data + "\0"
      @refs = refs
      @p = 0
      @pe = @data.length
      @orig_data = @data.dup
      CLEAR_REGS()
      @block = ""
    
      %% write init;
      %% write exec;
      ##%

      return block
    end
  
    def redcloth_attributes(str)
      return RedCloth::RedclothAttributes.redcloth_attributes(str)
    end
    def redcloth_link_attributes(str)
      return RedCloth::RedclothAttributes.redcloth_link_attributes(str)
    end
    
    def initialize
      %%{
        variable data  @data;
        variable p     @p;
        variable pe    @pe;
        variable cs    @cs;
        variable ts    @ts;
        variable te    @te;

        write data nofinal;
      }%%
    end
  end
end
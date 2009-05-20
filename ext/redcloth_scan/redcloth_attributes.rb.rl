# 
# redcloth_attributes.rb.rl
# 
# Copyright (C) 2009 Jason Garber
# 

%%{

  machine redcloth_attributes;
  include redcloth_common "redcloth_common.rb.rl";
  include redcloth_attributes "redcloth_attributes.rl";

}%%

module RedCloth
  class RedclothAttributes < BaseScanner
    def self.redcloth_attributes(str)
      self.new.redcloth_attributes(str)
    end

    def self.redcloth_link_attributes(str)
      self.new.redcloth_link_attributes(str)
    end
    
    def redcloth_attribute_parser(cs, data)
      @data = data + "\0"
      @regs = {}
      @attr_regs = {}
      @p = 0
      @pe = @data.length

      %% write init; #%

      @cs = cs

      %% write exec; #%

      return @regs
    end

    def redcloth_attributes(str)
      self.cs = self.redcloth_attributes_en_inline
      return redcloth_attribute_parser(cs, str)
    end

    def redcloth_link_attributes(str)
      self.cs = self.redcloth_attributes_en_link_says;
      return redcloth_attribute_parser(cs, str)
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
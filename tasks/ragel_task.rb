require 'yaml'
require 'erb'

class RagelTask
  RL_OUTPUT_DIR = File.dirname(__FILE__) + "/../ragel"
  EXT_DIR = File.dirname(__FILE__) + "/../ext/redcloth_scan"

  def initialize(lang)
    @lang     = lang
    define_tasks
  end

  def define_tasks
    %w(scan inline attributes).each do |machine|
      file target(machine) => [*ragel_dependencies(machine)] do
        mkdir_p(File.dirname(target)) unless File.directory?(File.dirname(target))
        ensure_ragel_version(target) do
          sh "ragel #{flags} #{lang_ragel} -o #{target(machine)}"
        end
      end
    end
  end

  def target(machine)
    {
      'scan' => {
        'c'    => "#{EXT_DIR}/redcloth_scan.c",
        'java' => "#{EXT_DIR}/RedclothScanService.java",
        'rb'   => "#{EXT_DIR}/redcloth_scan.rb"
      },
      'inline' => {
        'c'    => "#{EXT_DIR}/redcloth_inline.c",
        'java' => "#{EXT_DIR}/RedclothInline.java",
        'rb'   => "#{EXT_DIR}/redcloth_inline.rb"
      },
      'attributes' => {
        'c'    => "#{EXT_DIR}/redcloth_attributes.c",
        'java' => "#{EXT_DIR}/RedclothAttributes.java",
        'rb'   => "#{EXT_DIR}/redcloth_attributes.rb"
      }
    }[machine][@lang]
  end
  
  def lang_ragel(machine)
    "#{RL_OUTPUT_DIR}/redcloth_#{machine}.#{@lang}.rl"
  end
  
  def ragel_dependencies(machine)
    [lang_ragel(machine),   "#{RL_OUTPUT_DIR}/redcloth_#{machine}.rl", "#{RL_OUTPUT_DIR}/redcloth_common.#{@lang}.rl",   "#{RL_OUTPUT_DIR}/redcloth_common.rl"] + (@lang == 'c' ? ["#{EXT_DIR}/redcloth.h"] : [])
    # FIXME: merge that header file into other places so it can be eliminated?
  end

  def flags
    # FIXME: reinstate @code_style being passed from optimize rake task?
    code_style_flag = preferred_code_style ? " -" + preferred_code_style : ""
    "-#{host_language}#{code_style_flag}"
  end
  
  def host_language
    {
      'c'      => '-C',
      'java'   => '-J',
      'rb'     => '-R'
    }[@lang]
  end
  
  def preferred_code_style
    {
      'c'      => 'T0',
      'java'   => nil,
      'rb'     => 'F1'
    }[@lang]
  end
  
  def ensure_ragel_version(name)
    @ragel_v ||= `ragel -v`[/(version )(\S*)/,2].split('.').map{|s| s.to_i}
    if @ragel_v[0] > 6 || (@ragel_v[0] == 6 && @ragel_v[1] >= 3)
      yield
    else
      STDERR.puts "Ragel 6.3 or greater is required to generate #{name}."
      exit(1)
    end
  end
end

require 'lib/redcloth/version'

begin
  require 'rubygems'
  gem 'echoe', '>=2.7.11'
  require 'echoe'
rescue LoadError
  abort "You'll need to have `echoe' installed to use RedCloth's Rakefile"
end

e = Echoe.new('RedCloth', RedCloth::VERSION.to_s) do |p|
  p.summary = RedCloth::DESCRIPTION
  p.author = "Jason Garber"
  p.email = 'redcloth-upwards@rubyforge.org'
  p.clean_pattern += ['ext/redcloth_scan/**/*.{bundle,so,obj,pdb,lib,def,exp,c,o,xml,class,jar,java}', 'lib/*.{bundle,so,o,obj,pdb,lib,def,exp,jar}', 'ext/redcloth_scan/Makefile']
  p.url = "http://redcloth.org"
  p.project = "redcloth"
  p.rdoc_pattern = ['README', 'COPING', 'CHANGELOG', 'lib/**/*.rb', 'doc/**/*.rdoc']
  p.ignore_pattern = /^(pkg|site|projects|doc|log)|CVS|\.log/
  p.ruby_version = '>=1.8.4'
  p.extension_pattern = nil
  
  
  if RUBY_PLATFORM =~ /mingw|mswin|java/
    p.need_tar_gz = false
  else
    p.need_zip = true
    p.need_tar_gz = true
    p.extension_pattern = ["ext/**/extconf.rb"]
  end

  p.eval = proc do
    case RUBY_PLATFORM
    when /mingw/
      self.files += ['lib/redcloth_scan.so']
      self.platform = 'x86-mswin32-60'
    when /java/
      self.files += ['lib/redcloth_scan.jar']
      self.platform = 'jruby'
    else
      self.files += %w[attributes inline scan].map {|f| "ext/redcloth_scan/redcloth_#{f}.c"}
    end
  end

end

#### Pre-compiled extensions for alternative platforms

def move_extensions
  Dir["ext/**/*.{bundle,so,jar}"].each { |file| mv file, "lib/" }
end

def java_classpath_arg
  # A myriad of ways to discover the JRuby classpath
  classpath = begin
    require 'java'
    # Already running in a JRuby JVM
    Java::java.lang.System.getProperty('java.class.path')
  rescue LoadError
    ENV['JRUBY_PARENT_CLASSPATH'] || ENV['JRUBY_HOME'] && FileList["#{ENV['JRUBY_HOME']}/lib/*.jar"].join(File::PATH_SEPARATOR)
  end
  classpath ? "-cp #{classpath}" : ""
end

ext = "ext/redcloth_scan"

case RUBY_PLATFORM
when /mingw/
  
  filename = "lib/redcloth_scan.so"
  file filename => FileList["#{ext}/redcloth_scan.c", "#{ext}/redcloth_inline.c", "#{ext}/redcloth_attributes.c"] do
    cp "ext/mingw-rbconfig.rb", "#{ext}/rbconfig.rb"
    Dir.chdir("ext/redcloth_scan") do
      ruby "-I. extconf.rb"
      system(PLATFORM =~ /mswin/ ? 'nmake' : 'make')
    end
    move_extensions
    rm "#{ext}/rbconfig.rb"
  end

when /java/

  filename = "lib/redcloth_scan.jar"
  file filename => FileList["#{ext}/RedclothScanService.java", "#{ext}/RedclothInline.java", "#{ext}/RedclothAttributes.java"] do
    sources = FileList["#{ext}/**/*.java"].join(' ')
    sh "javac -target 1.5 -source 1.5 -d #{ext} #{java_classpath_arg} #{sources}"
    sh "jar cf lib/redcloth_scan.jar -C #{ext} ."
    move_extensions
  end
  
else
  filename = "#{ext}/redcloth_scan.#{Config::CONFIG['DLEXT']}"
  file filename => FileList["#{ext}/redcloth_scan.c", "#{ext}/redcloth_inline.c", "#{ext}/redcloth_attributes.c"]
end

task :compile => [filename]

# C Ragel file dependencies
c_header = "#{ext}/redcloth.h"
c_redcloth_common = "#{ext}/redcloth_common.rl"
file c_redcloth_common # => "#{ext}/redcloth_common.rl"
file "#{ext}/redcloth_scan.c.rl" => ["#{ext}/redcloth_scan.rl", c_redcloth_common, c_header]
file "#{ext}/redcloth_inline.c.rl" => ["#{ext}/redcloth_inline.rl", c_redcloth_common, c_header]
file "#{ext}/redcloth_attributes.c.rl" => ["#{ext}/redcloth_attributes.rl", c_redcloth_common, c_header]

# Java Ragel file dependencies
java_redcloth_common = "#{ext}/redcloth_common.java.rl"
file java_redcloth_common # => "#{ext}/redcloth_common.rl"
file "#{ext}/redcloth_scan.java.rl" => ["#{ext}/redcloth_scan.rl", java_redcloth_common]
file "#{ext}/redcloth_inline.java.rl" => ["#{ext}/redcloth_inline.rl", java_redcloth_common]
file "#{ext}/redcloth_attributes.java.rl" => ["#{ext}/redcloth_attributes.rl", java_redcloth_common]

GENERATED_SOURCE_FILES = {
  "redcloth_scan.c" => "redcloth_scan.c.rl",
  "redcloth_inline.c" => "redcloth_inline.c.rl",
  "redcloth_attributes.c" => "redcloth_attributes.c.rl",
  "RedclothScanService.java" => "redcloth_scan.java.rl",
  "RedclothInline.java" => "redcloth_inline.java.rl",
  "RedclothAttributes.java" => "redcloth_attributes.java.rl"
}

GENERATED_SOURCE_FILES.each do |target_name, source_name|
  target_name = File.join(ext,target_name)
  source_name = File.join(ext,source_name)
  host_language = (target_name =~ /java$/) ? "J" : "C"
  code_style = (host_language == "C") ? " -" + (@code_style || "T0") : ""
  file target_name => source_name do
    ensure_ragel_version(target_name) do
      sh %{ragel #{source_name} -#{host_language}#{code_style} -o #{target_name}}
    end
  end
end

# Make sure the .c files exist if you try the Makefile, otherwise Ragel will have to generate them.
file "#{ext}/Makefile" => ["#{ext}/extconf.rb", "#{ext}/redcloth_scan.c","#{ext}/redcloth_inline.c","#{ext}/redcloth_attributes.c","#{ext}/redcloth_scan.o","#{ext}/redcloth_inline.o","#{ext}/redcloth_attributes.o"]


#### Optimization

RAGEL_CODE_GENERATION_STYLES = {
  'T0' => "Table driven FSM (default)",
  'T1' => "Faster table driven FSM",
  'F0' => "Flat table driven FSM",
  'F1' => "Faster flat table-driven FSM",
  'G0' => "Goto-driven FSM",
  'G1' => "Faster goto-driven FSM",
  'G2' => "Really fast goto-driven FSM"
}

desc "Find the fastest code generation style for Ragel"
task :optimize do
  require 'extras/ragel_profiler'
  results = []
  RAGEL_CODE_GENERATION_STYLES.each do |style, name|
    @code_style = style
    profiler = RagelProfiler.new(style + " " + name)
    
    # Hack to get everything to invoke again.  Could use #execute, but then it 
    # doesn't execute prerequisites the second+ time
    Rake::Task.tasks.each {|t| t.instance_eval "@already_invoked = false" }
    
    Rake::Task['clobber'].invoke
    
    profiler.measure(:compile) do
      Rake::Task['compile'].invoke
    end
    profiler.measure(:test) do
      Rake::Task['test'].invoke
    end
    profiler.ext_size(ext_so)
    
  end
  puts RagelProfiler.results
end


#### Custom testing tasks

task :test => [:compile]

# Run specific tests or test files
# 
# rake test:parser
# => Runs the full TestParser unit test
# 
# rake test:parser:textism
# => Runs the tests matching /textism/ in the TestParser unit test
rule "" do |t|
  # test:file:method
  if /test:(.*)(:([^.]+))?$/.match(t.name)
    arguments = t.name.split(":")[1..-1]
    file_name = arguments.first
    test_name = arguments[1..-1] 
    
    if File.exist?("test/test_#{file_name}.rb")
      run_file_name = "test_#{file_name}.rb"
    end
    
    sh "ruby -Ilib:test test/#{run_file_name} -n /#{test_name}/" 
  end
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

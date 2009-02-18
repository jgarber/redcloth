require 'lib/redcloth/version'
require 'rubygems'
gem 'echoe', '>= 3.0.1'
require 'echoe'

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
  p.development_dependencies = [] # remove echoe from development dependencies
  
  if Platform.gcc?
    p.platform = 'x86-mswin32-60'
  elsif Platform.java?
    p.platform = 'universal-java'
  end
  
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
    when /java/
      self.files += ['lib/redcloth_scan.jar']
    else
      self.files += %w[attributes inline scan].map {|f| "ext/redcloth_scan/redcloth_#{f}.c"}
    end
    
    self.require_paths << "lib/case_sensitive_require"
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

def ragel(target_file, source_file)
  host_language = (target_file =~ /java$/) ? "J" : "C"
  code_style = (host_language == "C") ? " -" + (@code_style || "T0") : ""
  ensure_ragel_version(target_file) do
    sh %{ragel #{source_file} -#{host_language}#{code_style} -o #{target_file}}
  end
end

# Make sure the .c files exist if you try the Makefile, otherwise Ragel will have to generate them.
file "#{ext}/Makefile" => ["#{ext}/extconf.rb", "#{ext}/redcloth_scan.c","#{ext}/redcloth_inline.c","#{ext}/redcloth_attributes.c","#{ext}/redcloth_scan.o","#{ext}/redcloth_inline.o","#{ext}/redcloth_attributes.o"]

# Ragel-generated C files
file "#{ext}/redcloth_scan.c" =>  ["#{ext}/redcloth_scan.c.rl",   "#{ext}/redcloth_scan.rl", "#{ext}/redcloth_common.c.rl",   "#{ext}/redcloth_common.rl",  "#{ext}/redcloth.h"] do
  ragel "#{ext}/redcloth_scan.c", "#{ext}/redcloth_scan.c.rl"
end
file "#{ext}/redcloth_inline.c" =>  ["#{ext}/redcloth_inline.c.rl",   "#{ext}/redcloth_inline.rl", "#{ext}/redcloth_common.c.rl",   "#{ext}/redcloth_common.rl",  "#{ext}/redcloth.h"] do
  ragel "#{ext}/redcloth_inline.c", "#{ext}/redcloth_inline.c.rl"
end
file "#{ext}/redcloth_attributes.c" =>  ["#{ext}/redcloth_attributes.c.rl",   "#{ext}/redcloth_attributes.rl", "#{ext}/redcloth_common.c.rl",   "#{ext}/redcloth_common.rl",  "#{ext}/redcloth.h"] do
  ragel "#{ext}/redcloth_attributes.c", "#{ext}/redcloth_attributes.c.rl"
end

# Ragel-generated Java files
file "#{ext}/RedclothScanService.java" =>  ["#{ext}/redcloth_scan.java.rl",   "#{ext}/redcloth_scan.rl", "#{ext}/redcloth_common.java.rl",   "#{ext}/redcloth_common.rl"] do
  ragel "#{ext}/RedclothScanService.java", "#{ext}/redcloth_scan.java.rl"
end
file "#{ext}/RedclothInline.java" =>  ["#{ext}/redcloth_inline.java.rl",   "#{ext}/redcloth_inline.rl", "#{ext}/redcloth_common.java.rl",   "#{ext}/redcloth_common.rl", "#{ext}/redcloth_scan.java.rl"] do
  ragel "#{ext}/RedclothInline.java", "#{ext}/redcloth_inline.java.rl"
end
file "#{ext}/RedclothAttributes.java" =>  ["#{ext}/redcloth_attributes.java.rl",   "#{ext}/redcloth_attributes.rl", "#{ext}/redcloth_common.java.rl",   "#{ext}/redcloth_common.rl", "#{ext}/redcloth_scan.java.rl"] do
  ragel "#{ext}/RedclothAttributes.java", "#{ext}/redcloth_attributes.java.rl"
end


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

require 'lib/redcloth/version'
require 'rubygems'
gem 'echoe', '>= 4.1'
require 'echoe'
Dir["#{File.dirname(__FILE__)}/lib/tasks/*.rake"].sort.each { |ext| load(ext) }

e = Echoe.new('RedCloth', RedCloth::VERSION.to_s) do |p|
  p.summary = RedCloth::DESCRIPTION
  p.author = "Jason Garber"
  p.email = 'redcloth-upwards@rubyforge.org'
  p.clean_pattern += ['ext/redcloth_scan/**/*.{bundle,so,obj,pdb,lib,def,exp,c,o,xml,class,jar,java}', 'lib/*.{bundle,so,o,obj,pdb,lib,def,exp,jar}', 'ext/redcloth_scan/**/redcloth_*.rb', 'lib/redcloth_scan.rb', 'ext/redcloth_scan/Makefile']
  p.url = "http://redcloth.org"
  p.project = "redcloth"
  p.rdoc_pattern = ['README', 'COPING', 'CHANGELOG', 'lib/**/*.rb', 'doc/**/*.rdoc']
  p.ignore_pattern = /^(pkg|site|projects|doc|log)|CVS|\.log/
  p.ruby_version = '>=1.8.4'
  p.extension_pattern = nil
  p.development_dependencies = [] # remove echoe from development dependencies
  
  if Echoe::Platform.gcc?
    p.platform = 'x86-mswin32-60'
  elsif Echoe::Platform.java?
    p.platform = 'universal-java'
  elsif RUBY_PLATFORM == 'pureruby'
    p.platform = 'ruby'
  end
  
  if RUBY_PLATFORM =~ /mingw|mswin|java/
    p.need_tar_gz = false
  elsif RUBY_PLATFORM == 'pureruby'
    p.need_gem = false
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
    when 'pureruby'
      self.files += ['lib/redcloth_scan.rb']
    else
      self.files += %w[attributes inline scan].map {|f| "ext/redcloth_scan/redcloth_#{f}.c"}
    end
    
    self.require_paths << "lib/case_sensitive_require"
  end

end

def move_extensions
  Dir["ext/**/*.{bundle,so,jar}"].each { |file| mv file, "lib/" }
end

def java_classpath_arg # myriad of ways to discover JRuby classpath
  begin
    cpath  = Java::java.lang.System.getProperty('java.class.path').split(File::PATH_SEPARATOR)
    cpath += Java::java.lang.System.getProperty('sun.boot.class.path').split(File::PATH_SEPARATOR)
    jruby_cpath = cpath.compact.join(File::PATH_SEPARATOR)
  rescue => e
  end
  unless jruby_cpath
    jruby_cpath = ENV['JRUBY_PARENT_CLASSPATH'] || ENV['JRUBY_HOME'] &&
      FileList["#{ENV['JRUBY_HOME']}/lib/*.jar"].join(File::PATH_SEPARATOR)
  end
  jruby_cpath ? "-cp \"#{jruby_cpath}\"" : ""
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
  
when /pureruby/
  filename = "lib/redcloth_scan.rb"
  file filename => FileList["#{ext}/redcloth_scan.rb", "#{ext}/redcloth_inline.rb", "#{ext}/redcloth_attributes.rb"] do |task|
    
    sources = task.prerequisites.join(' ')
    sh "cat #{sources} > #{filename}"
  end
  
else
  filename = "#{ext}/redcloth_scan.#{Config::CONFIG['DLEXT']}"
  file filename => FileList["#{ext}/redcloth_scan.c", "#{ext}/redcloth_inline.c", "#{ext}/redcloth_attributes.c"]
end

task :compile => [:remove_other_platforms, filename]

def ragel(target_file, source_file)
  host_language = case target_file
  when /java$/
    "J"
  when /rb$/
    "R"
  else
    "C"
  end
  preferred_code_style = case host_language
  when "R"
    "F1"
  when "C"
    "T0"
  else
    nil
  end
  code_style = preferred_code_style ? " -" + (@code_style || preferred_code_style) : ""
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

# Ragel-generated pureruby files
file "#{ext}/redcloth_scan.rb" =>  ["#{ext}/redcloth_scan.rb.rl",   "#{ext}/redcloth_scan.rl", "#{ext}/redcloth_common.rb.rl",   "#{ext}/redcloth_common.rl"] do
  ragel "#{ext}/redcloth_scan.rb", "#{ext}/redcloth_scan.rb.rl"
end
file "#{ext}/redcloth_inline.rb" =>  ["#{ext}/redcloth_inline.rb.rl",   "#{ext}/redcloth_inline.rl", "#{ext}/redcloth_common.rb.rl",   "#{ext}/redcloth_common.rl"] do
  ragel "#{ext}/redcloth_inline.rb", "#{ext}/redcloth_inline.rb.rl"
end
file "#{ext}/redcloth_attributes.rb" =>  ["#{ext}/redcloth_attributes.rb.rl",   "#{ext}/redcloth_attributes.rl", "#{ext}/redcloth_common.rb.rl",   "#{ext}/redcloth_common.rl"] do
  ragel "#{ext}/redcloth_attributes.rb", "#{ext}/redcloth_attributes.rb.rl"
end


#### Optimization

# C/Ruby code styles
RAGEL_CODE_GENERATION_STYLES = {
  'T0' => "Table driven FSM (default)",
  'T1' => "Faster table driven FSM",
  'F0' => "Flat table driven FSM",
  'F1' => "Faster flat table-driven FSM"
}
# C only code styles
RAGEL_CODE_GENERATION_STYLES.merge!({
  'G0' => "Goto-driven FSM",
  'G1' => "Faster goto-driven FSM",
  'G2' => "Really fast goto-driven FSM"
}) if RUBY_PLATFORM !~ /pureruby/

desc "Find the fastest code generation style for Ragel"
task :optimize do
  require 'test/ragel_profiler'
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
    profiler.ext_size(filename)
    
  end
  puts RagelProfiler.results
end


#### Custom testing tasks

require 'rubygems' 
require 'spec/rake/spectask'
Rake::Task[:default].prerequisites.clear
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ["--options #{File.dirname(__FILE__) + '/spec/spec.opts'}"] 
  t.spec_files = FileList['spec/**/*_spec.rb'] 
end 

task :default => :spec
task :spec => [:ensure_diff_lcs, :compile]

task :ensure_diff_lcs do
  # A little insurance against rake on JRuby not passing the error from load-diff-lcs.rb
  begin
    require 'diff/lcs'
  rescue LoadError
    begin
      require 'rubygems' unless ENV['NO_RUBYGEMS']
      require 'diff/lcs'
    rescue LoadError
      raise "You must gem install diff-lcs to run the specs."
    end
  end
end

task :remove_other_platforms do
  Dir["lib/redcloth_scan.{bundle,so,jar,rb}"].each { |file| rm file }
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

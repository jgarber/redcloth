require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'fileutils'
include FileUtils
require 'lib/redcloth/version'

NAME = RedCloth::NAME
SUMMARY = RedCloth::DESCRIPTION
VERS = RedCloth::VERSION::STRING
CLEAN.include ['ext/redcloth_scan/*.{bundle,so,obj,pdb,lib,def,exp,c,o,xml}', 'ext/redcloth_scan/Makefile', '**/.*.sw?', '*.gem', '.config']
CLOBBER.include ['lib/*.{bundle,so,obj,pdb,lib,def,exp}']

desc "Does a full compile, test run"
task :default => [:compile, :test]

desc "Compiles all extensions"
task :compile => [:redcloth_scan] do
  if Dir.glob(File.join("lib","redcloth_scan.*")).length == 0
    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    STDERR.puts "Gem actually failed to build.  Your system is"
    STDERR.puts "NOT configured properly to build redcloth."
    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit(1)
  end
end

desc "Packages up RedCloth."
task :package => [:clean, :compile]

desc "Releases packages for all RedCloth packages and platforms."
task :release => [:package, :rubygems_win32]

desc "Run all the tests"
Rake::TestTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/test_*.rb']
    t.verbose = true
end

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

Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'doc/rdoc'
    # rdoc.options += RDOC_OPTS
    # rdoc.template = "extras/flipbook_rdoc.rb"
    rdoc.main = "README"
    rdoc.title = "RedCloth Documentation"
    rdoc.rdoc_files.add ['README', 'CHANGELOG', 'COPYING', 'lib/**/*.rb', 'ext/**/*.c']
end

PKG_FILES = %w(CHANGELOG COPYING README Rakefile) +
  Dir.glob("{bin,doc,test,lib,extras}/**/*") + 
  Dir.glob("ext/**/*.{h,c,rb,rl}") + 
  %w[attributes inline scan].map {|f| "ext/redcloth_scan/redcloth_#{f}.c"}

spec =
    Gem::Specification.new do |s|
        s.name = NAME
        s.version = VERS
        s.platform = Gem::Platform::RUBY
        s.has_rdoc = true
        s.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]
        s.summary = SUMMARY
        s.description = s.summary
        s.author = "Jason Garber"
        s.email = 'redcloth-upwards@rubyforge.org'
        s.homepage = 'http://redcloth.org/'
        s.rubyforge_project = 'redcloth'
        
        s.files = PKG_FILES
        
        s.require_paths << "lib/case_sensitive_require"
        #s.autorequire = "redcloth"  # no no no this is tHe 3v1l
        s.extensions = FileList["ext/**/extconf.rb"].to_a
        s.executables = ["redcloth"]
    end

Rake::GemPackageTask.new(spec) do |p|
    p.need_tar = true
    p.gem_spec = spec
end

extension = "redcloth_scan"
ext = "ext/redcloth_scan"
ext_so = "#{ext}/#{extension}.#{Config::CONFIG['DLEXT']}"
ext_files = FileList[
  "#{ext}/redcloth_scan.c",
  "#{ext}/redcloth_inline.c",
  "#{ext}/redcloth_attributes.c",
  "#{ext}/extconf.rb",
  "#{ext}/Makefile",
  "lib"
] 

file ext_so => ext_files do
  Dir.chdir(ext) do
    sh(RUBY_PLATFORM =~ /win32/ ? 'nmake' : 'make')
  end
  cp ext_so, "lib"
end

task "lib" do
  directory "lib"
end

["#{ext}/redcloth_scan.c","#{ext}/redcloth_inline.c","#{ext}/redcloth_attributes.c"].each do |name|
  @code_style ||= "T0"
  source = name.sub(/\.c$/, '.rl')
  file name => [source, "#{ext}/redcloth_common.rl", "#{ext}/redcloth.h"] do
    @ragel_v ||= `ragel -v`[/(version )(\S*)/,2].split('.').map{|s| s.to_i}
    if @ragel_v[0] > 6 || (@ragel_v[0] == 6 && @ragel_v[1] >= 3)
      sh %{ragel #{source} -#{@code_style} -o #{name}}
    else
      STDERR.puts "Ragel 6.3 or greater is required to generate #{name}."
      exit(1)
    end
  end
end

desc "Builds just the #{extension} extension"
task extension.to_sym => ["#{ext}/Makefile", ext_so ]

file "#{ext}/Makefile" => ["#{ext}/extconf.rb", "#{ext}/redcloth_scan.c","#{ext}/redcloth_inline.c","#{ext}/redcloth_attributes.c"] do
  Dir.chdir(ext) do ruby "extconf.rb" end
end

Win32Spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERS
  s.platform = 'x86-mswin32-60'
  s.has_rdoc = false
  s.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]
  s.summary = SUMMARY 
  s.description = s.summary
  s.author = "Jason Garber"
  s.email = 'redcloth-upwards@rubyforge.org'
  s.homepage = 'http://redcloth.org/'
  s.rubyforge_project = 'redcloth'

  s.files = PKG_FILES + ["lib/redcloth_scan.so"]

  s.require_path = "lib"
  #s.autorequire = "redcloth"  # no no no this is tHe 3v1l
  s.extensions = []
  s.bindir = "bin"
end
  
WIN32_PKG_DIR = "pkg/#{NAME}-#{VERS}-mswin32"

file WIN32_PKG_DIR => [:package] do
  cp_r "pkg/#{NAME}-#{VERS}", "#{WIN32_PKG_DIR}"
end

desc "Cross-compile the redcloth_scan extension for win32"
file "redcloth_scan_win32" => [WIN32_PKG_DIR] do
  cp "extras/mingw-rbconfig.rb", "#{WIN32_PKG_DIR}/ext/redcloth_scan/rbconfig.rb"
  sh "cd #{WIN32_PKG_DIR}/ext/redcloth_scan/ && ruby -I. extconf.rb && make"
  mv "#{WIN32_PKG_DIR}/ext/redcloth_scan/redcloth_scan.so", "#{WIN32_PKG_DIR}/lib"
end

desc "Build the binary RubyGems package for win32"
task :rubygems_win32 => ["redcloth_scan_win32"] do
  Dir.chdir("#{WIN32_PKG_DIR}") do
    Gem::Builder.new(Win32Spec).build
    verbose(true) {
      cp Dir["*.gem"].first, "../"
    }
  end
end

CLEAN.include WIN32_PKG_DIR

desc "Build and install the RedCloth gem on your system"
task :install => [:package] do
  sh %{sudo gem install pkg/#{NAME}-#{VERS}}
end

desc "Uninstall the RedCloth gem from your system"
task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end

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

namespace "jruby" do
 
  def ant(*args)
    system "ant #{args.join(' ')}"
  end
 
  desc "Installs jruby in a subdirectory of ./test/"
  task :install do
    sh %{svn export http://svn.codehaus.org/jruby/trunk/jruby test/jruby}
    Dir.chdir "test/jruby" do
      ant; ant "jar-complete"; # ant "create-apidocs"
    end
    sh %{jruby -S gem install rake}
    Rake::Task['add_path'].invoke
  end
 
  desc "Adds jruby to your PATH"
  task :add_path do
    ENV['PATH'] = ENV['PATH'] + ":" + File.join(File.dirname(__FILE__), "test/jruby/bin")
  end
  
  # Java only supports the table-driven code
  # generation style at this point.
  desc "Generates the Java scanner code using the Ragel table-driven code generation style."
  task :ragel_java => [:ragel_version] do
    ensure_ragel_version("RedclothScanService.java") do
      puts "compiling with ragel version #{@ragel_v}"
      sh %{ragel -J -o ext/redcloth_scan/RedclothScanService.java ext/redcloth_scan/redcloth_scan.java.rl}
    end
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
 
  def compile_java(filename, jarname)
    sh %{javac -source 1.5 -target 1.5 #{java_classpath_arg} #{filename}}
    sh %{jar cf #{jarname} *.class}
  end
 
  task :redcloth_scan_java => [:ragel_java] do
    Dir.chdir "ext/redcloth_scan" do
      compile_java("RedclothScanService.java", "redcloth_scan.jar")
    end
  end
  
  JRUBY_PKG_DIR = "pkg-jruby"
 
  desc "Package up the JRuby distribution."
  file JRUBY_PKG_DIR => [:ragel_java, :package] do
    sh "tar zxf #{JRUBY_PKG_DIR}/.tgz"
    mv PKG, JRUBY_PKG_DIR
  end
 
  desc "Build the RubyGems package for JRuby"
  task :package_jruby => JRUBY_PKG_DIR do
    Dir.chdir("#{JRUBY_PKG_DIR}") do
      Rake::Task[:hpricot_java].invoke
      Gem::Builder.new(JRubySpec).build
      verbose(true) {
        mv Dir["*.gem"].first, "../pkg/#{JRUBY_PKG_DIR}.gem"
      }
    end
  end
 
  CLEAN.include JRUBY_PKG_DIR
  
end
 
def ensure_ragel_version(name)
  @ragel_v ||= `ragel -v`[/(version )(\S*)/,2].split('.').map{|s| s.to_i}
  if @ragel_v[0] > 6 || (@ragel_v[0] == 6 && @ragel_v[1] >= 2)
    yield
  else
    STDERR.puts "Ragel 6.2 or greater is required to generate #{name}."
    exit(1)
  end
end

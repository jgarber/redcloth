require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'fileutils'
include FileUtils

NAME = "superredcloth"
SUMMARY = "a fast library for formatting Textile and Markdown as HTML"
REV = `svn info`[/Revision: (\d+)/, 1] rescue nil
VERS = ENV['VERSION'] || "1" + (REV ? ".#{REV}" : "")
CLEAN.include ['ext/superredcloth_scan/*.{bundle,so,obj,pdb,lib,def,exp}', 'ext/superredcloth_scan/Makefile', 
               '**/.*.sw?', '*.gem', '.config']

desc "Does a full compile, test run"
task :default => [:compile, :test]

desc "Compiles all extensions"
task :compile => [:superredcloth_scan] do
  if Dir.glob(File.join("lib","superredcloth_scan.*")).length == 0
    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    STDERR.puts "Gem actually failed to build.  Your system is"
    STDERR.puts "NOT configured properly to build superredcloth."
    STDERR.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit(1)
  end
end
task :superredcloth_scan => [:ragel]

desc "Packages up SuperRedCloth."
task :package => [:clean, :ragel]

desc "Releases packages for all SuperRedCloth packages and platforms."
task :release => [:package, :rubygems_win32]

desc "Run all the tests"
Rake::TestTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/test_*.rb']
    t.verbose = true
end

Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'doc/rdoc'
    # rdoc.options += RDOC_OPTS
    # rdoc.template = "extras/flipbook_rdoc.rb"
    rdoc.main = "README"
    rdoc.title = "SuperRedCloth Documentation"
    rdoc.rdoc_files.add ['README', 'CHANGELOG', 'COPYING', 'lib/**/*.rb']
end

spec =
    Gem::Specification.new do |s|
        s.name = NAME
        s.version = VERS
        s.platform = Gem::Platform::RUBY
        s.has_rdoc = true
        s.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]
        s.summary = SUMMARY
        s.description = s.summary
        s.author = "why the lucky stiff"
        s.email = 'why@ruby-lang.org'
        s.homepage = 'http://code.whytheluckystiff.net/redcloth/'

        s.files = %w(COPYING README Rakefile) +
          Dir.glob("{bin,doc,test,lib,extras}/**/*") + 
          Dir.glob("ext/**/*.{h,c,rb,rl}") + 
          %w[ext/superredcloth_scan/superredcloth_scan.c] # needed because it's generated later
        
        s.require_path = "lib"
        #s.autorequire = "superredcloth"  # no no no this is tHe 3v1l
        s.extensions = FileList["ext/**/extconf.rb"].to_a
        s.bindir = "bin"
    end

Rake::GemPackageTask.new(spec) do |p|
    p.need_tar = true
    p.gem_spec = spec
end

extension = "superredcloth_scan"
ext = "ext/superredcloth_scan"
ext_so = "#{ext}/#{extension}.#{Config::CONFIG['DLEXT']}"
ext_files = FileList[
  "#{ext}/*.c",
  "#{ext}/*.h",
  "#{ext}/*.rl",
  "#{ext}/extconf.rb",
  "#{ext}/Makefile",
  "lib"
] 

task "lib" do
  directory "lib"
end

desc "Builds just the #{extension} extension"
task extension.to_sym => ["#{ext}/Makefile", ext_so ]

file "#{ext}/Makefile" => ["#{ext}/extconf.rb"] do
  Dir.chdir(ext) do ruby "extconf.rb" end
end

file ext_so => ext_files do
  Dir.chdir(ext) do
    sh(PLATFORM =~ /win32/ ? 'nmake' : 'make')
  end
  cp ext_so, "lib"
end

desc "returns the ragel version"
task :ragel_version do
  @ragel_v = `ragel -v`[/(version )(\S*)/,2].to_f
end

desc "Generates the scanner code with Ragel."
task :ragel => [:ragel_version] do
  Dir.chdir('ext/superredcloth_scan') do
    ['superredcloth_scan', 'superredcloth_inline'].each do |src|
      sh %{ragel #{src}.rl | #{@ragel_v >= 5.18 ? 'rlgen-cd' : 'rlcodegen'} -G2 -o #{src}.c}
    end
  end
end

PKG_FILES = FileList[
  "test/**/*.{rb,html,xhtml}",
  "lib/**/*.rb",
  "ext/**/*.{c,rb,h,rl}",
  "CHANGELOG", "README", "Rakefile", "COPYING",
  "extras/**/*", "lib/superredcloth_scan.so"]

Win32Spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERS
  s.platform = Gem::Platform::WIN32
  s.has_rdoc = false
  s.extra_rdoc_files = ["README", "CHANGELOG", "COPYING"]
  s.summary = SUMMARY 
  s.description = s.summary
  s.author = "why the lucky stiff"
  s.email = 'why@ruby-lang.org'
  s.homepage = 'http://code.whytheluckystiff.net/redcloth/'

  s.files = PKG_FILES

  s.require_path = "lib"
  #s.autorequire = "superredcloth"  # no no no this is tHe 3v1l
  s.extensions = []
  s.bindir = "bin"
end
  
WIN32_PKG_DIR = "superredcloth-" + VERS

file WIN32_PKG_DIR => [:package] do
  sh "tar zxf pkg/#{WIN32_PKG_DIR}.tgz"
end

desc "Cross-compile the superredcloth_scan extension for win32"
file "superredcloth_scan_win32" => [WIN32_PKG_DIR] do
  cp "extras/mingw-rbconfig.rb", "#{WIN32_PKG_DIR}/ext/superredcloth_scan/rbconfig.rb"
  sh "cd #{WIN32_PKG_DIR}/ext/superredcloth_scan/ && ruby -I. extconf.rb && make"
  mv "#{WIN32_PKG_DIR}/ext/superredcloth_scan/superredcloth_scan.so", "#{WIN32_PKG_DIR}/lib"
end

desc "Build the binary RubyGems package for win32"
task :rubygems_win32 => ["superredcloth_scan_win32"] do
  Dir.chdir("#{WIN32_PKG_DIR}") do
    Gem::Builder.new(Win32Spec).build
    verbose(true) {
      mv Dir["*.gem"].first, "../pkg/superredcloth-#{VERS}-mswin32.gem"
    }
  end
end

CLEAN.include WIN32_PKG_DIR

task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end

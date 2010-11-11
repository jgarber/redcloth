namespace :gems do
  task :win do
    unless File.directory?(File.expand_path('~/.rake-compiler'))
      STDERR.puts <<-EOM

You must install Windows rubies to ~/.rake-compiler with:

  rake-compiler cross-ruby VERSION=1.8.6-p398
  # (Later 1.9.1 patch levels don't compile on mingw) 
  rake-compiler cross-ruby VERSION=1.9.1-p243
EOM
      exit(1)
    end
    # rvm and mingw ruby versions have to match to avoid errors
    sh "rvm ruby-1.8.6-p398@redcloth rake cross compile RUBY_CC_VERSION=1.8.6"
    sh "rvm ruby-1.9.1-p243@redcloth rake cross compile RUBY_CC_VERSION=1.9.1"
    # This will copy the .so files to the proper place
    sh "rake cross compile RUBY_CC_VERSION=1.8.6:1.9.1"
  end

  desc 'Prepare JRuby binares'
  task :jruby do
    sh "rvm jruby@redcloth rake compile"
  end

  desc "Prepare binaries for all gems"
  task :prepare => [
    :clean,
    :spec,
    :win,
    :jruby
  ]
  
  desc "Build all gems"
  task :build => [:prepare, :gem] do
  end
end
  
%w(ruby java x86-mswin32 x86-mingw32).map do |gem_platform|
  Rake::GemPackageTask.new(gemspec.dup) do |t|
    t.gem_spec.platform = gem_platform
    case gem_platform
    when /java/
      t.gem_spec.files += ['lib/redcloth_scan.jar']
    when /mswin|mingw32/
      t.gem_spec.files += Dir['lib/*/*.so']
    when /dotnet/
      t.gem_spec.files += Dir['lib/*.dll']
    else # MRI or Rubinius
      t.gem_spec.files += Dir['ext/**/*.c']
      t.gem_spec.extensions = Dir['ext/**/extconf.rb']
      t.gem_spec.add_development_dependency('rake-compiler', '~> 0.7.1')
    end
  end
end

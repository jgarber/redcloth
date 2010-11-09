require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts = %w{--exclude osx\/objc,gems\/,spec\/}
end

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
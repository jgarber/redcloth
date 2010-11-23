namespace :release do
  desc 'Upload all packages and tag git'
  task :all => [:release, :push_native_gems]

  desc 'Push all gems to rubygems.org (gemcutter)'
  task :push_native_gems do
    Dir.chdir('release') do
      Dir['*.gem'].each do |gem_file|
        sh("gem push #{gem_file}")
      end
    end
  end
end
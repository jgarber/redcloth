namespace :release do
  desc 'Push all gems to rubygems.org'
  task :gem do
    puts "Did you git tag and git push the tag for this release yet?"
    sh("rm *.gem")
    sh("gem build redcloth.gemspec")
    sh("gem push RedCloth-*.gem")
  end
end


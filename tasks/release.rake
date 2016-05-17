namespace :release do
  desc 'Push all gems to rubygems.org'
  # git tag and push tag
  # branch into stable vx.x branch
  # change version in version.rb
  # update changelog
  # run rake test
  
  task :gem do
    puts "Did you git tag and git push the tag for this release yet?"
    sh("rm *.gem")
    sh("gem build redcloth.gemspec")
    sh("gem push RedCloth-*.gem")
  end
end


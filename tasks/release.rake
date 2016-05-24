namespace :release do
  desc 'Push all gems to rubygems.org'
  # git tag and push tag
  # git tag vx.x.x
  # git push --follow-tags
  # branch into stable vx.x branch
  # change version in version.rb
  # update changelog
  # run rake test

  task :gem do
    sh("gem build redcloth.gemspec")
    sh("gem push RedCloth-*.gem")
  end
end


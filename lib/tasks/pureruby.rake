Gem::Specification::PLATFORM_CROSS_TARGETS << "pureruby"

task 'pureruby' do
  reset_target 'pureruby'
end

if target = ARGV.detect do |arg| 
  # Hack to get the platform set before the Rakefile evaluates
    Gem::Specification::PLATFORM_CROSS_TARGETS.include? arg
  end
  reset_target target
end

namespace :rvm do
  
  RVM_RUBIES = ['jruby-1.5.3', 'ruby-1.8.6-p398', 'ruby-1.9.1-p243', 'ruby-1.9.2-head', 'ree-1.8.7']
  RVM_GEMSET_NAME = 'redcloth'
  
  task :setup do
    unless @rvm_setup
      rvm_lib_path = "#{`echo $rvm_path`.strip}/lib"
      $LOAD_PATH.unshift(rvm_lib_path) unless $LOAD_PATH.include?(rvm_lib_path)
      require 'rvm'
      require 'tmpdir'
      @rvm_setup = true
    end
  end
  
  desc "Install development gems using bundler to each rubie version"
  task :bundle => :setup do
    rvm_each_rubie { RVM.run 'gem install bundler; bundle install' }
  end
  
  desc "Echo command to run specs under each rvm ruby"
  task :spec => :setup do
    puts "rvm #{rvm_rubies.join(',')} rake"
  end
  
end


# RVM Helper Methods

def rvm_each_rubie
  rvm_rubies.each do |rubie|
    RVM.use(rubie)
    yield
  end
ensure
  RVM.reset_current!
end

def rvm_rubies(options={})
  RVM_RUBIES.map{ |rubie| "#{rubie}@#{RVM_GEMSET_NAME}" }
end


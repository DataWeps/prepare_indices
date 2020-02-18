require 'bundler/gem_tasks'
DIR['./lib/tasks/*.rake'].each do |file|
  import(file)
end

task :default => :spec

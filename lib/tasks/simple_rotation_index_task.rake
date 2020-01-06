namespace :prepare_indices do
  task :simple_rotation_index do
    params = Oj.load(ENV['params'] || '{}')
    puts PrepareIndices::SimpleRotationIndexJob.new.perform(
      ENV['type'].split(';'),
      params).inspect
  end
end

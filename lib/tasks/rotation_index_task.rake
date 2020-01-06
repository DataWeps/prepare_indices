namespace :prepare_indices do
  task :rotation_index do
    params = Oj.load(ENV['params'] || '{}')
    puts PrepareIndices::RotationIndexJob.perform(
      ENV['type'].split(';'),
      params).inspect
  end
end

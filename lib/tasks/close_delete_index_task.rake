namespace :prepare_indices do
  task :close_index do
    # params='{ "connect": { "host": "localhost:9200"}, "close_older_indices": true }'
    params = Oj.load(ENV['params'] || '{}')
    puts PrepareIndices::CloseIndex.perform(params).inspect
  end
end

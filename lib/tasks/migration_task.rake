namespace :prepare_indices do
  desc 'Say something'
  task :migrate do
    # bundle exec rake prepare_indices:migrate es='https://localhost:9202' migration='1' index='disputatio_articles' index_to_update='disputatio_articles_201901' from='optional' to='optional'
    require 'prepare_indices/migration'
    PrepareIndices::Migration.perform(
      es: ENV['es'],
      migration: ENV['migration'],
      file: ENV['file'],
      index:     ENV['index'],
      index_to_update: ENV['index_to_update'],
      type: ENV['type'] || nil,
      from: ENV['from'],
      to:   ENV['to'])
  end
end

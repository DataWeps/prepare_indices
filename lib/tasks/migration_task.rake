namespace :prepare_indices do
  desc 'Say something'
  task :migrate do
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

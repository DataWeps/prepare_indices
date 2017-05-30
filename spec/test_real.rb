require 'prepare_indices'
@es = Elasticsearch::Client.new(host: 'localhost:9200')
params = {
  es: @es,
  file: File.join(__dir__, 'example.json'),
  index: 'muj_20170319200958',
  type: 'document',
  create: false,
  delete: true,
  setting: true,
  mapping: true,
  aliases: true }

puts PrepareIndices::CreateIndices.perform(params)

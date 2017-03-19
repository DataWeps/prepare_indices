require 'prepare_indices'
@es = Elasticsearch::Client.new(host: 'localhost:9200')
params = {es: @es, file: '/home/petra/ruby/prace/prepare_indices/spec/example.json', index: 'muj_20170319200958', type: 'document', create: false, delete: true, setting: true, mapping: true, aliases: true }
PrepareIndices::Base.check_params(params)
binding.pry
PrepareIndices::Base.start(params)

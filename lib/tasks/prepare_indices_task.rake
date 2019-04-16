namespace :prepare_indices do
  desc 'prepare indices task'
  task :perform do
    require 'prepare_indices/create_indices'
    require 'prepare_indices/requests'
    require 'elasticsearch'
    params = {
      es:    ENV['es'],
      index: ENV['index'],
      type:  ENV['type'] }

    params.each do |par|
      raise(ArgumentError, "Missing mandatory key: #{par[0]}") if par[1].nil?
    end

    languages = (ENV['languages'] || '').split(';')

    params = params.merge(
      force_index: ENV['force_index'],
      languages:   languages,
      mappings:    ENV['mappings'],
      settings:    ENV['settings'],
      close:       ENV['close'],
      aliases:     ENV['aliases'],
      create:      ENV['create'],
      delete:      ENV['delete'],
      file:        ENV['file'],
      time:        (ENV['time'] || 'this_month').to_sym,
      base_file:   ENV['base_file'] || false,
      log:         ENV['log'] || 'no')

    response = PrepareIndices::CreateIndices.perform(params)
    puts response
    response
  end
end

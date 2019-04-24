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
      raise ArgumentError, "Missing mandatory key: #{par[0]}" if par[1].nil?
    end

    params = params.merge(
      force_index: ENV['force_index'],
      mappings:    ENV['mappings'],
      settings:    ENV['settings'],
      close:       ENV['close'],
      aliases:     ENV['aliases'],
      create:      ENV['create'],
      delete:      ENV['delete'],
      file:        ENV['file'],
      log:         ENV['log'])

    PrepareIndices::CreateIndices.perform(params)
  end
end

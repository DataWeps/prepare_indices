require 'active_support/core_ext/time/calculations'

namespace :prepare_indices do
  # bundle exec rake prepare_indices:hamster_create_indices es='http://localhost:9201' from_time='2020-01-01' to_time='2020-01-02' type='hamster_logger' languages='heureka_cz' rotation_check=date

  task :hamster_create_indices do
    params = {
      connect: { log: true, host: ENV['es'] },
      rotation: ES[ENV['type'].to_sym][:rotation] || {},
      rotation_check: (ENV['rotation_check'] || '').to_sym,
      index: ENV['index'],
      languages: ENV['languages'].split(';'),
      base_file: false,
      name: ENV['type'],
      create: true,
      settings: true,
      aliases: true,
      required: false,
      merge: true,
      time: (ENV['time'] || 'this_month').to_sym
    }
    puts PrepareIndices::CreateIndices.perform(params)
  end
end

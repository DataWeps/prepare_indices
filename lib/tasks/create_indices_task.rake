require 'active_support/core_ext/time/calculations'

namespace :prepare_indices do
  task :create_indices do
    response = {}
    from_time = Time.parse(ENV['from_time'])
    to_time = Time.parse(ENV['to_time'] || Time.now.beginning_of_month.strftime('%Y-%m-%d'))
    loop do
      break if from_time > to_time

      response[from_time] = PrepareIndices::RotationIndexJob.perform(
        ENV['type'].split(';'),
        { "rotation" => { "time" => from_time.strftime('%Y-%m-%d') } })
      from_time = from_time.months_since(1)
    end
  end
end

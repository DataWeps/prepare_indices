require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/object/blank'
require 'oj'

namespace :prepare_indices do
  # bundle exec rake prepare_indices:create_indices explicit_params='{ "connect": { "host": "http://localhost:9202" } }' from_time='2019-08-01' to_time='2019-08-01' type='disputatio'
  # bundle exec rake prepare_indices:create_indices explicit_params='{ "connect": { "host": "https://localhost:9202", "ssl": { "verify": false } } }' from_time='2019-08-01' to_time='2019-08-01' type='disputatio'
  task :create_indices do
    response = {}
    from_time = Time.parse(ENV['from_time'])
    to_time = Time.parse(ENV['to_time'] || Time.now.beginning_of_month.strftime('%Y-%m-%d'))
    loop do
      break if from_time > to_time

      explicit_params = {
        'rotation' => { 'time' => from_time.strftime('%Y-%m-%d') } }
      explicit_params.deep_merge!(Oj.load(ENV['explicit_params'])) if\
       ENV['explicit_params'].present?

      response[from_time] = PrepareIndices::RotationIndexJob.perform(
        ENV['type'].split(';'),
        explicit_params)
      from_time = from_time.months_since(1)
    end
    puts "#{response}"
  end
end

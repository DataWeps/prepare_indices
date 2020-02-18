require 'prepare_indices/close_delete_index'

namespace :prepare_indices do
  task :close_index do
    # bundle exec rake prepare_indices:close_index params='{ "connect": { "host": "localhost:9200"}, "close_older_indices": true, "delete_older_indices": true, index": "index_name" }'
    params = Oj.load(ENV['params'] || '{}')
    puts PrepareIndices::CloseDeleteIndex.perform(params: params).inspect
  end

  task :close_all_indices do
    # bundle exec rake prepare_indices:close_all_indices_older_than params='{ "connect": { "host": "localhost:9200"}, "close_older_indices": true, "index": "index_name" }' from_time=YYYY-mm-dd to_time=YYYY-mm-dd
    params = Oj.load(ENV['params'] || '{}')
    response = {}
    from_time = Time.parse(ENV['from_time'])
    to_time = Time.parse(ENV['to_time'] || Time.now.months_ago(2).beginning_of_month.strftime('%Y-%m-%d'))
    loop do
      break if from_time > to_time

      params[:close_date] = nil
      params[:delete_date] = nil

      params[:close_date] = from_time.strftime('%Y-%m-%d') if params[:close_older_indices]
      params[:delete_date] = from_time.strftime('%Y-%m-%d') if params[:delete_older_indices]

      response[from_time.to_s] = PrepareIndices::CloseDeleteIndex.perform(params: params).inspect
      from_time = from_time.months_since(1)
    end
    puts response
  end
end

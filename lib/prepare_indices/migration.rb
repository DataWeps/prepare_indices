require 'json'
require 'elasticsearch'
require 'active_support/core_ext/time/calculations'

module PrepareIndices
  class Migration
    class << self
      def perform(es:, migration:, index:, index_to_update: nil, file: nil, type: nil, from: nil, to: nil)
        @client = Elasticsearch::Client.new(host: es, log: true)
        return nil unless index_to_update
        json_file = read_migration(migration, index, file)
        return put_mapping(index_to_update, type, json_file) unless to || from
        from_time = Time.parse(from)
        to_time   = Time.parse(to)
        loop do
          break if from_time > to_time
          put_mapping("#{index_to_update}_#{from_time.strftime('%Y%m')}", type, json_file)
          from_time = from_time.months_since(1)
        end
      end

    private

      def put_mapping(index, type, file)
        @client.indices.put_mapping(
          index: index,
          type: type || 'document',
          body: file)
      end

      def read_migration(migration, index, file)
        JSON.parse(
          File.read(resolve_migration_file(migration, index, file)))
      end

      def resolve_migration_file(migration, index, file)
        dir = \
          if file
            file
          else
            File.join("db/mappings/migrations/#{'%.2i' % migration}_#{index}.json")
          end
        puts File.expand_path(dir).to_s
        dir
      end
    end
  end
end

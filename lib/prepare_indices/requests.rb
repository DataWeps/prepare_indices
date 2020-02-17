require 'json'

module PrepareIndices
  class Requests
    class << self
      def exists_alias?(es:, index:)
        es.indices.exists_alias?(name: index)
      end

      def exists_index?(es:, index:)
        es.indices.exists?(index: index)
      end

      def put_settings(es:, settings:, index:, type:, if_close_index: false)
        safe_request do
          return if settings.empty?

          close_index(es: es, index: index, if_close_index: if_close_index)
          es.indices.put_settings(
            index: index,
            type: type,
            body: settings)
        end
      ensure
        es.indices.open(index: index) if if_close_index
      end

      def put_mappings(es:, mappings:, index:, type:, if_close_index: false)
        safe_request do
          close_index(es: es, index: index, if_close_index: if_close_index)
          es.indices.put_mapping(index: index, type: type, body: mappings[type] || mappings)
        end
      end

      def create_index(es:, index:, settings:, mappings:)
        safe_request do
          sleep(1)
          index_name = "#{index}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
          es.indices.create(
            index: index_name,
            body: {
              settings: settings,
              mappings: mappings })
          { errors: false, index: index_name }
        end
      end

      def put_aliases(es:, index:, aliases:)
        safe_request do
          return { errors: false } if index.blank?

          aliases.each do |aliaz|
            es.indices.put_alias(index: index, name: aliaz)
          end
        end
      end

      def delete_index(es:, index:)
        es.indices.delete(index: index) if es.indices.exists?(index: index)
      end

      def find_index(es:, name:)
        es.indices.get(index: name)
      end

      def close_index(es:, index:, if_close_index: false)
        es.indices.close(index: index) if if_close_index
      end

      private

      def safe_request
        response = yield
        { errors: false }.merge(response || {})
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, error: error }
      end
    end
  end
end

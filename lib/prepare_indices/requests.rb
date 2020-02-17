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
        return if settings.empty?

        close_index(es: es, index: index, if_close_index: if_close_index)
        es.indices.put_settings(
          index: index,
          type: type,
          body: settings)
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, settings_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, settings_error: error }
      ensure
        es.indices.open(index: index) if close_index
      end

      def put_mappings(es:, mappings:, index:, type:, if_close_index: false)
        close_index(es: es, index: index, if_close_index: if_close_index)
        es.indices.put_mapping(index: index, type: type, body: mappings[type] || mappings)
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, mappings_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, mappings_error: error }
      end

      def create_index(es:, index:, settings:, mappings:)
        sleep(1)
        index_name = "#{index}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
        es.indices.create(
          index: index_name,
          body: {
            settings: settings,
            mappings: mappings })
        { errors: false, index: index_name }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, create_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, create_error: error }
      end

      def put_aliases(es:, index:, aliases:)
        { errors: false } if index.blank?
        aliases.each do |aliaz|
          es.indices.put_alias(index: index, name: aliaz)
        end
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, aliases_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, aliases_error: error }
      end

      def delete_index(es:, index:)
        es.indices.delete(index: index) if es.indices.exists?(index: index)
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, delete_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, delete_error: error }
      end

      def find_index(es:, name:)
        es.indices.get(index: name)
      end

      def close_index(es:, index:, if_close_index: false)
        es.indices.close(index: index) if if_close_index
      end
    end
  end
end

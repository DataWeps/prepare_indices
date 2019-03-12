require 'json'

module PrepareIndices
  module Requests
    class << self
      def put_settings(es:, settings:, index:, type:, close_index: false)
        return if settings.empty?
        es.indices.close(index: index) if close_index
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

      def put_mappings(es:, mappings:, index:, type:, close_index: false)
        es.indices.close(index: index) if close_index
        es.indices.put_mapping(index: index, type: type, body: mappings[type] || mappings)
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, mappings_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, mappings_error: error }
      end

      def create_index(es:, index:, settings:, mappings:)
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
        aliases.each do |a|
          es.indices.put_alias(
          index: index,
          name: a)
        end
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, aliases_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, aliases_error: error }
      end

      def delete_index(es:, index:)
        es.indices.delete(index: index) #if es.indices.exists?(index: index)
        { errors: false }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { errors: true, delete_error: error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { errors: true, delete_error: error }
      end
    end
  end
end

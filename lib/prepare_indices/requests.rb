require 'json'

module PrepareIndices
  module Requests
    class << self
      def load_mappings(file:, index:)
        open = JSON.parse(File.read(file))
        raise ArgumentError, "Index is not in file" unless open[index]
        { mappings: open[index]['mappings'],
          settings: open[index]['settings'],
          aliases: open[index]['aliases'] || {} }
      rescue Errno::ENOENT
        nil
      end

      def put_settings(es:, settings:, index:, type:)
        return if settings.empty?
        es.indices.put_settings(
          index: index,
          type: type,
          body: settings)
        true
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { 'errors' => true, 'setting_error' => error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { 'errors' => true, 'setting_error' => error }
      end

      def put_mappings(es:, mappings:, index:, type:)
        return if mappings.empty?
        es.indices.put_mapping(
          index: index,
          type: type,
          body: mappings)
        true
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { 'errors' => true, 'mapping_error' => error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { 'errors' => true, 'mapping_error' => error }
      end

      def create_index(es:, index:, settings:)
        index_name = "#{index}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
        es.indices.create(index: index_name, body: settings)
        index_name
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { 'errors' => true, 'create_error' => error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { 'errors' => true, 'create_error' => error }
      end

      def put_aliases(es:, index:, aliases:)
        aliases.each do |a|
          es.indices.put_alias(
          index: index,
          name: a)
        end
        true
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { 'errors' => true, 'alias_error' => error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { 'errors' => true, 'alias_error' => error }
      end

      def delete_index(es:, index:)
        es.indices.delete(index: index)
        true
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => error
        { 'errors' => true, 'delete_error' => error }
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => error
        { 'errors' => true, 'delete_error' => error }
      end
    end
  end
end

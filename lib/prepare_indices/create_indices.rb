require 'prepare_indices/mappings'
require 'pry'
module PrepareIndices
  module CreateIndices
    class << self
      def perform(params)
        check_params!(params)
        start(params)
      end

    private

      def start(params)
        # require 'pry'
        # binding.pry
        client = Elasticsearch::Client.new(params[:connect].merge(
          params.include?(:logger) ? { logger: params[:logger] } : {}))
        index                = params[:index]
        index_for_update     = params[:force_index] || params[:index]
        params[:languages] ||= []
        params[:languages]   = %w[base] if params[:languages].blank?

        mapping = Mappings.load_mappings(
          file:      params[:file],
          index:     params[:name] || index,
          languages: params[:languages],
          base_file: params[:base_file],
          time:      params[:time],
          merge:     params[:merge])

        return mapping if mapping.include?(:errors)

        binding.pry

        params[:languages].each_with_object({}) do |language, mem|
          # mem[language] =
          #   build(client, params, index_for_update, mapping[language], language)
        end
      end

      def build(client, params, index_for_update, mapping, language)
        index_type = params[:type]
        err = {}
        if params[:delete]
          response = Requests.delete_index(es: client, index: index)
          Base.merge_errors!(err, response)
        end
        if params[:create]
          response = Requests.create_index(
            es: client,
            index: index_for_update,
            settings: mapping[:settings] || {},
            mappings: mapping[:mappings])
          Base.merge_errors!(err, response)
          index_for_update = response[:index]
        end
        if params[:settings] && !params[:create]
          response = Requests.put_settings(
            es: client,
            close_index: params[:close_index],
            settings: mapping[:settings] || {},
            index: index_for_update,
          type: index_type)
          Base.merge_errors!(err, response)
        end
        if params[:mappings] && !params[:create]
          response = Requests.put_mappings(
            es: client,
            mappings: mapping[:mappings],
            index: index_for_update,
            type: index_type,
            close_index: params[:close_index])
          Base.merge_errors!(err, response)
        end
        if params[:aliases]
          response = Requests.put_aliases(
            es: client,
            index: index_for_update,
            aliases: mapping[:aliases].keys.to_a)
          Base.merge_errors!(err, response)
        end
        if err[:errors]
          { status: :error, errors: err, index: index_for_update, language: language }
        else
          { status: :ok, index: index_for_update, language: language }
        end
      end

      def check_params!(params)
        %i[connect index].each do |key|
          raise(ArgumentError, "Missing params key #{key}") unless params.key?(key)
        end
        %i[mappings settings aliases create delete].each do |key|
          params[key] = false unless params.include?(key)
        end
        %i[base_file].each do |key|
          params[key] = true unless params.include?(key)
        end
        %i[log base_file mappings settings force_index
           close aliases create delete].each do |key|
          params[key] = \
            params.include?(key) && params[key].to_s =~ /true|yes|y|1|ano/ ? true : false
        end
        params[:languages].uniq!
        params[:time] = params[:time].to_sym if params.include?(:time)
        params
      end
    end
  end
end

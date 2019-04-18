require 'prepare_indices/mappings'
require 'prepare_indices/requests'

require 'pry'
module PrepareIndices
  class CreateIndicesError < StandardError; end

  module CreateIndices
    class << self
      def perform(params)
        check_params!(params)
        start(params)
      end

    private

      def start(params)
        require 'pry'
        binding.pry
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
        exists_indices = check_exists_indices(index_for_update, client, params, mapping)

        mapping.each_key.each_with_object({}) do |language, mem|
          mem[language] = \
            if exists_indices[language]
              { status: :exists }
            else
              build(client, params, index_for_update, mapping[language], language)
            end
        end
      end

      def check_exists_indices(index_for_update, client, params, mapping)
        mapping.keys.each_with_object({}) do |mapping_key, mem|
          alias_to_check = find_alias_to_check(
            index_for_update, mapping_key, params, mapping[mapping_key][:aliases])
          mem[mapping_key] = Requests.exists_index?(es: client, index: alias_to_check)
        end
      end

      def find_alias_to_check(index_for_update, mapping_key, params, aliases)
        if params[:rotation_check] == :date
          "#{index_for_update}_#{Mappings.what_time(params[:time])}"
        elsif params[:rotation_check] == :language_date
          "#{index_for_update}_#{mapping_key}_#{Mappings.what_time(params[:time])}"
        else
          index_for_update
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
          raise(CreateIndicesError, err) unless response[:index]
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
          raise(CreateIndicesError)
        else
          { status: :created, index: index_for_update, language: language }
        end
      rescue CreateIndicesError
        { status: :error, errors: err, index: index_for_update, language: language }
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

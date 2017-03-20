require "prepare_indices/version"
require 'elasticsearch'
require 'prepare_indices/requests'

module PrepareIndices
  include Requests
  class Base
    class << self
      #
      # params = {
      #   es: 'object'          # compalsory object of elasticsearch
      #   file: 'string',       # compalsory path to file with index
      #   index: 'string',      # compalsory name of index
      #   type: 'string'        # compalsory name of type
      #   mappings: 'boolean'    # default false
      #   settings: 'boolean'    # default false
      #   aliases: 'boolean'    # default false
      #   create: 'boolean'     # default false
      #   delete: 'boolean'     # default false
      # }
      #

      def perform(params: {})
        check_params(params)
        start(params)
      end

      def check_params(params)
        [:es, :file, :index, :type].each do |p|
          raise ArgumentError, 'Missing params key' unless params.key?(p)
        end
        [:mappings, :settings, :aliases, :create, :delete].each do |p|
          params[p] = false unless params.has_key?(p)
        end
        params
      end

      def start(params)
        client = params[:es]
        index = params[:index]
        mapping = Requests.load_mappings(file: params[:file], index: index)
        index_type = params[:type]
        err = {}
        if params[:delete]
          response = Requests.delete_index(es: client, index: index)
          merge_err!(err, response) if response[:errors]
        end
        if params[:create]
          response = Requests.create_index(
            es: client,
            index: index,
            settings: mapping[:settings])
          merge_err!(err, response) if response[:errors]
          index = response[:index]
        end
        if params[:settings] && !params[:create]
          response = Requests.put_settings(
            es: client,
            settings: mapping[:settings],
            index: index,
          type: index_type)
          merge_err!(err, response) if response[:errors]
        end
        if params[:mappings]
          response = Requests.put_mappings(
            es: client,
            mappings: mapping[:mappings],
            index: index,
            type: index_type)
          merge_err!(err, response) if response[:errors]
        end
        if params[:aliases]
          response = Requests.put_aliases(
            es: client,
            index: index,
            aliases: mapping[:aliases].keys.to_a)
        merge_err!(err, response) if response[:errors]
        end
        if err[:errors]
          { status: :error, errors: err, index: index }
        else
          { status: :ok, index: index }
        end
      end

      def merge_err!(err_1, err_2)
        err_1.merge!(err_2) if err_2.is_a?(Hash)
      end
    end
  end
end
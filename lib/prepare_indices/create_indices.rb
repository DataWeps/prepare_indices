
module PrepareIndices
  module CreateIndices
    class << self
      def perform(params)
        check_params!(params)
        start(params)
      end

    private

      def start(params)
        client = Elasticsearch::Client.new(
          host: params[:es],
          log: params[:log] =~ /(true|yes|y|1|ano)/ ? true : false)
        index = params[:index]
        index_for_update = params[:force_index] || params[:index]
        mapping = Requests.load_mappings(file: params[:file], index: params[:name] || index)
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
          { status: :error, errors: err, index: index_for_update }
        else
          { status: :ok, index: index_for_update }
        end
      end

      def check_params!(params)
        [:es, :file, :index, :type].each do |key|
          raise(ArgumentError, "Missing params key #{key}") unless params.key?(key)
        end
        [:mappings, :settings, :aliases, :create, :delete].each do |key|
          params[key] = false unless params.include?(key)
        end
        params
      end
    end
  end
end

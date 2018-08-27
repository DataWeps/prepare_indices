
module PrepareIndices
  module CreateIndices
    class << self
      def perform(params)
        check_params!(params)
        start(params)
      end

    private

      def start(params)
        client = params[:es]
        index = params[:index]
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
            index: index,
            settings: mapping[:settings] || {},
            mappings: mapping[:mappings])
          Base.merge_errors!(err, response)
          index = response[:index]
        end
        if params[:settings] && !params[:create]
          response = Requests.put_settings(
            es: client,
            close_index: params[:close_index],
            settings: mapping[:settings] || {},
            index: index,
          type: index_type)
          Base.merge_errors!(err, response)
        end
        if params[:mappings] && !params[:create]
          response = Requests.put_mappings(
            es: client,
            mappings: mapping[:mappings],
            index: index,
            type: index_type)
          Base.merge_errors!(err, response)
        end
        if params[:aliases]
          response = Requests.put_aliases(
            es: client,
            index: index,
            aliases: mapping[:aliases].keys.to_a)
          Base.merge_errors!(err, response)
        end
        if err[:errors]
          { status: :error, errors: err, index: index }
        else
          { status: :ok, index: index }
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

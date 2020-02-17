require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/hash/keys'

module PrepareIndices
  class CommonRotationJob
    @queue = :rotation_index
    DATA_TYPES = %i[node mention].freeze

    class << self
      def perform(types, explicit_params = {})
        explicit_params.deep_symbolize_keys!

        types.each_with_object({}) do |type, mem|
          type = type.to_sym
          DATA_TYPES.each do |data_type|
            params = create_base_params(type, data_type, explicit_params)

            mem[output_name(ES[type], type, data_type)] = \
              call_rotation_job(params)

            (ES[type][:connect_another] || []).each do |connect_another|
              mem[output_name(connect_another, type, data_type)] =
                call_rotation_job(
                  create_params(type, params, data_type, connect_another))
            end
          end
        end
      end

      private

      def create_base_params(type, data_type, explicit_params)
        ES[type] \
          .deep_dup.deep_merge(ES[type][:rotation][data_type]) \
          .deep_merge(explicit_params)
      end

      def output_name(connect, type, data_type)
        "#{type}_#{[connect[:connect][:host]].flatten[0]}_#{data_type}"
      end

      def create_params(type, params, data_type, connect_another)
        created_params = ES[type].deep_dup.deep_merge(connect_another)
        created_params.deep_merge!(params[:rotation][data_type]).deep_merge(
          explicit_params)
        created_params
      end

      def call_rotation_job(_)
        raise(MethodNotImplemented)
      end
    end
  end
end

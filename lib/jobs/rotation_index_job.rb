# encoding:utf-8
require 'prepare_indices'

require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/hash/keys'

module PrepareIndices
  class RotationIndexJob
    @queue = :rotation_index
    DATA_TYPES = %i[node mention].freeze

    class << self
      def perform(types, explicit_params = {})
        explicit_params.deep_symbolize_keys!

        types.each_with_object({}) do |type, mem|
          type = type.to_sym
          DATA_TYPES.each do |data_type|
            params = ES[type].deep_dup.deep_merge(ES[type][:rotation][data_type]).deep_merge(explicit_params)

            mem["#{type}_#{[ES[type][:connect][:host]].flatten[0]}_#{data_type}"] =
              PrepareIndices::RotationIndex.perform(params: params)

            (ES[type][:connect_another] || []).each do |connect_another|
              params = ES[type].deep_dup.deep_merge(connect_another)
              params = params.deep_merge(params[:rotation][data_type]).deep_merge(explicit_params)

              mem["#{type}_#{[connect_another[:connect][:host]].flatten[0]}_#{data_type}"] =
                PrepareIndices::RotationIndex.perform(params: params)
            end
          end
        end
      end
    end
  end
end

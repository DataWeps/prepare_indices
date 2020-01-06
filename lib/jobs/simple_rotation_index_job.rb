# encoding:utf-8
require 'prepare_indices'

require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/hash/keys'

module PrepareIndices
  class SimpleRotationIndexJob
    def self.perform(types, params = {})
      types.each_with_object({}) do |type, mem|
        temp_params = params.deep_dup
        temp_params.reverse_merge!(ES[type.to_sym] || {})
        temp_params[:connect] = ES[:common_config]
        temp_params[:name] ||= type
        mem[type] = PrepareIndices::RotationIndex.perform(params: temp_params)
      end
    end
  end
end

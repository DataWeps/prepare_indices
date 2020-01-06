# encoding:utf-8
require 'prepare_indices'

require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/hash/keys'

module PrepareIndices
  class SimpleRotationIndexJob
    def self.perform(types, params = {})
      types.each_with_object({}) do |type, mem|
        params.reverse_merge!(ES[type.to_sym] || {})
        params[:connect] = ES[:common_config]
        params[:name] ||= type
        mem[type] = PrepareIndices::RotationIndex.perform(params: params)
      end
    end
  end
end

# encoding:utf-8
require 'prepare_indices'

require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/hash/keys'

module PrepareIndices
  class SimpleRotationIndexJob
    def self.perform(connect_params)
      PrepareIndices::RotationIndex.perform(params: connect_params)
    end
  end
end

require 'prepare_indices'
require 'jobs/common_rotation_job'

module PrepareIndices
  class RotationIndexJob < CommonRotationJob
    class << self
      def call_rotation_job(params)
        PrepareIndices::RotationIndex.perform(params: params)
      end
    end
  end
end

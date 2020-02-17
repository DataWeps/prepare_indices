module PrepareIndices
  class CloseIndexJob < CommonRotationJob
    class << self
      def call_rotation_job(params)
        PrepareIndices::CloseIndex.perform(params: params)
      end
    end
  end
end

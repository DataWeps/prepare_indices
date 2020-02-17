module PrepareIndices
  class CloseDeleteIndexJob < CommonRotationJob
    class << self
      def call_rotation_job(params)
        PrepareIndices::CloseDeleteIndex.perform(params: params)
      end
    end
  end
end

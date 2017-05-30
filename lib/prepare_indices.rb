# encoding:utf-8
require 'prepare_indices/version'
require 'elasticsearch'

require 'prepare_indices/requests'
require 'prepare_indices/create_indices'
require 'prepare_indices/rotation_index'

module PrepareIndices
  include Requests
  include CreateIndices
  include RotationIndex

  class Base
    class << self
      #
      # params = {
      #   es: 'object'          # compalsory object of elasticsearch
      #   file: 'string',       # compalsory path to file with index
      #   index: 'string',      # compalsory name of index
      #   type: 'string'        # compalsory name of type
      #   mappings: 'boolean'    # default false
      #   settings: 'boolean'    # default false
      #   aliases: 'boolean'    # default false
      #   create: 'boolean'     # default false
      #   delete: 'boolean'     # default false
      # }
      #

      def check_params(params)
        [:es, :file, :index, :type].each do |p|
          raise ArgumentError, 'Missing params key' unless params.key?(p)
        end
        [:mappings, :settings, :aliases, :create, :delete].each do |p|
          params[p] = false unless params.include?(p)
        end
        params
      end

      def merge_errors!(err1, err2)
        return unless err2.include?(:errors)
        err1.merge!(err2) if err2.is_a?(Hash)
      end
    end
  end
end

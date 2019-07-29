# encoding:utf-8
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

require 'prepare_indices/create_indices'

require 'pry'

module PrepareIndices
  module RotationIndex
    class << self
      # es:
      # node|mention:
      #   rotate: Boolean
      def perform(params:)
        raise(ArgumentError, "Missing ES instatnce") if params[:connect].blank?
        check_params!(params)
        @time = Time.now

        rotate_index(params)
      end

      def rotate_index(params)
        return true unless rotate_index?(params)
        response =
          case params[:every]
            when :month
              rotate_month(params)
            else
              raise(ArgumentError, "Unknown rotate every parameter with '#{params}'")
          end
        response[:status] = response.include?(:error) ? false : true
        response
      end

    private

      def rotate_index?(params)
        params[:rotate]
      end

      def rotate_month(params)
        CreateIndices.perform(params)
      rescue Elasticsearch::Transport::Transport::Errors, StandardError => error
        { error: error.message, backtrace: error.backtrace }
      end

      def check_params!(params)
        if params.blank?
          params = { rotate: false }
          return params
        end
        # raise(ArgumentError, "Missing file '#{params}'") if missing_file?(params)
        # raise(ArgumentError, "Unexists file: '#{params}") unless exist_file?(params)
        # raise(ArgumentError, "Missing base index '#{params}'") if missing_base_index?(params)
        # raise(ArgumentError, "Missing type: '#{params}") if missing_type?(params)
        %i[mappings settings create].each do |key|
          next if params.include?(key)
          params[key] = true
        end
        params[:close]     = false       unless params.include?(:close)
        params[:every]     = :month      unless params.include?(:month)
        params[:aliases]   = true        unless params.include?(:aliases)
        params[:time] = \
          if params.include?(:rotation) && params[:rotation].include?(:time)
            params[:rotation][:time].to_sym
          else
            :next_month
          end
        params[:languages] = (params[:languages_write] || [])
        params[:rotation_check] = \
          params[:rotation] ? params[:rotation][:check].to_sym : false
        params
      end

      def missing_base_index?(params)
        params[:base_index].blank? ? true : false
      end

      def exist_file?(params)
        return false unless File.exist?(params[:file])
        true
      end

      def missing_type?(params)
        return true if params[:type].blank?
        false
      end

      def missing_file?(params)
        return true if params[:file].blank?
        false
      end
    end
  end
end

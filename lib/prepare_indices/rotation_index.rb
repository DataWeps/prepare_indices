# encoding:utf-8
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

module PrepareIndices
  module RotationIndex
    class << self
      # es:
      # node|mention:
      #   rotate: Boolean
      def perform(es:, params:)
        raise(ArgumentError, "Missing ES instatnce") if es.blank?
        check_params!(params)
        @time = Time.now

        rotate_index(es, params)
      end

      def rotate_index(es, params)
        return true unless rotate_index?(params)
        mapping = Requests.load_mappings(
          file: params[:file], index: params[:base_index])
        response =
          case params[:every]
            when :month
              rotate_month(es, params, mapping)
            else
              raise(ArgumentError, "Unknown rotate every parameter with '#{params}'")
          end
        response[:status] = response.include?(:error) ? false : true
        response
      end

    private

      def rotate_month(es, params, mapping)
        next_month = @time.next_month.strftime('%Y%m')
        alias_name = create_alias_name(params[:base_index], next_month)
        raise(StandardError, "exists alias index #{alias_name}") if
          es.indices.exists?(index: alias_name) ||
          es.indices.exists_alias?(name: alias_name)
        index_name = create_index_name(
          params[:base_index], @time.strftime('%Y%m%d%H%M%S'))
        raise(StandardError, "exists index #{index_name}") if
          es.indices.exists?(index: index_name)
        response = create_index(es, index_name, mapping)
        raise(StandardError, "Some strange error during create index #{response}") if
          response['acknowledged'].blank?
        add_month_alias(es, index_name, alias_name)
        raise(StandardError, "Some strange error during adding alias #{response}") if
          response['acknowledged'].blank?
        { ok: true }
      rescue Elasticsearch::Transport::Transport::Errors, StandardError => error
        { error: error.message }
      end

      def add_month_alias(es, index, alias_name)
        es.indices.put_alias(index: index, name: alias_name)
      end

      def create_index(es, index_name, mapping)
        es.indices.create(index: index_name, body: mapping)
      end

      def create_index_name(base, tail)
        "#{base}_#{tail}"
      end

      def create_alias_name(base, tail)
        "#{base}_#{tail}"
      end

      def rotate_index?(params)
        params[:rotate].present? ? true : false
      end

      def check_params!(params)
        if params.blank?
          params = { rotate: false }
          return params
        end
        raise(ArgumentError, "Missing file '#{params}'") if missing_file?(params)
        raise(ArgumentError, "Missing base index '#{params}'") if missing_base_index?(params)
        raise(ArgumentError, "Unexists file: '#{params}") unless exist_file?(params)
        raise(ArgumentError, "Missing type: '#{params}") if missing_type?(params)
        params[:close] = false unless params.include?(:close)
        params[:every] = :month unless params.include?(:month)
        params[:aliases] = :true unless params.include?(:aliases)
        params
      end

      def missing_base_index?(params)
        return true if params[:base_index].blank?
        false
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

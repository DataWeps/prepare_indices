require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

require 'prepare_indices/create_indices'
require 'jobs/common_rotation_job'

module PrepareIndices
  class CloseDeleteIndex
    CLOSE_OLDER_THAN = 2
    DELETE_OLDER_THAN = 6

    class << self
      def perform(params:)
        check_params!(params)
        @time = Time.now

        closed = close_indices_older_than || {}
        deleted = delete_indices_older_than || {}
        closed.merge(deleted)
      end

      private

      def delete_indices_older_than
        return unless delete_older_index?

        indices = find_indices_older_than(:delete)
        return if indices.blank?

        indices.each do |index, _|
          Requests.delete_index(es: client, index: index)
        end
        { status: true, deleted: indices.keys }
      rescue Elasticsearch::Transport::Transport::Errors, StandardError => e
        { error: e.message, backtrace: e.backtrace }
      end

      def close_indices_older_than
        return unless close_older_index?

        indices = find_indices_older_than(:close)
        return if indices.blank?

        indices.each do |index, _|
          Requests.close_index(es: client, index: index, if_close_index: true)
        end
        { status: true, closed: indices.keys }
      rescue Elasticsearch::Transport::Transport::Errors, StandardError => e
        { error: e.message, backtrace: e.backtrace }
      end

      def delete_older_index?
        @params[:delete_older_indices]
      end

      def close_older_index?
        @params[:close_older_indices]
      end

      def include_newer_alias?(type, index)
        regexp_to_check = create_newer_regexp(type)
        (index['aliases'] || []).each do |aliaz|
          return true if aliaz =~ regexp_to_check
        end

        false
      end

      def create_newer_regexp(type)
        now = Time.now.beginning_of_month
        from = compute_date(type)
        regexp = []
        loop do
          break if now <= from

          regexp << "_#{now.strftime('%Y%m')}"
          now = now.months_ago(1)
        end
        /(?:#{regexp.join('|')})\z/
      end

      def find_indices_older_than(type)
        indices = Requests.find_index(es: client, name: compute_name(type))
        indices.delete_if { |_index_name, data| include_newer_alias?(type, data) }
        indices
      end

      def client
        @client ||= Elasticsearch::Client.new(@params[:connect])
      end

      def compute_date(key, older_than = true)
        compute_key = key == :close ? :close_older_than : :delete_older_than
        Time.now.beginning_of_month.months_ago(
          @params[compute_key] + (older_than ? 1 : 0))
      end

      def compute_name(type)
        "#{@params[:index]}_#{compute_date(type).strftime('%Y%m')}"
      end

      def check_params!(params)
        params ||= {}
        params.deep_symbolize_keys!

        raise(ArgumentError, 'Missing ES instance') if params[:connect].blank?

        params[:close_older_indices] = false unless params.include?(:close_older_indices)
        params[:delete_older_indices] = false unless params.include?(:delete_older_indices)
        params[:close_older_than] = CLOSE_OLDER_THAN unless params.include?(:close_older_than)
        params[:delete_older_than] = DELETE_OLDER_THAN unless params.include?(:delete_older_than)
        params[:close_all_older]  = false unless params.include?(:close_all_older)
        @params = params
      end
    end
  end
end

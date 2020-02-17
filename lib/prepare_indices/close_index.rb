# encoding:utf-8
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/time/calculations'

require 'prepare_indices/create_indices'
require 'jobs/common_rotation_job'

module PrepareIndices
  module CloseIndex
    CLOSE_OLDER_THAN = 2

    class << self
      def perform(params:)
        check_params!(params)
        @time = Time.now

        close_indices_older_than
      end

      private

      def close_indices_older_than
        return unless close_older_index?

        indices = find_indices_older_than
        return if indices.blank?

        indices.each do |index, _|
          Requests.close_index(es: client, index: index, if_close_index: true)
        end
        { status: true, response: indices.keys }
      rescue Elasticsearch::Transport::Transport::Errors, StandardError => e
        { error: e.message, backtrace: e.backtrace }
      end

      def close_older_index?
        @params[:close_older_indices]
      end

      def include_newer_alias?(index)
        regexp_to_check = create_newer_regexp
        (index['aliases'] || []).each do |aliaz|
          return true if aliaz =~ regexp_to_check
        end

        false
      end

      def create_newer_regexp
        now = Time.now.beginning_of_month
        from = compute_date
        regexp = []
        loop do
          break if now <= from

          regexp << "_#{now.strftime('%Y%m')}"
          now = now.months_ago(1)
        end
        /(?:#{regexp.join('|')})\z/
      end

      def find_indices_older_than
        indices = Requests.find_index(es: client, name: compute_name)
        indices.delete_if { |_index_name, data| include_newer_alias?(data) }
        indices
      end

      def client
        @client ||= Elasticsearch::Client.new(@params[:connect])
      end

      def compute_date(older_than = true)
        Time.now.beginning_of_month.months_ago(
          @params[:close_older_than] + (older_than ? 1 : 0))
      end

      def compute_name
        "#{@params[:index]}_#{compute_date.strftime('%Y%m')}"
      end

      def check_params!(params)
        params ||= {}
        params.deep_symbolize_keys!

        raise(ArgumentError, 'Missing ES instance') if params[:connect].blank?

        params[:close_older_indices] = false unless params.include?(:close_older_indices)
        params[:close_older_than] = CLOSE_OLDER_THAN unless params.include?(:month)

        @params = params
      end
    end
  end
end

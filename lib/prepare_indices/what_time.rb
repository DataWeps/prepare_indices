module PrepareIndices
  class WhatTime
    class << self
      def what_time(what_time_key)
        time_to_calculate = implicit_time(what_time_key) || Time.now
        time_to_calculate = time_to_calculate.months_since(1) if what_time_key.to_sym == :next_month
        time_to_calculate = time_to_calculate.months_since(2) if what_time_key.to_sym == :next_next_month
        time_to_calculate.strftime('%Y%m')
      end

    private

      def implicit_time(what_time_key)
        Time.parse(what_time_key.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end

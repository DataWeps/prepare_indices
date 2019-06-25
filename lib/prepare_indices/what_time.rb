module PrepareIndices
  class WhatTime
    class << self
      def what_time(what_time_key)
        time_to_calculate = Time.now
        time_to_calculate = time_to_calculate.months_since(1) if what_time_key == :next_month
        time_to_calculate = time_to_calculate.months_since(2) if what_time_key == :next_next_month
        time_to_calculate.strftime('%Y%m')
      end
    end
  end
end
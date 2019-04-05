require 'json'
require 'active_support/core_ext/time/calculations'

module PrepareIndices
  class Mappings
    class << self
      # time: :this_month|:next_month
      def load_mappings(file:, index:, languages: nil, time: :this_month)
        file_data = find_file(file, index, 'base', false)
        raise(ArgumentError, "Index #{index} is not in file") if \
          !file_data.include?(index) ||
          !file_data[index]['mappings']

        build_mappings(
          file_data[index],
          find_languages(index, languages),
          languages,
          time)
      rescue Errno::ENOENT => error
        { errors: true, load_error: error }
      end

    private

      def build_mappings(file_data, language_data, languages, time)
        languages.each_with_object({}) do |language, mem|
          %w[mappings settings aliases].each do |key|
            mem[language] ||= {}
            mem[language][key.to_sym] = build_language(
              file_data,
              language_data[language],
              key,
              language,
              time)
          end
        end
      end

      def build_language(file_data, language_data, key, language, time)
        data = (file_data[key] || {}).deep_merge(language_data[key] || {})
        data = prepare_aliases(data, language, time) if key.to_sym == :aliases
        data
      end

      def prepare_aliases(data, language, time)
        (data || {}).each_with_object({}) do |(alias_name, _), mem|
          alias_name = alias_name.sub("%date%", what_time(time))
          alias_name = alias_name.sub("%language%", language) unless language == 'base'
          mem[alias_name] = {}
        end
      end

      def what_time(time)
        time_to_calculate = Time.now
        time_to_calculate = time.months_since(1) if time == :next_month
        time_to_calculate.strftime('%Y%m')
      end

      def find_languages(index, languages)
        languages.each_with_object({}) do |language, mem|
          mem[language] = find_file(nil, language.to_s, 'languages', true, true)
          mem[language].deep_merge!(
            find_file(nil, "#{index}_#{language}", 'languages', false, false))
        end
      end

      def find_file(file, index, tail = 'base', gem_file = true, required = true)
        return {} if index == 'base'
        file_dir = file ? file : base_file(index, tail, gem_file)
        puts File.expand_path(file_dir).to_s
        JSON.parse(File.read(file_dir))
      rescue Errno::ENOENT => error
        raise(Errno::ENOENT, error.message) if required
        {}
      end

      def base_file(file, tail = 'base', gem_file = true)
        file_dir = gem_file ?  [__dir__, '..', '..'] : ['db']
        File.join(*file_dir, 'mappings', tail, "#{file}.json")
      end

      def default_folder
        'db/mappings'
      end
    end
  end
end

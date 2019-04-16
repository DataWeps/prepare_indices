require 'json'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/object/deep_dup'

module PrepareIndices
  class Mappings
    LANGUAGES = {
      'cs' => { language: 'cs', country: 'czech' },
      'sk' => { language: 'sk', country: 'czech' },
      'pl' => { language: 'pl', country: 'polish' },
      'de' => { language: 'de', country: 'german' },
      'en' => { language: 'en', country: 'english' },
      'es' => { language: 'es', country: 'spanish' },
      'hu' => { language: 'hu', country: 'hungarian' },
      'lt' => { language: 'lt', country: 'lithuanian' },
      'lv' => { language: 'lv', country: 'latvian' },
      'mk' => { language: 'mk', country: 'macedonian' },
      'ru' => { language: 'ru', country: 'russian' },
      'sr' => { language: 'sr', country: 'serbian' } }.freeze

    class << self
      # time: :this_month|:next_month
      def load_mappings(file:, index:, languages: nil, time: :this_month, base_file: true, merge: false)
        base_data = load_base_data(index, base_file)
        file_data = find_file(file, index, 'base', false)
        raise(ArgumentError, "Index #{index} is not in file") if \
          !file_data.include?(index) ||
          !file_data[index]['mappings']

        build_mappings(
          base_data,
          file_data[index],
          find_languages(index, languages),
          languages,
          time,
          merge)
      rescue Errno::ENOENT => error
        { errors: true, load_error: error }
      end

    private

      def load_base_data(index, base_file)
        if base_file
          find_file(
            nil,
            index =~ /articles/ ? 'base_articles' : 'base_mentions',
            'base',
            true,
            false)
        else
          {}
        end
      end

      def build_mappings(base_data, file_data, language_data, languages, time, merge)
        data = languages.each_with_object({}) do |language, mem|
          %w[mappings settings aliases].each do |key|
            mem[language] ||= base_data.deep_dup.symbolize_keys
            mem[language][key.to_sym] ||= {}
            mem[language][key.to_sym].deep_merge!(
              build_language(
                file_data,
                language_data[language],
                key,
                language,
                time))
          end
        end
        merge ? { base: merge_data(data) } : data
      end

      def merge_data(data)
        data.keys.each_with_object({}) do |key, mem|
          mem.deep_merge!(data[key])
        end
      end

      def build_language(file_data, language_data, key, language, time)
        data = (file_data[key] || {}).deep_dup.deep_merge(language_data[key] || {})
        data = prepare_aliases(data, language, time)    if key.to_sym == :aliases
        data = prepare_language_mapping(data, language) if key.to_sym == :mappings
        data
      end

      def prepare_aliases(data, language, time)
        (data || {}).each_with_object({}) do |(alias_name, _), mem|
          alias_name = alias_name.sub("%date%", what_time(time))
          alias_name = \
            if language == 'base'
              nil
            else
              alias_name.sub("%language%", language)
            end
          mem[alias_name] = {} if alias_name
        end
      end

      def prepare_language_mapping(data, language)
        return data if language == 'base'
        data = Oj.dump(data)
        data = data.gsub("%language%", LANGUAGES[language][:language])
        data = data.gsub("%country%", LANGUAGES[language][:country])
        Oj.load(data)
      end

      def what_time(what_time)
        time_to_calculate = Time.now
        time_to_calculate = time_to_calculate.months_since(1) if what_time == :next_month
        time_to_calculate = time_to_calculate.months_since(2) if what_time == :next_next_month
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

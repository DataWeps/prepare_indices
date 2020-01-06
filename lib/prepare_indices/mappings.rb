require 'json'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/object/deep_dup'

require_relative 'prepare_language'

module PrepareIndices
  class Mappings
    class << self
      # time: :this_month|:next_month
      def load_mappings(file:, index:, languages: nil, time: :this_month, base_file: true, merge: false, required: true)
        base_data = load_base_data(index, base_file)
        file_data = find_file(file, index, 'base', false)
        raise(ArgumentError, "Index #{index} is not in file") if \
          !file_data.include?(index) ||
          !file_data[index]['mappings']

        mappings = build_mappings(
          base_data,
          file_data[index],
          find_languages(index, languages, required),
          languages,
          time,
          merge)
        delete_keys!(mappings)
        mappings
      rescue Errno::ENOENT => e
        { errors: true, load_error: e }
      end

    private

      def delete_keys!(mappings)
        mappings.each do |key, value|
          delete_keys!(value)  if value.is_a?(Hash)
          mappings.delete(key) if value.is_a?(String) && value == 'delete'
        end
      end

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
                key))
            PrepareLanguage.prepare!(mem, language, key, time)
          end
        end
        merge ? { base: merge_data(data) } : data
      end

      def merge_data(data)
        data.keys.each_with_object({}) do |key, mem|
          mem.deep_merge!(data[key])
        end
      end

      def build_language(file_data, language_data, key)
        (file_data[key] || {}).deep_dup.deep_merge(language_data[key] || {})
      end

      def find_languages(index, languages, required = true)
        languages.each_with_object({}) do |language, mem|
          mem[language] = find_file(nil, language.to_s, 'languages', true, required)
          mem[language].deep_merge!(
            find_file(nil, "#{index}_#{language}", 'languages', false, false))
        end
      end

      def find_file(file, index, tail = 'base', gem_file = true, required = true)
        return {} if index == 'base'

        file_dir = file || base_file(index, tail, gem_file)
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

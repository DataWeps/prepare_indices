require 'json'

require 'pry'

module PrepareIndices
  class Mappings
    class << self
      def load_mappings(file:, index:, languages: nil)
        file_data = find_file(file, index, 'base')
        raise(ArgumentError, "Index #{index} is not in file") if \
          !file_data.include?(index) ||
          !file_data[index]['mappings']

        language_data = find_languages(languages)
        build_mappings(file_data, language_data, index)

        { mappings: file_data[index]['mappings'],
          settings: file_data[index]['settings'],
          aliases: file_data[index]['aliases'] || {} }
      # rescue Errno::ENOENT => error
      #   { errors: true, load_error: error }
      end

    private

      def find_languages(languages)
        languages.each_with_object({}) do |language, mem|
          mem[language] = find_file(nil, language, 'languages')
        end
      end

      def find_file(file, index, tail = 'base')
        file_dir = file ? file : base_file(index, tail)
        puts File.expand_path(file_dir).to_s
        JSON.parse(File.read(file_dir))
      end

      def base_file(file, tail = 'base')
        File.join(default_folder, tail, "#{file}.json")
      end

      def default_folder
        'db/mappings'
      end
    end
  end
end

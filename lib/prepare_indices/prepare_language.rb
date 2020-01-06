require_relative 'what_time'
require 'oj'

module PrepareIndices
  class PrepareLanguage
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
      'sr' => { language: 'sr', country: 'serbian' },
      'bs' => { language: 'bs', country: 'serbian' },
      'hr' => { language: 'hr', country: 'serbian' } }.freeze

    class << self
      # gsub wildcards with actual language/counry
      def prepare!(data, language, key, time)
        data[language][key.to_sym] =
          prepare_aliases(data[language][key.to_sym], language, time)    if key.to_sym == :aliases
        data[language][key.to_sym] =
          prepare_language_mapping(data[language][key.to_sym], language) if key.to_sym == :mappings
      end

    private

      def prepare_aliases(data, language, time)
        (data || {}).each_with_object({}) do |(alias_name, _), mem|
          alias_name = alias_name.sub("%date%", WhatTime.what_time(time))
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
        data = data.gsub("%language%", LANGUAGES.include?(language) ? LANGUAGES[language][:language] : language)
        data = data.gsub("%country%",  LANGUAGES.include?(language) ? LANGUAGES[language][:country] : language)
        Oj.load(data)
      end
    end
  end
end

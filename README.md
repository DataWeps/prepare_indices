# PrepareIndices

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/prepare_indices`. To experiment with that code, run `bin/console` for an interactive prompt.

This gem has make better work with indices in elasticsearch. It is usefull for creating, deleting, putting mapping, settting or
aliases of indices from file. Gem is divided to 2 modules:
1. Base class, where are running function
2. Requests class with all basic function like create_index, delete_index, put_mappings,...

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prepare_indices'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prepare_indices

## Usage

Main function of gem is start and it take 1 parameter like hash where you define
elasticseach, index, file and action. Params looks like:
```ruby
  params = {
    es: 'object'          # compalsory object of elasticsearch
    file: 'string',       # compalsory path to file with index
    index: 'string',      # compalsory name of index
    type: 'string'        # compalsory name of type
    mappings: 'boolean'    # default false
    settings: 'boolean'    # default false
    aliases: 'boolean'    # default false
    create: 'boolean'     # default false
    delete: 'boolean'     # default false
    }
```
Function you can run by:
```ruby
  PrepareIndices::Base.start(params)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/prepare_indices. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


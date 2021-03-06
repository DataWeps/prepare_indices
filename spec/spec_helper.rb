# encoding:utf-8
$LOAD_PATH << File.join(__dir__, '..', 'lib')
require 'prepare_indices'
require 'pry'

def ini_es(host)
  Elasticsearch::Client.new(host: host, log: true)
end

def params_miss_del
{
  es: 'object',
  file: 'string',
  index: 'string',
  type: 'string',
  mappings: true,
  settings: false,
  aliases: false,
  create: false
}
end

def all_params
{
  es: 'object',
  file: 'string',
  index: 'string',
  type: 'string',
  mappings: true,
  settings: false,
  aliases: false,
  create: false,
  delete: false
}
end

def error_params
{
  file: 'string',
  index: 'string',
  type: 'string',
  mappings: true,
  settings: false,
  aliases: false,
  create: false,
  delete: false
}
end
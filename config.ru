#\ -p 1207 -s mongrel
$: << File.expand_path(__FILE__, '../lib')

require 'ronn'
require 'ronn/server'

# use Rack::Lint

options = {
  :styles  => %w[man toc],
  :organization => "Ronn v#{Ronn::VERSION}"
}
files = Dir['man/*.ronn'] + Dir['test/*.ronn']

run Ronn::Server.new(files, options)

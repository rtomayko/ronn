#!/usr/bin/env ruby
require 'rdiscount'
require 'nokogiri'

# Ron is a humane text format and toolchain for authoring manpages (and
# things that appear as manpages from a distance). Use it to build /
# install standard UNIX roff(7) formatted manpages or to generate
# beautiful HTML manpages.
module Ron
  VERSION = '0.1'

  require 'ron/document'
  require 'ron/roff'

  # Create a new Ron::Document for the given ron file.
  def self.new(filename, &block)
    Document.new(filename, &block)
  end
end

# Ronn is a humane text format and toolchain for authoring manpages (and
# things that appear as manpages from a distance). Use it to build /
# install standard UNIX roff(7) formatted manpages or to generate
# beautiful HTML manpages.
module Ronn
  # Create a new Ronn::Document for the given ronn file. See
  # Ronn::Document.new for usage information.
  def self.new(filename, attributes={}, &block)
    Document.new(filename, attributes, &block)
  end

  # bring REV up to date with: rake rev
  REV = '0.5-91-ga704784'
  VERSION = REV[/(?:[\d.]+)(?:-\d+)?/].tr('-', '.')

  def self.release?
    REV != '' && !REV.include?('-')
  end

  require 'ronn/document'
  require 'ronn/roff'
  autoload :Server, 'ronn/server'
end

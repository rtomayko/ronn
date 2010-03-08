# Ronn is a humane text format and toolchain for authoring manpages (and
# things that appear as manpages from a distance). Use it to build /
# install standard UNIX roff(7) formatted manpages or to generate
# beautiful HTML manpages.
module Ronn
  VERSION = '0.4.1'

  require 'ronn/document'
  require 'ronn/roff'

  # Create a new Ronn::Document for the given ronn file. See
  # Ronn::Document.new for usage information.
  def self.new(filename, attributes={}, &block)
    Document.new(filename, attributes, &block)
  end
end

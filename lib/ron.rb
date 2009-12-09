# Ron is a humane text format and toolchain for authoring manpages (and
# things that appear as manpages from a distance). Use it to build /
# install standard UNIX roff(7) formatted manpages or to generate
# beautiful HTML manpages.
module Ron
  VERSION = '0.3'

  require 'ron/document'
  require 'ron/roff'

  # Create a new Ron::Document for the given ron file. See
  # Ron::Document.new for usage information.
  def self.new(filename, attributes={}, &block)
    Document.new(filename, attributes, &block)
  end
end

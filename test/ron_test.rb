require 'contest'
require 'ron'

class RonTest < Test::Unit::TestCase
  SIMPLE_FILE = "#{File.dirname(__FILE__)}/simple.ron"

  test "creating a Document from a file" do
    doc = Ron::Document.new(SIMPLE_FILE)
    assert_not_nil doc.data
  end
end

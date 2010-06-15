require 'contest'
require 'ronn'

class IndexTest < Test::Unit::TestCase
  setup {
    @paths = %w[section_reference_links underline_spacing_test].
      map { |p| File.expand_path("../#{p}.ronn", __FILE__) }
  }

  test "creating with paths" do
    Ronn::Index.new(@paths)
  end

  test "running over documents" do
    index = Ronn::Index.new(@paths)
    assert_equal 2, index.size
    doc = index.to_a.first
    assert_equal 'section_reference_links', doc.name
    assert_equal '1', doc.section
    doc = index.to_a.last
    assert_equal 'underline_spacing_test', doc.name
    assert_nil doc.section
  end
end

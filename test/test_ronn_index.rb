require 'contest'
require 'ronn'

class IndexTest < Test::Unit::TestCase
  setup do
    @index_path   = File.expand_path('../index.txt', __FILE__)
    @missing_path = File.expand_path('../missing-index.txt', __FILE__)
  end

  def expand_path(path, rel=File.dirname(__FILE__))
    File.expand_path(path, rel)
  end

  test "creating with a non-existant file" do
    index = Ronn::Index.new(@missing_path)
    assert_equal @missing_path, index.path
    assert_equal 0, index.size
    assert index.empty?
  end

  test "creating with an index file and no block" do
    index = Ronn::Index.new(@index_path)
    assert_equal 3, index.size
    assert_equal 2, index.manuals.size

    ref = index.references[0]
    assert_equal 'basic_document(7)', ref.name
    assert_equal 'basic_document.ronn', ref.location
    assert_equal 'basic_document.html', ref.url
    assert_equal expand_path('basic_document.ronn'), ref.path
    assert ref.manual?
    assert ref.ronn?
    assert !ref.remote?

    ref = index.references[1]
    assert_equal 'definition_list_syntax(5)', ref.name
    assert_equal 'definition_list_syntax.ronn', ref.location
    assert_equal 'definition_list_syntax.html', ref.url
    assert_equal expand_path('definition_list_syntax.ronn'), ref.path

    ref = index.references[2]
    assert_equal 'grep(1)', ref.name
    assert_equal 'http://man.cx/grep(1)', ref.url
    assert ref.manual?
    assert ref.remote?
    assert !ref.ronn?
  end

  test "creating with a block reader" do
    index = Ronn::Index.new(@index_path) { "hello(1) hello.1.ronn" }
    assert_equal @index_path, index.path
    assert_equal 1, index.size
    ref = index.first
    assert_equal 'hello(1)',     ref.name
    assert_equal 'hello.1.ronn', ref.location
    assert_equal 'hello.1.html', ref.url
    assert_equal expand_path('hello.1.ronn'), ref.path
  end

  test "adding manual paths" do
    index = Ronn::Index.new(@index_path)
    index << expand_path("angle_bracket_syntax.ronn")
    assert_equal 'angle_bracket_syntax(5)', index.last.name
    assert_equal expand_path('angle_bracket_syntax.ronn'), index.last.path
  end

  test "adding manual paths that are already present" do
    index = Ronn::Index.new(@index_path)
    size = index.size
    index << expand_path("basic_document.ronn")
    assert_equal size, index.size
  end
end

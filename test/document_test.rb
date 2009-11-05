require 'contest'
require 'ron/document'

class DocumentTest < Test::Unit::TestCase
  SIMPLE_FILE = "#{File.dirname(__FILE__)}/simple.ron"
  HELLO_DATA = "# hello(1) -- hello world"

  test "creating with a file" do
    doc = Ron::Document.new(SIMPLE_FILE)
    assert_equal File.read(SIMPLE_FILE), doc.data
  end

  test "creating with a string and a file" do
    doc = Ron::Document.new('hello.1.ron') { HELLO_DATA }
    assert_equal HELLO_DATA, doc.data
  end

  context "Document" do
    setup do
      @doc = Ron::Document.new('hello.1.ron') { HELLO_DATA }
    end

    should "load data" do
      assert_equal HELLO_DATA, @doc.data
    end

    should "extract the name" do
      assert_equal 'hello', @doc.name
    end

    should "extract the section" do
      assert_equal '1', @doc.section
    end
  end
end

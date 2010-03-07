require 'contest'
require 'ron/document'

class DocumentTest < Test::Unit::TestCase
  SIMPLE_FILE = "#{File.dirname(__FILE__)}/basic_document.ron"

  test "new with path" do
    doc = Ron::Document.new(SIMPLE_FILE)
    assert_equal File.read(SIMPLE_FILE), doc.data
  end

  test "new with path and block" do
    doc = Ron::Document.new('hello.1.ron') { "# hello(1) -- hello world" }
    assert_equal "# hello(1) -- hello world", doc.data
  end

  test "new with path and block but missing name section" do
    doc = Ron::Document.new('foo.7.ron') { '' }
    assert_equal 'foo', doc.name
    assert_equal '7', doc.section
  end

  test "new with non conventional path and missing name section" do
    doc = Ron::Document.new('bar.ron') { '' }
    assert_equal 'bar', doc.name
    assert_equal nil, doc.section
    assert_equal "./bar.html", doc.path_for('html')
    assert_equal "./bar", doc.path_for('roff')
    assert_equal "./bar", doc.path_for('')
    assert_equal "./bar", doc.path_for(nil)
  end

  test "new with path and name section mismatch" do
    doc = Ron::Document.new('foo/rick.7.ron') { "# randy(3) -- I'm confused." }
    assert_equal 'randy', doc.name
    assert_equal 'rick', doc.path_name
    assert_equal '3', doc.section
    assert_equal '7', doc.path_section
    assert_equal 'rick.7', doc.basename
    assert_equal 'foo/rick.7.bar', doc.path_for(:bar)
  end

  test "new with no path and a name section" do
    doc = Ron::Document.new { "# brandy(5) -- wootderitis" }
    assert_equal nil, doc.path_name
    assert_equal nil, doc.path_section
    assert_equal 'brandy', doc.name
    assert_equal '5', doc.section
    assert_equal 'brandy.5', doc.basename
    assert_equal 'brandy.5.foo', doc.path_for(:foo)
  end

  context "simple conventionally named document" do
    setup do
      @doc = Ron::Document.new('hello.1.ron') { "# hello(1) -- hello world" }
    end

    should "load data" do
      assert_equal "# hello(1) -- hello world", @doc.data
    end

    should "extract the manual page name from the filename or document" do
      assert_equal 'hello', @doc.name
    end

    should "extract the manual page section from the filename or document" do
      assert_equal '1', @doc.section
    end

    should "convert to an HTML fragment" do
      assert_equal %[<h2 id='NAME'>NAME</h2>\n<p><code>hello</code> -- hello world</p>\n],
        @doc.to_html_fragment
    end

    should "convert to HTML with a layout" do
      assert_match %r{^<!DOCTYPE html.*}m, @doc.to_html
      assert_match %[<h2 id='NAME'>NAME</h2>\n<p><code>hello</code> -- hello world</p>],
        @doc.to_html
    end

    should "construct a path to related documents" do
      assert_equal "./hello.1.html", @doc.path_for(:html)
      assert_equal "./hello.1", @doc.path_for(:roff)
      assert_equal "./hello.1", @doc.path_for('')
      assert_equal "./hello.1", @doc.path_for(nil)
    end
  end
end

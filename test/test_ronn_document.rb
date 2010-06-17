require 'contest'
require 'ronn/document'

class DocumentTest < Test::Unit::TestCase
  SIMPLE_FILE = "#{File.dirname(__FILE__)}/basic_document.ronn"

  def canonicalize(text)
    text.
    gsub(/^ +/, '').
    gsub(/\n/m, '').
    gsub(/ +/, ' ').
    gsub(/"/, "'")
  end

  test "new with path" do
    doc = Ronn::Document.new(SIMPLE_FILE)
    assert_equal File.read(SIMPLE_FILE), doc.data
  end

  test "new with path and block" do
    doc = Ronn::Document.new('hello.1.ronn') { "# hello(1) -- hello world" }
    assert_equal "# hello(1) -- hello world", doc.data
  end

  test "new with path and block but missing name section" do
    doc = Ronn::Document.new('foo.7.ronn') { '' }
    assert_equal 'foo', doc.name
    assert_equal '7', doc.section
  end

  test "new with non conventional path and missing name section" do
    doc = Ronn::Document.new('bar.ronn') { '' }
    assert_equal 'bar', doc.name
    assert_equal nil, doc.section
    assert_equal "./bar.html", doc.path_for('html')
    assert_equal "./bar", doc.path_for('roff')
    assert_equal "./bar", doc.path_for('')
    assert_equal "./bar", doc.path_for(nil)
  end

  test "new with path and name section mismatch" do
    doc = Ronn::Document.new('foo/rick.7.ronn') { "# randy(3) -- I'm confused." }
    assert_equal 'randy', doc.name
    assert_equal 'rick', doc.path_name
    assert_equal '3', doc.section
    assert_equal '7', doc.path_section
    assert_equal 'rick.7', doc.basename
    assert_equal 'foo/rick.7.bar', doc.path_for(:bar)
  end

  test "new with no path and a name section" do
    doc = Ronn::Document.new { "# brandy(5) -- wootderitis" }
    assert_equal nil, doc.path_name
    assert_equal nil, doc.path_section
    assert_equal 'brandy', doc.name
    assert_equal '5', doc.section
    assert_equal 'brandy.5', doc.basename
    assert_equal 'brandy.5.foo', doc.path_for(:foo)
  end

  1.upto(5) do |i|
    dashes = '-' * i

    test "new with no path and #{i} dashes in name" do
      doc = Ronn::Document.new { "# brandy #{dashes} wootderitis" }
      assert_equal 'brandy', doc.name
      assert_equal nil, doc.section
      assert_equal 'wootderitis', doc.tagline
    end

    test "new with no path and a name section and #{i} dashes in name" do
      doc = Ronn::Document.new { "# brandy(5) #{dashes} wootderitis" }
      assert_equal 'brandy', doc.name
      assert_equal '5', doc.section
      assert_equal 'wootderitis', doc.tagline
    end
  end

  context "simple conventionally named document" do
    setup do
      @now = Time.now
      @doc = Ronn::Document.new('hello.1.ronn') { "# hello(1) -- hello world" }
      @doc.date = @now
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

    should "convert to an HTML fragment with no wrap div" do
      assert_equal %[<h2 id='NAME'>NAME</h2><p class='man-name'><code>hello</code> - <span class='man-whatis'>hello world</span></p>],
        canonicalize(@doc.to_html_fragment(wrap=nil))
    end

    should "convert to an HTML fragment with a wrap class" do
      assert_equal %[<div class='pm'><h2 id='NAME'>NAME</h2><p class='man-name'><code>hello</code> - <span class='man-whatis'>hello world</span></p></div>],
        canonicalize(@doc.to_html_fragment(wrap_class='pm'))
    end

    should "convert to HTML with a layout" do
      assert_match %r{^<!DOCTYPE html.*}m, @doc.to_html
      assert_match %[<h2 id='NAME'>NAME</h2><p class='man-name'><code>hello</code> - <span class='man-whatis'>hello world</span></p>],
        canonicalize(@doc.to_html)
    end

    should "construct a path to related documents" do
      assert_equal "./hello.1.html", @doc.path_for(:html)
      assert_equal "./hello.1", @doc.path_for(:roff)
      assert_equal "./hello.1", @doc.path_for('')
      assert_equal "./hello.1", @doc.path_for(nil)
    end

    test "uses default styles" do
      assert_equal %w[man], @doc.styles
    end

    test "converting to a hash" do
      assert_equal({
        "section"      => "1",
        "name"         => "hello",
        "date"         => @now,
        "tagline"      => "hello world",
        "styles"       => ["man"],
        "toc"          => [["NAME", "NAME"]],
        "organization" => nil,
        "manual"       => nil
      }, @doc.to_h)
    end

    test "converting to yaml" do
      require 'yaml'
      assert_equal({
        "section"      => "1",
        "name"         => "hello",
        "date"         => @now,
        "tagline"      => "hello world",
        "styles"       => ["man"],
        "toc"          => [["NAME", "NAME"]],
        "organization" => nil,
        "manual"       => nil
      }, YAML.load(@doc.to_yaml))
    end

    test "converting to json" do
      require 'json'
      assert_equal({
        "section"      => "1",
        "name"         => "hello",
        "date"         => @now.iso8601,
        "tagline"      => "hello world",
        "styles"       => ["man"],
        "toc"          => [["NAME", "NAME"]],
        "organization" => nil,
        "manual"       => nil
      }, JSON.parse(@doc.to_json))
    end
  end

  test 'extracting toc' do
    @doc = Ronn::Document.new(File.expand_path('../markdown_syntax.ronn', __FILE__))
    expected = [
      ["NAME", "NAME"],
      ["SYNOPSIS", "SYNOPSIS"],
      ["DESCRIPTION", "DESCRIPTION"],
      ["BLOCK-ELEMENTS", "BLOCK ELEMENTS"],
      ["SPAN-ELEMENTS", "SPAN ELEMENTS"],
      ["MISCELLANEOUS", "MISCELLANEOUS"],
      ["AUTHOR", "AUTHOR"],
      ["SEE-ALSO", "SEE ALSO"]
    ]
    assert_equal expected, @doc.toc
  end

  test "passing a list of styles" do
    @doc = Ronn::Document.new('hello.1.ronn', :styles => %w[test boom test]) { '' }
    assert_equal %w[man test boom], @doc.styles
  end
end

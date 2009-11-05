require 'contest'

# ron command tests
class RonTest < Test::Unit::TestCase
  testdir = File.dirname(__FILE__)
  bindir = File.dirname(testdir)
  ENV['PATH'] = "#{bindir}:#{ENV['PATH']}"

  SIMPLE_FILE = "#{File.dirname(__FILE__)}/simple.ron"

  test "takes ron text on stdin and produces roff on stdout" do
    output = `echo '# hello(1) -- hello world' | ron`
    lines = output.split("\n")
    assert_equal 7, lines.size
    assert_equal %[.\\" generated with Ron], lines.shift 
    assert_equal %[.\\" http://github.com/rtomayko/ron/], lines.shift
    assert_equal %[.], lines.shift
    assert_equal %[.TH "HELLO" 1 "" "" ""], lines.shift
    assert_equal %[.], lines.shift
    assert_equal %[.SH "NAME"], lines.shift
    assert_equal %[\\fBhello\\fR \\-\\- hello world], lines.shift
    assert_equal 0, lines.size
  end

  test "produces html instead of roff with the --html argument" do
    output = `echo '# hello(1) -- hello world' | ron --html`
    assert_match(/<h2 id="NAME">NAME<\/h2>/, output)
  end
end

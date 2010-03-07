require 'contest'

class RonTest < Test::Unit::TestCase
  testdir = File.dirname(__FILE__)

  # setup PATH so that we execute the right ron command
  bindir = File.dirname(testdir) + "/bin"
  ENV['PATH'] = "#{bindir}:#{ENV['PATH']}"

  # make sure the load path is setup correctly
  libdir = File.expand_path("#{testdir}/../lib")
  $:.unshift(libdir) unless $:.any? { |path| File.expand_path(path) == libdir }
  ENV['RUBYLIB'] = $:.join(':')

  require 'ron'

  test "takes ron text on stdin and produces roff on stdout" do
    output = `echo '# hello(1) -- hello world' | ron --date=2009-11-23`
    lines = output.split("\n")
    assert_equal 7, lines.size
    assert_equal %[.\\" generated with Ron/v#{Ron::VERSION}], lines.shift 
    assert_equal %[.\\" http://github.com/rtomayko/ron/], lines.shift
    assert_equal %[.], lines.shift
    assert_equal %[.TH "HELLO" "1" "November 2009" "" ""], lines.shift
    assert_equal %[.], lines.shift
    assert_equal %[.SH "NAME"], lines.shift
    assert_equal %[\\fBhello\\fR \\-\\- hello world], lines.shift
    assert_equal 0, lines.size
  end

  test "produces html instead of roff with the --html argument" do
    output = `echo '# hello(1) -- hello world' | ron --html`
    assert_match(/<h2 id='NAME'>NAME<\/h2>/, output)
  end

  test "produces html fragment with the --fragment argument" do
    output = `echo '# hello(1) -- hello world' | ron --fragment`
    assert_equal "<h2 id='NAME'>NAME</h2>\n<p><code>hello</code> -- hello world</p>\n",
      output
  end

  # ron -> HTML file based tests
  Dir[testdir + '/*.ron'].each do |source|
    dest = source.sub(/ron$/, 'html')
    next unless File.exist?(dest)
    wrong = dest + '.wrong'
    test File.basename(source, '.ron') + ' HTML' do
      output = `ron --html --fragment #{source}`
      expected = File.read(dest) rescue ''
      if expected != output
        File.open(wrong, 'wb') { |f| f.write(output) }
        diff = `diff -u #{dest} #{wrong} 2>/dev/null`
        flunk diff
      elsif File.exist?(wrong)
        File.unlink(wrong)
      end
    end
  end

  # ron -> roff file based tests
  Dir[testdir + '/*.ron'].each do |source|
    dest = source.sub(/ron$/, 'roff')
    next unless File.exist?(dest)
    wrong = dest + '.wrong'
    test File.basename(source, '.ron') + ' roff' do
      output = `ron #{source}`
      expected = File.read(dest) rescue ''
      if expected != output
        File.open(wrong, 'wb') { |f| f.write(output) }
        diff = `diff -u #{dest} #{wrong} 2>/dev/null`
        flunk diff
      elsif File.exist?(wrong)
        File.unlink(wrong)
      end
    end
  end
end

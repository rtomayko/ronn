require 'contest'

class RonnTest < Test::Unit::TestCase
  testdir = File.dirname(__FILE__)

  # setup PATH so that we execute the right ronn command
  bindir = File.dirname(testdir) + "/bin"
  ENV['PATH'] = "#{bindir}:#{ENV['PATH']}"

  # make sure the load path is setup correctly
  libdir = File.expand_path("#{testdir}/../lib")
  $:.unshift(libdir) unless $:.any? { |path| File.expand_path(path) == libdir }
  ENV['RUBYLIB'] = $:.join(':')

  require 'ronn'

  test "takes ronn text on stdin and produces roff on stdout" do
    output = `echo '# hello(1) -- hello world' | ronn --date=2009-11-23`
    lines = output.split("\n")
    assert_equal 7, lines.size
    assert_equal %[.\\" generated with Ronn/v#{Ronn::version}], lines.shift
    assert_equal %[.\\" http://github.com/rtomayko/ronn/tree/#{Ronn::revision}], lines.shift
    assert_equal %[.], lines.shift
    assert_equal %[.TH "HELLO" "1" "November 2009" "" ""], lines.shift
    assert_equal %[.], lines.shift
    assert_equal %[.SH "NAME"], lines.shift
    assert_equal %[\\fBhello\\fR \\- hello world], lines.shift
    assert_equal 0, lines.size
  end

  def canonicalize(text)
    text.
    gsub(/^ +/, '').
    gsub(/\n/m, '').
    gsub(/ +/, ' ').
    gsub(/"/, "'")
  end

  test "produces html instead of roff with the --html argument" do
    output = `echo '# hello(1) -- hello world' | ronn --html`
    assert_match(/<h2 id='NAME'>NAME<\/h2>/, canonicalize(output))
  end

  test "produces html fragment with the --fragment argument" do
    output = `echo '# hello(1) -- hello world' | ronn --fragment`
    assert_equal [
      "<div class='mp'>",
      "<h2 id='NAME'>NAME</h2>",
      "<p class='man-name'><code>hello</code>",
      " - <span class='man-whatis'>hello world</span>",
      "</p></div>"
    ].join, canonicalize(output)
  end

  test "abbides by the RONN_MANUAL environment variable" do
    output = `echo '# hello(1) -- hello world' | RONN_MANUAL='Some Manual' ronn --html`
    assert_match(/Some Manual/, output)
  end

  test "abbides by the RONN_DATE environment variable" do
    output = `echo '# hello(1) -- hello world' | RONN_DATE=1979-01-01 ronn --html`
    assert_match(/January 1979/, output)
  end

  test "abbides by the RONN_ORGANIZATION environment variable" do
    output = `echo '# hello(1) -- hello world' | RONN_ORGANIZATION='GitHub' ronn --html`
    assert_match(/GitHub/, output)
  end

  # ronn -> HTML file based tests
  Dir[testdir + '/*.ronn'].each do |source|
    dest = source.sub(/ronn$/, 'html')
    next unless File.exist?(dest)
    wrong = dest + '.wrong'
    test File.basename(source, '.ronn') + ' HTML' do
      output = `ronn --pipe --html --fragment #{source}`
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

  # ronn -> roff file based tests
  Dir[testdir + '/*.ronn'].each do |source|
    dest = source.sub(/ronn$/, 'roff')
    next unless File.exist?(dest)
    wrong = dest + '.wrong'
    test File.basename(source, '.ronn') + ' roff' do
      output = `ronn --pipe --roff --date=1979-01-01 #{source}`.
        split("\n", 4).last # remove ronn version comments
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

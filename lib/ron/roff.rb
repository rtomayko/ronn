require 'nokogiri'

module Ron
  class RoffFilter
    # Convert Ron HTML to roff.
    def initialize(html, name, section, tagline, manual=nil, version=nil, date=nil)
      @buf = []
      title_heading name, section, tagline, manual, version, date
      block_filter(Nokogiri::HTML.fragment(html))
      write "\n"
    end

    def to_s
      @buf.join.gsub(/\s+$/, '')
    end

  protected
    def title_heading(name, section, tagline, manual, version, date)
      comment "generated with Ron/v#{Ron::VERSION}"
      comment "http://github.com/rtomayko/ron/"
      macro "TH", %["#{escape(name.upcase)}" "#{section}" "#{date.strftime('%B %Y')}" "#{version}" "#{manual}"]
    end

    def block_filter(node)
      if node.kind_of?(Nokogiri::XML::NodeSet)
        node.each { |ch| block_filter(ch) }
        return
      end

      prev = node.previous_sibling
      prev = prev.previous_sibling until prev.nil? || prev.element?

      case node.name

      # non-element nodes
      when '#document-fragment'
        block_filter(node.children)
      when 'text'
        return if node.text =~ /^\s*$/m
        warn "unexpected text: %p",  node.text

      # headings
      when 'h2'
        macro "SH", quote(escape(node.content))
      when 'h3'
        macro "SS", quote(escape(node.content))

      # paragraphs
      when 'p'
        if prev && %w[dd li].include?(node.parent.name)
          macro "IP"
        elsif prev && !%w[h1 h2 h3].include?(prev.name)
          macro "P"
        end
        inline_filter(node.children)
      when 'pre'
        indent = prev.nil? || !%w[h1 h2 h3].include?(prev.name)
        macro "IP", %w["" 4] if indent
        macro "nf"
        write "\n"
        inline_filter(node.search('code'))
        macro "fi"
        macro "IP", %w["" 0] if indent

      # definition lists
      when 'dl'
        macro "TP"
        block_filter(node.children)
      when 'dt'
        macro "TP" unless prev.nil?
        inline_filter(node.children)
        write "\n"
      when 'dd'
        if node.search('p').any?
          block_filter(node.children)
        else
          inline_filter(node.children)
        end
        write "\n"

      # ordered/unordered lists
      # when 'ol'
      #   macro "IP", '1.'
      #   block_filter(node.children)
      when 'ul'
        block_filter(node.children)
        macro "IP", %w["" 0]
      when 'li'
        case node.parent.name
        when 'ul'
          macro "IP", %w["\(bu" 4]
        end
        if node.search('p', 'ol', 'ul', 'dl', 'div').any?
          block_filter(node.children)
        else
          inline_filter(node.children)
        end
        write "\n"

      else
        warn "unrecognized block tag: %p", node.name
      end
    end

    def inline_filter(node, should_escape=true)
      if node.kind_of?(Nokogiri::XML::NodeSet)
        node.each { |ch| inline_filter(ch, should_escape) }
        return
      end

      prev = node.previous_sibling
      prev = prev.previous_sibling until prev.nil? || prev.element?

      case node.name
      when 'text'
        text = node.content.dup
        text.sub!(/^\n+/m, '') if prev && prev.name == 'br'
        if node.previous_sibling.nil? && node.next_sibling
          text.sub!(/\n+$/m, '')
        else
          text.sub!(/\n+$/m, ' ')
        end
        write should_escape ? escape(text) : text
      when 'code'
        write '\fB'
        inline_filter(node.children, should_escape=false)
        write '\fR'
      when 'b', 'strong', 'kbd', 'samp'
        write '\fB'
        inline_filter(node.children)
        write '\fR'
      when 'var', 'em', 'i', 'u'
        write '\fI'
        inline_filter(node.children)
        write '\fR'
      when 'br'
        macro 'br'
      when 'a'
        write '\fI'
        inline_filter(node.children)
        write '\fR'
      else
        warn "unrecognized inline tag: %p", node.name
      end
    end

    def macro(name, value=nil)
      writeln ".\n.#{[name, value].compact.join(' ')}"
    end

    def escape(text)
      text.
        gsub(/[\\-]/)  { |m| "\\#{m}" }.
        gsub('&nbsp;', ' ').
        gsub('&lt;',   '<').
        gsub('&gt;',   '>').
        gsub('&amp;',  '&')
    end

    def quote(text)
      "\"#{text}\""
    end

    # write text to output buffer
    def write(text)
      @buf << text unless text.nil? || text.empty?
    end

    # write text to output buffer on a new line.
    def writeln(text)
      write "\n" if @buf.last && @buf.last[-1] != ?\n
      write text
      write "\n"
    end

    def comment(text)
      writeln %[.\\" #{text}]
    end

    def warn(text, *args)
      $stderr.puts "warn: #{text}" % args
    end
  end
end

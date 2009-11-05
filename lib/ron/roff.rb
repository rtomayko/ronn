module Ron
  class RoffFilter
    # Convert Ron HTML to roff.
    def initialize(html, name, section, tagline, manual=nil, version=nil, date=Time.now)
      @buf = []
      title_heading name, section, tagline, manual, version, date
      block_filter(Nokogiri::HTML.fragment(html))
      write "\n"
    end

    def to_s
      @buf.join
    end

  protected
    def title_heading(name, section, tagline, manual, version, date)
      comment "generated with Ron"
      comment "http://github.com/rtomayko/ron/"
      macro "TH", %["#{escape(name.upcase)}" #{section} "#{date}" "#{version}" "#{manual}"]
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
        macro "nf"
        inline_filter(node.search('code').children)
        macro "fi"

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

      else
        warn "unrecognized block tag: %p", node.name
      end
    end

    def inline_filter(node)
      if node.kind_of?(Nokogiri::XML::NodeSet)
        node.each { |ch| inline_filter(ch) }
        return
      end

      case node.name
      when 'text'
        write escape(node.to_s.sub(/\n+$/, ' '))
      when 'code', 'b', 'strong'
        write '\fB'
        inline_filter(node.children)
        write '\fR'
      when 'em', 'i', 'u'
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
      text.gsub(/[\\-]/) { |m| "\\#{m}" }
    end

    def quote(text)
      "\"#{text}\""
    end

    # write text to output buffer
    def write(text)
      @buf << text
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

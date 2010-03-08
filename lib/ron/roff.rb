require 'hpricot'

module Ron
  class RoffFilter
    # Convert Ron HTML to roff.
    def initialize(html, name, section, tagline, manual=nil, version=nil, date=nil)
      @buf = []
      title_heading name, section, tagline, manual, version, date
      html = Hpricot(html)
      block_filter(html)
      write "\n"
    end

    def to_s
      @buf.join.gsub(/\s+$/, '')
    end

  protected
    def previous(node)
      if node.respond_to?(:previous)
        prev = node.previous
        prev = prev.previous until prev.nil? || prev.elem?
        prev
      end
    end

    def title_heading(name, section, tagline, manual, version, date)
      comment "generated with Ron/v#{Ron::VERSION}"
      comment "http://github.com/rtomayko/ron/"
      macro "TH", %["#{escape(name.upcase)}" "#{section}" "#{date.strftime('%B %Y')}" "#{version}" "#{manual}"]
    end

    def block_filter(node)
      if node.kind_of?(Array) || node.kind_of?(Hpricot::Elements)
        node.each { |ch| block_filter(ch) }

      elsif node.doc?
        block_filter(node.children)

      elsif node.text?
        return if node.to_html =~ /^\s*$/m
        warn "unexpected text: %p",  node

      elsif node.elem?
        case node.name
        when 'h2'
          macro "SH", quote(escape(node.html))
        when 'h3'
          macro "SS", quote(escape(node.html))

        when 'p'
          prev = previous(node)
          if prev && %w[dd li].include?(node.parent.name)
            macro "IP"
          elsif prev && !%w[h1 h2 h3].include?(prev.name)
            macro "P"
          end
          inline_filter(node.children)

        when 'pre'
          prev = previous(node)
          indent = prev.nil? || !%w[h1 h2 h3].include?(prev.name)
          macro "IP", %w["" 4] if indent
          macro "nf"
          write "\n"
          inline_filter(node.search('code > *'))
          macro "fi"
          macro "IP", %w["" 0] if indent

        when 'dl'
          macro "TP"
          block_filter(node.children)
        when 'dt'
          prev = previous(node)
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
          if node.search('p|ol|ul|dl|div').any?
            block_filter(node.children)
          else
            inline_filter(node.children)
          end
          write "\n"

        else
          warn "unrecognized block tag: %p", node.name
        end

      else
        fail "unexpected node: #{node.inspect}"
      end
    end

    def inline_filter(node)
      if node.kind_of?(Array) || node.kind_of?(Hpricot::Elements)
        node.each { |ch| inline_filter(ch) }

      elsif node.text?
        prev = previous(node)
        text = node.to_html.dup
        text.sub!(/^\n+/m, '') if prev && prev.name == 'br'
        if node.previous.nil? && node.next
          text.sub!(/\n+$/m, '')
        else
          text.sub!(/\n+$/m, ' ')
        end
        write escape(text)

      elsif node.elem?
        case node.name
        when 'code'
          write '\fB'
          inline_filter(node.children)
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

      else
        fail "unexpected node: #{node.inspect}"
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

require 'hpricot'
require 'ronn/utils'

module Ronn
  class RoffFilter
    include Ronn::Utils

    # Convert Ronn HTML to roff.
    def initialize(html, name, section, tagline, manual=nil, version=nil, date=nil)
      @buf = []
      title_heading name, section, tagline, manual, version, date
      doc = Hpricot(html)
      remove_extraneous_elements! doc
      normalize_whitespace! doc
      block_filter doc
      write "\n"
    end

    def to_s
      @buf.join.gsub(/[ \t]+$/, '')
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
      comment "generated with Ronn/v#{Ronn.version}"
      comment "http://github.com/rtomayko/ronn/tree/#{Ronn.revision}"
      return if name.nil?
      macro "TH", %["#{escape(name.upcase)}" "#{section}" "#{date.strftime('%B %Y')}" "#{version}" "#{manual}"]
    end

    def remove_extraneous_elements!(doc)
      doc.traverse_all_element do |node|
        if node.comment? || node.procins? || node.doctype? || node.xmldecl?
          node.parent.children.delete(node)
        end
      end
    end

    def normalize_whitespace!(node)
      case
      when node.kind_of?(Array) || node.kind_of?(Hpricot::Elements)
        node.to_a.dup.each { |ch| normalize_whitespace! ch }
      when node.text?
        preceding, following = node.previous, node.next
        content = node.content.gsub(/[\n ]+/m, ' ')
        if preceding.nil? || block_element?(preceding.name) ||
           preceding.name == 'br'
          content.lstrip!
        end
        if following.nil? || block_element?(following.name) ||
           following.name == 'br'
          content.rstrip!
        end
        if content.empty?
          node.parent.children.delete(node)
        else
          node.content = content
        end
      when node.elem? && node.name == 'pre'
        # stop traversing
      when node.elem? && node.children
        normalize_whitespace! node.children
      when node.elem?
        # element has no children
      when node.doc?
        normalize_whitespace! node.children
      else
        warn "unexpected node during whitespace normalization: %p", node
      end
    end

    def block_filter(node)
      if node.kind_of?(Array) || node.kind_of?(Hpricot::Elements)
        node.each { |ch| block_filter(ch) }

      elsif node.doc?
        block_filter(node.children)

      elsif node.text?
        warn "unexpected text: %p",  node

      elsif node.elem?
        case node.name
        when 'div'
          block_filter(node.children)
        when 'h1'
          # discard
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
          inline_filter(node.children)
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
          if node.at('p')
            block_filter(node.children)
          else
            inline_filter(node.children)
          end
          write "\n"

        when 'ol', 'ul'
          block_filter(node.children)
          macro "IP", %w["" 0]
        when 'li'
          case node.parent.name
          when 'ol'
            macro "IP", %W["#{node.position + 1}." 4]
          when 'ul'
            macro "IP", %w["\(bu" 4]
          end
          if node.at('p|ol|ul|dl|div')
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
      return unless node # is an empty node

      if node.kind_of?(Array) || node.kind_of?(Hpricot::Elements)
        node.each { |ch| inline_filter(ch) }

      elsif node.text?
        text = node.to_html.dup
        write escape(text)

      elsif node.elem?
        case node.name
        when 'span'
          inline_filter(node.children)
        when 'code'
          if child_of?(node, 'pre')
            inline_filter(node.children)
          else
            write '\fB'
            inline_filter(node.children)
            write '\fR'
          end

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
          if node.classes.include?('man-ref')
            inline_filter(node.children)
          elsif node.has_attribute?('data-bare-link')
            write '\fI'
            inline_filter(node.children)
            write '\fR'
          else
            inline_filter(node.children)
            write ' '
            write '\fI'
            write escape(node.attributes['href'])
            write '\fR'
          end
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

    HTML_ROFF_ENTITIES = {
      '&bull;'  => '\(bu',
      '&lt;'    => '<',
      '&gt;'    => '>',
      '&nbsp;'  => '\~',
      '&copy;'  => '\(co',
      '&rdquo;' => '\(rs',
      '&mdash;' => '\(em',
      '&reg;'   => '\(rg',
      '&sec;'   => '\(sc',
      '&ge;'    => '\(>=',
      '&le;'    => '\(<=',
      '&ne;'    => '\(!=',
      '&equiv;' => '\(=='
    }

    def escape(text)
      return text.to_s if text.nil? || text.empty?
      ent = HTML_ROFF_ENTITIES
      text = text.dup
      text.gsub!(/&#x([0-9A-Fa-f]+);/) { $1.to_i(16).chr }  # hex entities
      text.gsub!(/&#(\d+);/) { $1.to_i.chr }                # dec entities
      text.gsub!('\\', '\e')                                # backslash
      text.gsub!(/['.-]/) { |m| "\\#{m}" }                  # control chars
      text.gsub!(/(&[A-Za-z]+;)/) { ent[$1] || $1 }         # named entities
      text.gsub!('&amp;',  '&')                             # amps
      text
    end

    def quote(text)
      "\"#{text.gsub(/"/, '\\"')}\""
    end

    # write text to output buffer
    def write(text)
      return if text.nil? || text.empty?
      # lines cannot start with a '.'. insert zero-width character before.
      if text[0,2] == '\.' &&
        (@buf.last && @buf.last[-1] == ?\n)
        @buf << '\&'
      end
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

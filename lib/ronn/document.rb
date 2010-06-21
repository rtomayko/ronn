require 'time'
require 'cgi'
require 'hpricot'
require 'rdiscount'
require 'ronn/roff'
require 'ronn/template'
require 'ronn/utils'

module Ronn
  # The Document class can be used to load and inspect a ronn document
  # and to convert a ronn document into other formats, like roff or
  # HTML.
  #
  # Ronn files may optionally follow the naming convention:
  # "<name>.<section>.ronn". The <name> and <section> are used in
  # generated documentation unless overridden by the information
  # extracted from the document's name section.
  class Document
    include Ronn::Utils

    # Path to the Ronn document. This may be '-' or nil when the Ronn::Document
    # object is created with a stream.
    attr_reader :path

    # The raw input data, read from path or stream and unmodified.
    attr_reader :data

    # The index used to resolve man and file references.
    attr_accessor :index

    # The man pages name: usually a single word name of
    # a program or filename; displayed along with the section in
    # the left and right portions of the header as well as the bottom
    # right section of the footer.
    attr_accessor :name

    # The man page's section: a string whose first character
    # is numeric; displayed in parenthesis along with the name.
    attr_accessor :section

    # Single sentence description of the thing being described
    # by this man page; displayed in the NAME section.
    attr_accessor :tagline

    # The manual this document belongs to; center displayed in
    # the header.
    attr_accessor :manual

    # The name of the group, organization, or individual responsible
    # for this document; displayed in the left portion of the footer.
    attr_accessor :organization

    # The date the document was published; center displayed in
    # the document footer.
    attr_accessor :date

    # Array of style modules to apply to the document.
    attr_accessor :styles

    # Create a Ronn::Document given a path or with the data returned by
    # calling the block. The document is loaded and preprocessed before
    # the intialize method returns. The attributes hash may contain values
    # for any writeable attributes defined on this class.
    def initialize(path=nil, attributes={}, &block)
      @path = path
      @basename = path.to_s =~ /^-?$/ ? nil : File.basename(path)
      @reader = block ||
        lambda do |f|
          if ['-', nil].include?(f)
            STDIN.read
          else
            File.read(f)
          end
        end
      @data = @reader.call(path)
      @name, @section, @tagline = sniff

      @styles = %w[man]
      @manual, @organization, @date = nil
      @markdown, @input_html, @html = nil
      @index = Ronn::Index[path || '.']
      @index.add_manual(self) if path && name

      attributes.each { |attr_name,value| send("#{attr_name}=", value) }
    end

    # Generate a file basename of the form "<name>.<section>.<type>"
    # for the given file extension. Uses the name and section from
    # the source file path but falls back on the name and section
    # defined in the document.
    def basename(type=nil)
      type = nil if ['', 'roff'].include?(type.to_s)
      [path_name || @name, path_section || @section, type].
      compact.join('.')
    end

    # Construct a path for a file near the source file. Uses the
    # Document#basename method to generate the basename part and
    # appends it to the dirname of the source document.
    def path_for(type=nil)
      if @basename
        File.join(File.dirname(path), basename(type))
      else
        basename(type)
      end
    end

    # Returns the <name> part of the path, or nil when no path is
    # available. This is used as the manual page name when the
    # file contents do not include a name section.
    def path_name
      @basename[/^[^.]+/] if @basename
    end

    # Returns the <section> part of the path, or nil when
    # no path is available.
    def path_section
      $1 if @basename.to_s =~ /\.(\d\w*)\./
    end

    # Returns the manual page name based first on the document's
    # contents and then on the path name.
    def name
      @name || path_name
    end

    # Truthful when the name was extracted from the name section
    # of the document.
    def name?
      !@name.nil?
    end

    # Returns the manual page section based first on the document's
    # contents and then on the path name.
    def section
      @section || path_section
    end

    # True when the section number was extracted from the name
    # section of the document.
    def section?
      !@section.nil?
    end

    # The name used to reference this manual.
    def reference_name
      name + (section && "(#{section})").to_s
    end

    # Truthful when the document started with an h1 but did not follow
    # the "<name>(<sect>) -- <tagline>" convention. We assume this is some kind
    # of custom title.
    def title?
      !name? && tagline
    end

    # The document's title when no name section was defined. When a name section
    # exists, this value is nil.
    def title
      @tagline if !name?
    end

    # The date the man page was published. If not set explicitly,
    # this is the file's modified time or, if no file is given,
    # the current time.
    def date
      return @date if @date
      return File.mtime(path) if File.exist?(path)
      Time.now
    end

    # Retrieve a list of top-level section headings in the document and return
    # as an array of +[id, text]+ tuples, where +id+ is the element's generated
    # id and +text+ is the inner text of the heading element.
    def toc
      @toc ||=
        html.search('h2[@id]').map { |h2| [h2.attributes['id'], h2.inner_text] }
    end
    alias section_heads toc

    # Styles to insert in the generated HTML output. This is a simple Array of
    # string module names or file paths.
    def styles=(styles)
      @styles = (%w[man] + styles).uniq
    end

    # Sniff the document header and extract basic document metadata. Return a
    # tuple of the form: [name, section, description], where missing information
    # is represented by nil and any element may be missing.
    def sniff
      html = Markdown.new(data[0, 512]).to_html
      heading, html = html.split("</h1>\n", 2)
      return [nil, nil, nil] if html.nil?

      case heading
      when /([\w_.\[\]~+=@:-]+)\s*\((\d\w*)\)\s*-+\s*(.*)/
        # name(section) -- description
        [$1, $2, $3]
      when /([\w_.\[\]~+=@:-]+)\s+-+\s+(.*)/
        # name -- description
        [$1, nil, $2]
      else
        # description
        [nil, nil, heading.sub('<h1>', '')]
      end
    end

    # Preprocessed markdown input text.
    def markdown
      @markdown ||= process_markdown!
    end

    # A Hpricot::Document for the manual content fragment.
    def html
      @html ||= process_html!
    end

    # Convert the document to :roff, :html, or :html_fragment and
    # return the result as a string.
    def convert(format)
      send "to_#{format}"
    end

    # Convert the document to roff and return the result as a string.
    def to_roff
      RoffFilter.new(
        to_html_fragment(wrap_class=nil),
        name, section, tagline,
        manual, organization, date
      ).to_s
    end

    # Convert the document to HTML and return the result as a string.
    def to_html
      if layout = ENV['RONN_LAYOUT']
        if !File.exist?(layout_path = File.expand_path(layout))
          warn "warn: can't find #{layout}, using default layout."
          layout_path = nil
        end
      end

      template = Ronn::Template.new(self)
      template.context.push :html => to_html_fragment(wrap_class=nil)
      template.render(layout_path || 'default')
    end

    # Convert the document to HTML and return the result
    # as a string. The HTML does not include <html>, <head>,
    # or <style> tags.
    def to_html_fragment(wrap_class='mp')
      return html.to_s if wrap_class.nil?
      [
        "<div class='#{wrap_class}'>",
        html.to_s,
        "</div>"
      ].join("\n")
    end

    def to_markdown
      markdown
    end

    def to_h
      %w[name section tagline manual organization date styles toc].
      inject({}) { |hash, name| hash[name] = send(name); hash }
    end

    def to_yaml
      require 'yaml'
      to_h.to_yaml
    end

    def to_json
      require 'json'
      to_h.merge('date' => date.iso8601).to_json
    end

  protected
    ##
    # Document Processing

    # Parse the document and extract the name, section, and tagline from its
    # contents. This is called while the object is being initialized.
    def preprocess!
      input_html
      nil
    end

    def input_html
      @input_html ||= strip_heading(Markdown.new(markdown).to_html)
    end

    def strip_heading(html)
      heading, html = html.split("</h1>\n", 2)
      html || heading
    end

    def process_markdown!
      markdown = markdown_filter_heading_anchors(self.data)
      markdown_filter_link_index(markdown)
      markdown_filter_angle_quotes(markdown)
    end

    def process_html!
      @html = Hpricot(input_html)
      html_filter_angle_quotes
      html_filter_definition_lists
      html_filter_inject_name_section
      html_filter_heading_anchors
      html_filter_annotate_bare_links
      html_filter_manual_reference_links
      @html
    end

    ##
    # Filters

    # Appends all index links to the end of the document as Markdown reference
    # links. This lets us use [foo(3)][] syntax to link to index entries.
    def markdown_filter_link_index(markdown)
      return markdown if index.nil? || index.empty?
      markdown << "\n\n"
      index.each { |ref| markdown << "[#{ref.name}]: #{ref.url}\n" }
    end

    # Add [id]: #ANCHOR elements to the markdown source text for all sections.
    # This lets us use the [SECTION-REF][] syntax
    def markdown_filter_heading_anchors(markdown)
      first = true
      markdown.split("\n").grep(/^[#]{2,5} +[\w '-]+[# ]*$/).each do |line|
        markdown << "\n\n" if first
        first = false
        title = line.gsub(/[^\w -]/, '').strip
        anchor = title.gsub(/\W+/, '-').gsub(/(^-+|-+$)/, '')
        markdown << "[#{title}]: ##{anchor} \"#{title}\"\n"
      end
      markdown
    end

    # Convert <WORD> to <var>WORD</var> but only if WORD isn't an HTML tag.
    def markdown_filter_angle_quotes(markdown)
      markdown.gsub(/\<([^:.\/]+?)\>/) do |match|
        contents = $1
        tag, attrs = contents.split(' ', 2)
        if attrs =~ /\/=/ || html_element?(tag.sub(/^\//, '')) ||
           data.include?("</#{tag}>")
          match.to_s
        else
          "<var>#{contents}</var>"
        end
      end
    end

    # Perform angle quote (<THESE>) post filtering.
    def html_filter_angle_quotes
      # convert all angle quote vars nested in code blocks
      # back to the original text
      @html.search('code').search('text()').each do |node|
        next unless node.to_html.include?('var&gt;')
        new =
          node.to_html.
            gsub('&lt;var&gt;', '&lt;').
            gsub("&lt;/var&gt;", '>')
        node.swap(new)
      end
    end

    # Convert special format unordered lists to definition lists.
    def html_filter_definition_lists
      # process all unordered lists depth-first
      @html.search('ul').to_a.reverse.each do |ul|
        items = ul.search('li')
        next if items.any? { |item| item.inner_text.split("\n", 2).first !~ /:$/ }

        ul.name = 'dl'
        items.each do |item|
          if child = item.at('p')
            wrap = '<p></p>'
            container = child
          else
            wrap = '<dd></dd>'
            container = item
          end
          term, definition = container.inner_html.split(":\n", 2)

          dt = item.before("<dt>#{term}</dt>").first
          dt.attributes['class'] = 'flush' if dt.inner_text.length <= 7

          item.name = 'dd'
          container.swap(wrap.sub(/></, ">#{definition}<"))
        end
      end
    end

    def html_filter_inject_name_section
      markup =
        if title?
          "<h1>#{title}</h1>"
        elsif name
          "<h2>NAME</h2>\n" +
          "<p class='man-name'>\n  <code>#{name}</code>" +
          (tagline ? " - <span class='man-whatis'>#{tagline}</span>\n" : "\n") +
          "</p>\n"
        end
      if markup
        if @html.children
          @html.at("*").before(markup)
        else
          @html = Hpricot(markup)
        end
      end
    end

    # Add URL anchors to all HTML heading elements.
    def html_filter_heading_anchors
      @html.search('h2|h3|h4|h5|h6').not('[@id]').each do |heading|
        heading.set_attribute('id', heading.inner_text.gsub(/\W+/, '-'))
      end
    end

    # Add a 'data-bare-link' attribute to hyperlinks
    # whose text labels are the same as their href URLs.
    def html_filter_annotate_bare_links
      @html.search('a[@href]').each do |node|
        href = node.attributes['href']
        text = node.inner_text

        if href == text  ||
           href[0] == ?# ||
           CGI.unescapeHTML(href) == "mailto:#{CGI.unescapeHTML(text)}"
        then
          node.set_attribute('data-bare-link', 'true')
        end
      end
    end

    # Convert text of the form "name(section)" to a hyperlink. The URL is
    # obtaiend from the index.
    def html_filter_manual_reference_links
      return if index.nil?
      @html.search('text()').each do |node|
        next if !node.content.include?(')')
        next if %w[pre code h1 h2 h3].include?(node.parent.name)
        next if child_of?(node, 'a')
        node.swap(
          node.content.gsub(/([0-9A-Za-z_:.+=@~-]+)(\(\d+\w*\))/) {
            name, sect = $1, $2
            if ref = index["#{name}#{sect}"]
              "<a class='man-ref' href='#{ref.url}'>#{name}<span class='s'>#{sect}</span></a>"
            else
              # warn "warn: manual reference not defined: '#{name}#{sect}'"
              "<span class='man-ref'>#{name}<span class='s'>#{sect}</span></span>"
            end
          }
        )
      end
    end
  end
end

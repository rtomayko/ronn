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
      @reader = block || Proc.new { |f| File.read(f) }
      @data = @reader.call(path)

      @styles = %w[man]
      @name, @section, @tagline = nil
      @manual, @organization, @date = nil
      @markdown, @input_html, @html = nil

      preprocess!

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
      !name.nil?
    end

    # Returns the manual page section based first on the document's
    # contents and then on the path name.
    def section
      @section || path_section
    end

    # True when the section number was extracted from the name
    # section of the document.
    def section?
      !section.nil?
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
    def section_heads
      parse_html(to_html_fragment).search('h2[@id]').map do |heading|
        [heading.attributes['id'], heading.inner_text]
      end
    end

    # Styles to insert in the generated HTML output. This is a simple Array of
    # string module names or file paths.
    def styles=(styles)
      @styles = (%w[man] + styles).uniq
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
      template.context.push :html => to_html_fragment
      template.render(layout_path || 'default')
    end

    # Convert the document to HTML and return the result
    # as a string. The HTML does not include <html>, <head>,
    # or <style> tags.
    def to_html_fragment(wrap_class='mp')
      template = Ronn::Template.new(self)
      template.context.push :html => html
      template.render 'fragment'
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
      @input_html ||=
        begin
          @name, @section, @tagline, html =
            extract_name_section_description(Markdown.new(markdown).to_html)
          html
        end
    end

    def process_markdown!
      markdown = markdown_filter_heading_anchors(self.data)
      markdown_filter_angle_quotes(markdown)
    end

    def process_html!
      @html = parse_html(input_html)
      html_filter_angle_quotes
      html_filter_definition_lists
      html_filter_heading_anchors
      html_filter_annotate_bare_links
      @html
    end

    def extract_name_section_description(html)
      heading, html = html.split("</h1>\n", 2)
      return [nil, nil, nil, heading] if html.nil?

      if heading =~ /([\w_.\[\]~+=@:-]+)\s*\((\d\w*)\)\s*-+\s*(.*)/
        [$1, $2, $3, html]
      elsif heading =~ /([\w_.\[\]~+=@:-]+)\s+-+\s+(.*)/
        [$1, nil, $2, html]
      else
        [nil, nil, heading.sub('<h1>', ''), html]
      end
    end

    ##
    # Filters

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

    # Add URL anchors to all HTML heading elements.
    def html_filter_heading_anchors
      @html.search('h1|h2|h3|h4|h5|h6').not('[@id]').each do |heading|
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

  private
    def parse_html(html)
      if html.respond_to?(:doc?) && html.doc?
        html
      else
        Hpricot(html.to_s)
      end
    end
  end
end

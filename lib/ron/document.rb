require 'set'
require 'nokogiri'
require 'rdiscount'
require 'ron/roff'

module Ron
  # The Document class can be used to load and inspect a ron document
  # and to convert a ron document into other formats, like roff or
  # HTML.
  #
  # Ron files may optionally follow the naming convention:
  # "<name>.<section>.ron". The <name> and <section> are used in
  # generated documentation unless overridden by the information
  # extracted from the document's name section.
  class Document
    attr_reader :path, :data, :tagline

    # Create a Ron::Document given a path or with the data returned by
    # calling the block. The document is loaded and preprocessed before
    # intialize returns.
    def initialize(path=nil, &block)
      @path = path
      @basename = path.to_s =~ /^-?$/ ? nil : File.basename(path)
      @reader = block || Proc.new { |f| File.read(f) }
      @data = @reader.call(path)
      @name, @section, @tagline = nil
      @fragment = preprocess
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

    # Returns the manual page section based first on the document's
    # contents and then on the path name.
    def section
      @section || path_section
    end

    # Convert the document to :roff, :html, or :html_fragment and
    # return the result as a string.
    def convert(format)
      send "to_#{format}"
    end

    # Convert the document to roff and return the result as a string.
    def to_roff
      RoffFilter.new(
        to_html_fragment,
        name,
        section,
        tagline
      ).to_s
    end

    # Convert the document to HTML and return the result as a string.
    def to_html
      layout_filter(to_html_fragment)
    end

    # Convert the document to HTML and return the result
    # as a string. The HTML does not include <html>, <head>,
    # or <style> tags.
    def to_html_fragment
      "<h2 id='NAME'>NAME</h2>\n" +
      "<p><code>#{name}</code> -- #{tagline}</p>\n" +
      @fragment.to_s
    end

  protected
    # Parse the document and extract the name, section, and tagline
    # from its contents. This is called while the object is being
    # initialized.
    def preprocess
      [
        :angle_quote_pre_filter,
        :markdown_filter,
        :angle_quote_post_filter,
        :definition_list_filter
      ].inject(data) { |res,filter| send(filter, res) }
    end

    # Apply the standard HTML layout template.
    def layout_filter(html)
      template_file = File.dirname(__FILE__) + "/layout.html"
      template = File.read(template_file)
      eval("%Q{#{template}}", binding, template_file)
    end

    # Convert special format unordered lists to definition lists.
    def definition_list_filter(html)
      doc = parse_html(html)
      # process all unordered lists depth-first
      doc.search('ul').to_a.reverse.each do |ul|
        items = ul.search('li')
        next if items.any? { |item| item.text.split("\n", 2).first !~ /:$/ }

        ul.name = 'dl'
        items.each do |item|
          if item.child.name == 'p'
            wrap = '<p></p>'
            container = item.child
          else
            wrap = '<dd></dd>'
            container = item
          end
          term, definition = container.inner_html.split(":\n", 2)

          dt = item.before("<dt>#{term}</dt>").previous_sibling
          dt['class'] = 'flush' if dt.content.length <= 10

          item.name = 'dd'
          container.swap(wrap.sub(/></, ">#{definition}<"))
        end
      end
      doc
    end

    # Perform angle quote (<THESE>) post filtering.
    def angle_quote_post_filter(html)
      doc = parse_html(html)
      # convert all angle quote vars nested in code blocks
      # back to the original text
      doc.search('code text()').each do |node|
        next unless node.to_s.include?('var&gt;')
        new = node.document.create_text_node(
          node.to_s.
            gsub('&lt;var&gt;', '<').
            gsub("&lt;/var&gt;", '>')
        )
        node.replace(new)
      end

      doc.search('ron-var').each { |node| node.name = 'var' }
      doc
    end

    # Run markdown on the data and extract name, section, and
    # tagline.
    def markdown_filter(data)
      html = Markdown.new(data).to_html
      @tagline, html = html.split("</h1>\n", 2)
      @tagline.sub!('<h1>', '')

      # grab name and section from title
      if @tagline =~ /([\w_:-]+)\((\d\w*)\) -- (.*)/
        @name, @section = $1, $2
        @tagline = $3
      end

      html.to_s
    end

    # Convert all <WORD> to <var>WORD</var> but only if WORD
    # isn't an HTML tag.
    def angle_quote_pre_filter(data)
      data.gsub(/\<(.+?)\>/) do |match|
        contents = $1
        tag, attrs = contents.split(' ', 2)
        if attrs =~ /\/=/ ||
           HTML.include?(tag.sub(/^\//, '')) ||
           data.include?("</#{tag}>")
          match.to_s
        else
          "<var>#{contents}</var>"
        end
      end
    end

    HTML = %w[
      a abbr acronym b bdo big br cite code dfn
      em i img input kbd label q samp select
      small span strong sub sup textarea tt var
      address blockquote div dl fieldset form
      h1 h2 h3 h4 h5 h6 hr noscript ol p pre
      table ul
    ].to_set

  private
    def parse_html(html)
      if html.kind_of?(Nokogiri::HTML::DocumentFragment)
        html
      else
        Nokogiri::HTML.fragment(html.to_s)
      end
    end
  end
end

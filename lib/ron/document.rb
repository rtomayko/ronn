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
    attr_reader :path, :data

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

    # Create a Ron::Document given a path or with the data returned by
    # calling the block. The document is loaded and preprocessed before
    # the intialize method returns. The attributes hash may contain values
    # for any writeable attributes defined on this class.
    def initialize(path=nil, attributes={}, &block)
      @path = path
      @basename = path.to_s =~ /^-?$/ ? nil : File.basename(path)
      @reader = block || Proc.new { |f| File.read(f) }
      @data = @reader.call(path)
      @name, @section, @tagline = nil
      @manual, @organization, @date = nil
      @fragment = preprocess
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
        tagline,
        manual,
        organization,
        date
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
      buf = []
      if name? && section?
        buf << "<h2 id='NAME'>NAME</h2>"
        buf << "<p><code>#{name}</code> -- #{tagline}</p>"
      elsif tagline
        buf << "<h1>#{[name, tagline].compact.join(' -- ')}</h1>"
      end
      buf << @fragment.to_s
      buf.join("\n")
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
          dt['class'] = 'flush' if dt.content.length <= 7

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
      doc
    end

    # Run markdown on the data and extract name, section, and
    # tagline.
    def markdown_filter(data)
      html = Markdown.new(data).to_html
      @tagline, html = html.split("</h1>\n", 2)
      if html.nil?
        html = @tagline
        @tagline = nil
      else
        # grab name and section from title
        @tagline.sub!('<h1>', '')
        if @tagline =~ /([\w_.\[\]~+=@:-]+)\s*\((\d\w*)\)\s*--?\s*(.*)/
          @name = $1
          @section = $2
          @tagline = $3
        elsif @tagline =~ /([\w_.\[\]~+=@:-]+)\s+--\s+(.*)/
          @name = $1
          @tagline = $2
        end
      end

      html.to_s
    end

    # Convert all <WORD> to <var>WORD</var> but only if WORD
    # isn't an HTML tag.
    def angle_quote_pre_filter(data)
      data.gsub(/\<([^:.\/]+?)\>/) do |match|
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

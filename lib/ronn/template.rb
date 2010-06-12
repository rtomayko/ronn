require 'mustache'

module Ronn
  class Template < Mustache
    self.template_path = File.dirname(__FILE__) + '/template'
    self.template_extension = 'html'

    def initialize(document, style_path=ENV['RONN_STYLE'].to_s.split(':'))
      @document = document
      @style_path = style_path + [Template.template_path]
    end

    def render(template='default')
      super partial(template)
    end

    ##
    # Basic document attributes

    def name
      @document.name
    end

    def section
      @document.section
    end

    def tagline
      @document.tagline
    end

    def title
      [page_name, tagline].compact.join(' - ')
    end

    def page_name
      if section
        "#{name}(#{section})"
      else
        name
      end
    end

    def generator
      "Ronn/v#{Ronn::VERSION} (http://github.com/rtomayko/ronn)"
    end

    def manual
      @document.manual
    end

    def organization
      @document.organization
    end

    def date
      @document.date.strftime('%B %Y')
    end

    def html
      @document.to_html_fragment
    end

    ##
    # Section TOCs

    def section_heads
      @document.section_heads.map do |id, text|
        {
          :id   => id,
          :text => text
        }
      end
    end

    ##
    # Styles

    # Array of style module names as given on the command line.
    def styles
      @document.styles
    end

    # All embedded stylesheets.
    def stylesheets
      styles.zip(style_files).map do |style, path|
        fail "style not found: #{style.inspect}" if path.nil?
        inline_stylesheet(path)
      end.join("\n  ")
    end

    attr_accessor :style_path

    # Array of expanded stylesheet file names. If a file cannot be found, the
    # resulting array will include nil elements in positions corresponding to
    # the stylesheets array.
    def style_files
      styles.map do |name|
        next name if name.include?('/')
        style_path.
          reject  { |p| p.strip.empty? }.
          map     { |p| File.join(p, "#{name}.css") }.
          detect  { |file| File.exist?(file) }
      end
    end

    # Array of style names for which no file could be found.
    def missing_styles
      style_files.
        zip(files).
        select { |style, file| file.nil? }.
        map    { |style, file| style }
    end

    ##
    # TEMPLATE CSS LOADING

    def inline_stylesheet(path, media='all')
      data = File.read(path)
      data.gsub!(/([;{]) *\n/m, '\1')  # end-of-line whitespace
      data.gsub!(/([;{]) +/m, '\1')    # coalescing whitespace elsewhere
      data.gsub!(/[; ]+\}/, '}')       # remove superfluous trailing semi-colons
      data.gsub!(%r|/\*.+?\*/|m, '')   # comments
      data.gsub!(/\n{2,}/m, "\n")      # collapse lines
      data.gsub!(/^/, '  ')
      "<style type='text/css' media='#{media}'>\n#{data}  </style>"
    end

    def remote_stylesheet(name, media='all')
      path = File.expand_path("../template/#{name}.css", __FILE__)
      "<link rel='stylesheet' type='text/css' media='#{media}' href='#{path}'>"
    end

    def stylesheet(path, media='all')
      inline_stylesheet(name, media)
    end
  end
end

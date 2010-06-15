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
      super template[0,1] == '/' ? File.read(template) : partial(template)
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
    alias tagline? tagline

    def name_and_section?
      name && section
    end

    def title
      if !name_and_section? && tagline
        tagline
      else
        [page_name, tagline].compact.join(' - ')
      end
    end

    def custom_title?
      !name_and_section? && tagline
    end

    def page_name
      if section
        "#{name}(#{section})"
      else
        name
      end
    end

    def generator
      "Ronn/v#{Ronn.version} (http://github.com/rtomayko/ronn/tree/#{Ronn.revision})"
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

    def wrap_class_name
      'mp'
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

    # Array of stylesheet info hashes.
    def stylesheets
      styles.zip(style_files).map do |name, path|
        base = File.basename(path, '.css')
        fail "style not found: #{style.inspect}" if path.nil?
        {
          :name  => name,
          :path  => path,
          :base  => File.basename(path, '.css'),
          :media => (base =~ /(print|screen)$/) ? $1 : 'all'
        }
      end
    end

    # All embedded stylesheets.
    def stylesheet_tags
      stylesheets.
        map { |style| inline_stylesheet(style[:path], style[:media]) }.
        join("\n  ")
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
      data.gsub!(%r|/\*.+?\*/|m, '')   # comments
      data.gsub!(/([;{,]) *\n/m, '\1') # end-of-line whitespace
      data.gsub!(/\n{2,}/m, "\n")      # collapse lines
      data.gsub!(/[; ]+\}/, '}')       # superfluous trailing semi-colons
      data.gsub!(/([{;,+])[ ]+/, '\1') # whitespace around things
      data.gsub!(/[ \t]+/m, ' ')       # coalescing whitespace elsewhere
      data.gsub!(/^/, '  ')            # indent
      data.strip!
      [
        "<style type='text/css' media='#{media}'>",
        "/* style: #{File.basename(path, '.css')} */",
        data,
        "</style>"
      ].join("\n  ")
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

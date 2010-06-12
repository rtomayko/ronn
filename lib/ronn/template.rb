require 'mustache'

module Ronn
  class Template < Mustache
    self.template_path = File.dirname(__FILE__) + '/template'
    self.template_extension = 'html'

    def initialize(document)
      @document = document
    end

    def render(template='default')
      super partial(template)
    end

    def name
      @document.name
    end

    def section
      @document.section
    end

    def tagline
      @document.tagline
    end

    def page_name
      if section
        "#{name}(#{section})"
      else
        name
      end
    end

    def title
      [page_name, tagline].compact.join(' - ')
    end

    def html
      @document.to_html_fragment
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

    def section_heads
      @document.section_heads.map do |id, text|
        {
          :id   => id,
          :text => text
        }
      end
    end

    ##
    # TEMPLATE CSS LOADING

    def inline_stylesheet(name, media='all')
      path = File.expand_path("../template/#{name}.css", __FILE__)
      data = File.read(path)
      data.gsub!(/([;{]) *\n/m, '\1')
      data.gsub!(/([;{]) +/m, '\1')
      data.gsub!(/[; ]+\}/, '}')
      data.gsub!(/^/, '  ')
      "<style type='text/css' media='#{media}'>\n#{data}  </style>"
    end

    def remote_stylesheet(name, media='all')
      path = File.expand_path("../template/#{name}.css", __FILE__)
      "<link rel='stylesheet' type='text/css' media='#{media}' href='#{path}'>"
    end

    def stylesheet(name, media='all')
      inline_stylesheet(name, media)
    end

    def screen_styles
      stylesheet 'screen'
    end

    def print_styles
      stylesheet 'print', media='print'
    end
  end
end

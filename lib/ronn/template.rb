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
      @document.section_heads.each do |id, text|
        { :id => id, :text => text }
      end
    end
  end
end

require 'cgi'

module Ronn
  module Utils
    HTML = %w[
      a abbr acronym b bdo big br cite code dfn
      em i img input kbd label q samp select
      small span strong sub sup textarea tt var
      address blockquote div dl fieldset form
      h1 h2 h3 h4 h5 h6 hr noscript ol p pre
      table ul
    ].to_set

    HTML_BLOCK = %w[
      address blockquote div dl fieldset form
      h1 h2 h3 h4 h5 h6 hr noscript ol p pre
      table ul
    ].to_set

    HTML_INLINE = HTML - HTML_BLOCK

    def block_element?(name)
      HTML_BLOCK.include?(name)
    end

    def inline_element?(name)
      HTML_INLINE.include?(name)
    end

    def html_element?(name)
      HTML.include?(name)
    end
  end
end

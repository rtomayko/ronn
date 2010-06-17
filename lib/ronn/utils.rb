require 'set'
require 'cgi'

module Ronn
  module Utils

    # All HTML 4 elements and some that are in common use.
    HTML = %w[
      a abbr acronym address applet area b base basefont bdo big blockquote body br
      button caption center cite code col colgroup dd del dfn dir div dl dt em
      fieldset font form frame frameset h1 h2 h3 h4 h5 h6 head hr html i iframe img
      input ins isindex kbd label legend li link map menu meta noframes noscript
      object ol optgroup option p param pre q s samp script select small span strike
      strong style sub sup table tbody td textarea tfoot th thead title tr tt u ul var
    ].to_set

    # Block elements.
    HTML_BLOCK = %w[
      blockquote body colgroup dd div dl dt fieldset form frame frameset
      h1 h2 h3 h4 h5 h6 hr head html iframe li noframes noscript
      object ol optgroup option p param pre script select
      style table tbody td textarea tfoot th thead title tr tt ul
    ].to_set

    # Inline elements
    HTML_INLINE = HTML - HTML_BLOCK

    # Elements that don't have a closing tag.
    HTML_EMPTY  = %w[area base basefont br col hr input link meta].to_set

    def block_element?(name)
      HTML_BLOCK.include?(name)
    end

    def inline_element?(name)
      HTML_INLINE.include?(name)
    end

    def empty_element?(name)
      HTML_EMPTY.include?(name)
    end

    def html_element?(name)
      HTML.include?(name)
    end

    def child_of?(node, tag)
      while node
        return true if node.name && node.name.downcase == tag
        node = node.parent
      end
      false
    end
  end
end

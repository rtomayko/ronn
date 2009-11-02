#!/usr/bin/env ruby
require 'rdiscount'
require 'nokogiri'

class Ron
  attr_reader :filename, :data, :basename, :name, :section, :tagline

  def initialize(filename, &block)
    @filename = filename
    @reader = block || Proc.new { |f| File.read(f) }
    @data = @reader.call(filename)

    @basename = File.basename(filename)
    @name, @section =
      if @basename =~ /(\w+)\.(\d\w*)\.ron/
        [$1, $2]
      else
        [@basename[/\w+/], nil]
      end
  end

  # Construct a path to a file near the input file.
  def path(extension=nil)
    name = "#{@name}.#{section}"
    name = "#{name}.#{extension}" if extension
    File.join(File.dirname(filename), name)
  end

  # Convert the document to HTML and return result
  # as a string.
  def to_html
    layout_filter(to_html_fragment)
  end

  # Convert the document to HTML and return result
  # as a string. The HTML does not include <html>, <head>,
  # or <style> tags.
  def to_html_fragment
    definition_list_filter(markdown_filter(data))
  end

  # Apply the standard HTML layout template.
  def layout_filter(html)
    template_file = File.dirname(__FILE__) + "/ron/layout.html"
    template = File.read(template_file)
    eval("%Q{#{template}}", binding, template_file)
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

    "<h2 id='NAME'>NAME</h2>\n" +
    "<p><code>#{@name}</code> -- #{@tagline}</p>\n" +
    html
  end

  # Convert special format unordered lists to definition lists.
  def definition_list_filter(html)
    doc = Nokogiri::HTML(html)
    doc.xpath('//ul').each do |ul|
      items = ul.xpath('li')
      next if items.any? { |item| item.text.split("\n", 2).first !~ /:$/ }

      ul.name = 'dl'
      items.each do |item|
        if item.child.name == 'p'
          para = item.child
          term, definition = para.inner_html.split(":\n", 2)
          item.before("<dt>#{term}</dt>")
          dt = item.previous_sibling
          dt['class'] = 'flush' if dt.content.length <= 10
          item.name = 'dd'
          para.inner_html = definition
        else
          term, definition = item.inner_html.split(":\n", 2)
          item.before("<dt>#{term}</dt>")
          dt = item.previous_sibling
          dt['class'] = 'flush' if dt.content.length <= 8
          item.name = 'dd'
          item.inner_html = definition
        end
      end
    end
    doc.css('body').inner_html
  end

  # Convert Ron HTML to roff.
  def roff_filter(html)
  end
end

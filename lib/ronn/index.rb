require 'ronn'

module Ronn

  # Maintains a list of links / references to manuals and other resources.
  class Index
    include Enumerable

    attr_reader :path
    attr_reader :attributes
    attr_reader :references

    def initialize(path, attributes={}, &bk)
      @path = path
      @attributes = attributes
      @references = []
      @manuals    = {}

      if block_given?
        read! yield
      elsif exist?
        read! File.read(path)
      end
    end

    # Determine whether the index file exists.
    def exist?
      File.exist?(path)
    end

    # Load index data from a string.
    def read!(data)
      data.each_line do |line|
        line = line.strip.gsub(/\s*#.*$/, '')
        if !line.empty?
          name, url = line.split(/ +/, 2)
          @references << Ronn::Reference.new(self, name, url)
        end
      end
    end

    ##
    # Enumerable and friends

    def each(&bk)
      references.each(&bk)
    end

    def size
      references.size
    end

    def first
      references.first
    end

    def last
      references.last
    end

    def empty?
      references.empty?
    end

    def find_by_name(name)
      references.find { |ref| ref.name == name }
    end

    def find_by_url(url_or_path)
      references.find { |ref| ref.url == url_or_path || ref.path == url_or_path }
    end

    alias [] find_by_name

    def reference(name, path)
      Reference.new(self, name, path)
    end

    def <<(path)
      return self if find_by_url(path)
      @references << \
        if path =~ /\.ronn?$/
          reference(manual(path).reference_name, path)
        else
          reference(File.basename(path), path)
        end
      self
    end

    def manual(path)
      @manuals[File.expand_path(path)] ||= Document.new(path, attributes)
    end

    def manuals
      select { |ref| ref.relative? && ref.ronn? }.
      map    { |ref| manual(ref.path) }
    end

    ##
    # Converting

    def to_text
      map { |ref| [ref.name, ref.url].join(' ') }.join("\n")
    end

    def to_a
      references
    end

    def to_h
      to_a.map { |doc| doc.to_hash }
    end
  end

  # An individual index reference.
  class Reference
    attr_reader :name
    attr_reader :url

    def initialize(index, name, url)
      @index = index
      @name = name
      @url  = url
    end

    def remote?
      url =~ /^(?:https?|mailto):/
    end

    def relative?
      !remote?
    end

    def manual?
      name =~ /\([0-9]\w*\)$/
    end

    def ronn?
      url =~ /\.ronn?$/
    end

    def path
      File.expand_path(url, File.dirname(@index.path)) if relative?
    end
  end
end

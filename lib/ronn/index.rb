require 'ronn'

module Ronn

  # Maintains a list of links / references to manuals and other resources.
  class Index
    include Enumerable

    attr_reader :path
    attr_reader :references

    # Retrieve an Index for <path>, where <path> is a directory or normal
    # file. The index is loaded from the corresponding index.txt file if
    # one exists.
    def self.[](path)
      (@indexes ||= {})[index_path_for_file(path)] ||=
        Index.new(index_path_for_file(path))
    end

    def self.index_path_for_file(file)
      File.expand_path(
        if File.directory?(file)
          File.join(file, 'index.txt')
        else
          File.join(File.dirname(file), 'index.txt')
        end
      )
    end

    def initialize(path, &bk)
      @path = path
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
          @references << reference(name, url)
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

    def [](name)
      references.find { |ref| ref.name == name }
    end

    def reference(name, path)
      Reference.new(self, name, path)
    end

    def <<(path)
      raise ArgumentError, "local paths only" if path =~ /(https?|mailto):/
      return self if any? { |ref| ref.path == File.expand_path(path) }
      relative_path = relative_to_index(path)
      @references << \
        if path =~ /\.ronn?$/
          reference manual(path).reference_name, relative_path
        else
          reference File.basename(path), relative_path
        end
      self
    end

    def add_manual(manual)
      @manuals[File.expand_path(manual.path)] = manual
      self << manual.path
    end

    def manual(path)
      @manuals[File.expand_path(path)] ||= Document.new(path)
    end

    def manuals
      select { |ref| ref.relative? && ref.ronn? }.
      map    { |ref| manual(ref.path) }
    end

    ##
    # Converting

    def to_text
      map { |ref| [ref.name, ref.location].join(' ') }.join("\n")
    end

    def to_a
      references
    end

    def to_h
      to_a.map { |doc| doc.to_hash }
    end

    def relative_to_index(path)
      path = File.expand_path(path)
      index_dir = File.dirname(File.expand_path(self.path))
      path.sub(/^#{index_dir}\//, '')
    end
  end

  # An individual index reference. A reference can point to one of a few types
  # of locations:
  #
  #   - URLs: "http://man.cx/crontab(5)"
  #   - Relative paths to ronn manuals: "crontab.5.ronn"
  #
  # The #url method should be used to obtain the href value for HTML.
  class Reference
    attr_reader :name
    attr_reader :location

    def initialize(index, name, location)
      @index = index
      @name = name
      @location = location
    end

    def manual?
      name =~ /\([0-9]\w*\)$/
    end

    def ronn?
      location =~ /\.ronn?$/
    end

    def remote?
      location =~ /^(?:https?|mailto):/
    end

    def relative?
      !remote?
    end

    def url
      if remote?
        location
      else
        location.chomp('.ronn') + '.html'
      end
    end

    def path
      File.expand_path(location, File.dirname(@index.path)) if relative?
    end
  end
end

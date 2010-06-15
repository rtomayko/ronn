require 'ronn'

module Ronn
  class Index
    include Enumerable

    attr_reader :paths
    attr_reader :attributes

    def initialize(paths=[], attributes={})
      @paths = paths
      @attributes = attributes
      @documents = paths.map { |path| Ronn::Document.new(path, attributes) }
    end

    def each(&bk)
      @documents.each(&bk)
    end

    def size
      @documents.size
    end

    def to_a
      @documents.dup
    end

    def to_hash
      to_a.map { |doc| doc.to_hash }
    end
  end
end

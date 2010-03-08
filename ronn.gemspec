Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'ronn'
  s.version = '0.4'
  s.date = '2010-03-08'

  s.description = "The opposite of roff"
  s.summary     = "The opposite of roff"

  s.authors = ["Ryan Tomayko"]
  s.email = "rtomayko@gmail.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    README.md
    Rakefile
    bin/ron
    bin/ronn
    lib/ronn.rb
    lib/ronn/document.rb
    lib/ronn/layout.html
    lib/ronn/roff.rb
    man/markdown.5
    man/markdown.5.ronn
    man/ronn.1
    man/ronn.1.ronn
    man/ronn.5
    man/ronn.5.ronn
    man/ronn.7
    man/ronn.7.ronn
    ronn.gemspec
    test/angle_bracket_syntax.html
    test/angle_bracket_syntax.ronn
    test/basic_document.html
    test/basic_document.ronn
    test/custom_title_document.html
    test/custom_title_document.ronn
    test/definition_list_syntax.html
    test/definition_list_syntax.ronn
    test/document_test.rb
    test/entity_encoding_test.html
    test/entity_encoding_test.roff
    test/entity_encoding_test.ronn
    test/middle_paragraph.html
    test/middle_paragraph.roff
    test/middle_paragraph.ronn
    test/ronn_test.rb
    test/titleless_document.html
    test/titleless_document.ronn
  ]
  # = MANIFEST =

  s.executables = ['ronn', 'ron']
  s.test_files = s.files.select { |path| path =~ /^test\/.*_test.rb/ }

  s.extra_rdoc_files = %w[COPYING]
  s.add_dependency 'hpricot',    '~> 0.8.2'
  s.add_dependency 'rdiscount',   '~> 1.5.8'
  s.add_development_dependency 'contest', '~> 0.1'

  s.has_rdoc = true
  s.homepage = "http://rtomayko.github.com/ronn/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Ronn"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end

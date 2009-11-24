Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'ron'
  s.version = '0.2'
  s.date = '2009-11-23'

  s.description = "The opposite of roff"
  s.summary     = "The opposite of roff"

  s.authors = ["Ryan Tomayko"]
  s.email = "rtomayko@gmail.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    README
    Rakefile
    bin/ron
    lib/ron.rb
    lib/ron/document.rb
    lib/ron/layout.html
    lib/ron/roff.rb
    man/markdown.5.ron
    man/ron.1.ron
    man/ron.5.ron
    man/ron.7.ron
    ron.gemspec
    test/angle_bracket_syntax.html
    test/angle_bracket_syntax.ron
    test/basic_document.html
    test/basic_document.ron
    test/custom_title_document.html
    test/custom_title_document.ron
    test/definition_list_syntax.html
    test/definition_list_syntax.ron
    test/document_test.rb
    test/ron_test.rb
    test/titleless_document.html
    test/titleless_document.ron
  ]
  # = MANIFEST =

  s.executables = ['ron']
  s.test_files = s.files.select { |path| path =~ /^test\/.*_test.rb/ }

  s.extra_rdoc_files = %w[README COPYING]
  s.add_dependency 'nokogiri',    '~> 1.4'
  s.add_dependency 'rdiscount',   '~> 1.3'
  s.add_development_dependency 'contest', '~> 0.1'

  s.has_rdoc = true
  s.homepage = "http://github.com/rtomayko/ron/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Ron"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end

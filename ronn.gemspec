Gem::Specification.new do |s|
  s.name = 'ronn'
  s.version = '0.7.4'
  s.date = '2017-11-22'

  s.description = "Builds manuals"
  s.summary     = "Builds manuals"
  s.homepage    = "http://kamontat.github.io/ronn"

  s.authors     = ["Ryan Tomayko", "Kamontat Chantrachirathumrong"]
  s.email       = ["rtomayko@gmail.com", "kamontat@hotmail.com"]

  s.licenses    = ["MIT"]

  # = MANIFEST =
  s.files = %w[
    AUTHORS
    CHANGES
    COPYING
    Gemfile
    Gemfile.lock
    INSTALLING
    LICENSE
    README.md
    Rakefile
    bin/ronn
    config.ru
    lib/ronn.rb
    lib/ronn/document.rb
    lib/ronn/index.rb
    lib/ronn/roff.rb
    lib/ronn/server.rb
    lib/ronn/template.rb
    lib/ronn/template/80c.css
    lib/ronn/template/dark.css
    lib/ronn/template/darktoc.css
    lib/ronn/template/default.html
    lib/ronn/template/man.css
    lib/ronn/template/print.css
    lib/ronn/template/screen.css
    lib/ronn/template/toc.css
    lib/ronn/utils.rb
    man/index.html
    man/index.txt
    man/ronn-format.7
    man/ronn-format.7.ronn
    man/ronn.1
    man/ronn.1.ronn
    ronn.gemspec
    test/angle_bracket_syntax.html
    test/angle_bracket_syntax.ronn
    test/backticks.html
    test/backticks.ronn
    test/basic_document.html
    test/basic_document.ronn
    test/contest.rb
    test/custom_title_document.html
    test/custom_title_document.ronn
    test/definition_list_syntax.html
    test/definition_list_syntax.roff
    test/definition_list_syntax.ronn
    test/dots_at_line_start_test.roff
    test/dots_at_line_start_test.ronn
    test/ellipses.roff
    test/ellipses.ronn
    test/entity_encoding_test.html
    test/entity_encoding_test.roff
    test/entity_encoding_test.ronn
    test/index.txt
    test/markdown_syntax.html
    test/markdown_syntax.roff
    test/markdown_syntax.ronn
    test/middle_paragraph.html
    test/middle_paragraph.roff
    test/middle_paragraph.ronn
    test/missing_spaces.roff
    test/missing_spaces.ronn
    test/nested_list_with_code.html
    test/nested_list_with_code.roff
    test/nested_list_with_code.ronn
    test/pre_block_with_quotes.roff
    test/pre_block_with_quotes.ronn
    test/section_reference_links.html
    test/section_reference_links.roff
    test/section_reference_links.ronn
    test/test_ronn.rb
    test/test_ronn_document.rb
    test/test_ronn_index.rb
    test/titleless_document.html
    test/titleless_document.ronn
    test/underline_spacing_test.roff
    test/underline_spacing_test.ronn
  ]
  # = MANIFEST =

  s.executables = ['ronn']
  s.test_files = s.files.select { |path| path =~ /^test\/.*_test.rb/ }

  s.extra_rdoc_files = %w[COPYING AUTHORS]
  s.add_dependency 'hpricot',           '~> 0.8.2'
  s.add_dependency 'rdiscount',         '~> 2.2.0.1'
  s.add_dependency 'mustache',          '~> 1.0.5'
  
  s.add_development_dependency 'rake',         '~> 12.0.0'
  s.add_development_dependency 'test-unit',    '~> 3.2.6'
  s.add_development_dependency 'minitest-ci',  '~> 3.3.0'

  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Ronn"]
  s.require_paths = %w[lib]
  s.rubygems_version = '2.4.0'
end

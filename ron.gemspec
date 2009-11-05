Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'ron'
  s.version = '0.1'
  s.date = '2009-11-04'

  s.description = "The opposite of roff"
  s.summary     = "The opposite of roff"

  s.authors = ["Ryan Tomayko"]
  s.email = "rtomayko@gmail.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    Rakefile
    bin/ron
    lib/ron.rb
    lib/ron/layout.html
    man/ron.1.ron
    man/ron.5.ron
    ron.gemspec
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/.*_test.rb/ }

  s.extra_rdoc_files = %w[LICENSE]
  s.add_dependency 'nokogiri',    '~> 1.4'
  s.add_dependency 'rdiscount',   '~> 1.3'

  s.has_rdoc = true
  s.homepage = "http://github.com/rtomayko/ron/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Ron"]
  s.require_paths = %w[lib]
  s.rubygems_version = '1.1.1'
end

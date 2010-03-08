Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=

  s.name = 'ron'
  s.version = '0.4'
  s.date = '2010-03-08'

  s.description = "ron -- the opposite of roff -- is now known as 'ronn'"

  s.summary     = (<<-TEXT).gsub(/^ {4}/, '')
    IMPORTANT: ron -- the opposite of roff -- is now known as "ronn". Ownership
    of the "ron" gem will be handed over to the Ruby Object Notation (Ron)
    project in the not-too-distant future.

    If you came here looking for "ron" -- the opposite of roff --, see the
    "ronn" gem instead: http://rubygems.org/gems/ronn

    If you came here looking for Ron (Ruby Object Notation), see the "Ron"
    gem instead: http://rubygems.org/gems/Ron
  TEXT

  s.authors = ["Ryan Tomayko"]
  s.email = "rtomayko@gmail.com"
  s.files = %w[ron.gemspec]
  s.executables = []
  s.test_files = []

  s.has_rdoc = true
  s.homepage = "http://rtomayko.github.com/ronn/"
  s.require_paths = ['.']
  s.add_dependency 'ronn', '>= 0.4'

  s.post_install_message = (<<-TEXT).gsub(/^ {4}/, '')
    ==================================================================
    WARNING: ron -- the opposite of roff -- is now known as "ronn"

    The "ronn" gem has automatically been installed. However, in the
    not-too-distant future, the "ron" gem will be owned by the
    Ruby Object Notation <http://github.com/coatl/ron> project. Please
    use the "ronn" gem to install ronn -- the opposite of roff -- from
    this point forward.

    If you meant to install the Ruby Object Notation (Ron) gem,
    uninstall the "ron" and "ronn" gems and install the "Ron" gem:
      gem uninstall ron ronn
      gem install Ron
    ==================================================================
  TEXT
end

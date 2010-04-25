ronn -- the opposite of roff
===========================

## DESCRIPTION

Ronn is a humane text format and toolchain for creating UNIX man
pages, and things that appear as man pages from a distance. Use it
to build and install standard UNIX roff man pages or to generate
nicely formatted HTML manual pages for the web.

The Ronn file format is based on Markdown. In fact, Ronn files are a
compatible subset of Markdown syntax but have a more rigid structure and
extend Markdown in some ways to provide features commonly found in man
pages (e.g., definition lists). The ronn(5) manual page defines the
format in more detail.

## DOCUMENTATION

The `.ronn` files located under the `man/` directory show off a wide
range of ronn capabilities and are the source of Ronn's own documentation.
The source files and generated HTML / roff output files are available
at:

  * [ronn(1)](http://rtomayko.github.com/ronn/ronn.1) -
    build markdown based manual pages at the command line.  
    [source file](http://github.com/rtomayko/ronn/blob/master/man/ronn.1.ronn),
    [roff output](http://github.com/rtomayko/ronn/blob/master/man/ronn.1)

  * [ronn(5)](http://rtomayko.github.com/ronn/ronn.5) -
    humane manual page authoring format syntax reference.  
    [source file](http://github.com/rtomayko/ronn/blob/master/man/ronn.5.ronn),
    [roff output](http://github.com/rtomayko/ronn/blob/master/man/ronn.5)

## INSTALL

Install with Rubygems:

    $ [sudo] gem install ronn
    $ ronn --help

Or, clone the git repository:

    $ git clone git://github.com/rtomayko/ronn.git
    $ PATH=ronn/bin:$PATH
    $ ronn --help

## BASIC USAGE

To generate a roff man page from the included `ronn.5.ronn` file and
open it with man(1):

    $ ronn man/ronn.5.ronn
    roff: man/ronn.5
    html: man/ronn.5.html

    # view the generated roff manpage with man(1):
    $ man man/ronn.5

    # view the generated HTML manpage
    $ open man/ronn.5.html

To generate only a standalone HTML version of the manpage:

    $ ronn --html man/markdown.5.ronn
    html: man/markdown.5.html

To build roff versions of all ronn files in a directory:

    $ ronn --roff man/*.ronn

If you just want to view a ronn file as if it were a man page without building
intermediate files:

    $ ronn -m man/markdown.5.ronn

The [ronn(1)](http://rtomayko.github.com/ronn/ronn.1) manual page includes
comprehensive documentation on `ronn` command line options.

## ABOUT

Some people think UNIX manual pages are a poor and outdated style of
documentation. I disagree:

- Man pages follow a well defined structure that's immediately
  familiar and provides a useful starting point for developers
  documenting new tools, libraries, and formats.

- Man pages get to the point. Because they're written in an inverted
  style, with a SYNOPSIS section followed by additional detail,
  prose and references to other sources of information, man pages
  provide the best of both cheat sheet and reference style
  documentation.

- Man pages have extremely -- unbelievably -- limited text
  formatting capabilities. You get a couple of headings, lists, bold,
  underline and no more. This is a feature.

- Although two levels of section hierarchy are technically
  supported, most man pages use only a single level. Unwieldy
  document hierarchies complicate otherwise good documentation.
  Feynman covered all of physics -- heavenly bodies through QED --
  with only two levels of document hierarchy (_The Feynman Lectures
  on Physics_, 1970).

- Man pages have a simple referencing syntax; e.g., sh(1), fork(2),
  markdown(7). HTML versions can use this to generate links between
  pages.

- The classical terminal man page display is typographically well
  thought out. Big bold section headings, justified monospace text,
  nicely indented paragraphs, intelligently aligned definition
  lists, and an informational header and footer.

Unfortunately, trying to figure out how to create a man page is a
fairly tedious process. The roff/man macro languages are highly
extensible, fractured between multiple dialects, and include a bunch
of device specific stuff that's entirely irrelevant to modern
publishing tools.

Ronn aims to address many of the issues with man page creation while
preserving the things that makes man pages a great form of
documentation.

## COPYING

Ronn is Copyright (C) 2009 [Ryan Tomayko](http://tomayko.com/about)
See the file COPYING for information of licensing and distribution.

## SEE ALSO

[ronn(1)](http://rtomayko.github.com/ronn/ronn.1),
[ronn(5)](http://rtomayko.github.com/ronn/ronn.5),
markdown(5)

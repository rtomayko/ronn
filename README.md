ron -- the opposite of roff
===========================

Ron is a humane text format and toolchain for creating UNIX man
pages, and things that appear as man pages from a distance. Use it
to build and install standard UNIX roff man pages or to generate
nicely formatted HTML manual pages for the web.

The Ron file format is based on Markdown. In fact, Ron files are a
compatible subset of Markdown syntax but have a more rigid structure
and extend Markdown in some ways to provide features commonly found in
man pages (e.g., definition lists). The
[`ron(5)`](http://rtomayko.github.com/ron/ron.5.html) manual page
defines the format in more detail.

## DOCUMENTATION

The `.ron` files located under the [`man/`](./man) directory show
off a wide range of ron capabilities and are the source of Ron's own
documentation. The source files and generated HTML / roff output
files are available at:

  * [ron(1)](http://rtomayko.github.com/ron/ron.1.html) -
    build markdown based manual pages at the command line.  
    [source file](man/ron.1.ron), [roff output](man/ron.1.roff).

  * [ron(5)](http://rtomayko.github.com/ron/ron.5.html) -
    humane manual page authoring format syntax reference.  
    [source file](man/ron.5.ron), [roff output](man/ron.5.roff)

  * [markdown(5)](http://rtomayko.github.com/ron/markdown.5.html) -
    humane text markup syntax (taken from:
    <http://daringfireball.net/projects/markdown/syntax>)  
    [source file](ron/markdown.5.ron), [roff output](man/markdown.5.roff)

## INSTALL

Install with Rubygems:

    $ [sudo] gem install ron
    $ ron --help

Or, clone the git repository:

    $ git clone git://github.com/rtomayko/ron.git
    $ PATH=ron/bin:$PATH
    $ ron --help

## BASIC USAGE

To generate a roff man page from the included
[`markdown.5.ron`](man/markdown.5.ron) file and open it with man(1):

    $ ron -b man/markdown.5.ron
    building: man/markdown.5
    $ man man/markdown.5

To generate a standalone HTML version:

    $ ron -b --html man/markdown.5.ron
    building: man/markdown.5.html
    $ open man/markdown.5.html

To build roff and HTML versions of all ron files:

    $ ron -b --roff --html man/*.ron

If you just want to view a ron file as if it were a man page without
building intermediate files:

    $ ron -m man/markdown.5.ron

The [ron(1)](http://rtomayko.github.com/ron/ron.1.html) manual page
includes comprehensive documentation on `ron` command line options.

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
  markdown(5). HTML versions can use this to generate links between
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

Ron aims to address many of the issues with man page creation while
preserving the things that makes man pages a great form of
documentation.

## COPYING

Ron is Copyright (C) 2009 [Ryan Tomayko](http://tomayko.com/about)  
See the file COPYING for information of licensing and distribution.

## SEE ALSO

ron(1), ron(5), markdown(5)

require 'rake/clean'
require 'date'

task :default => :test

ROOTDIR = File.expand_path('..', __FILE__).sub(/#{Dir.pwd}(?=\/)/, '.')
LIBDIR  = "#{ROOTDIR}/lib"
BINDIR  = "#{ROOTDIR}/bin"

task :environment do
  $LOAD_PATH.unshift ROOTDIR if !$:.include?(ROOTDIR)
  $LOAD_PATH.unshift LIBDIR if !$:.include?(LIBDIR)
  require_library 'hpricot'
  require_library 'rdiscount'
  ENV['RUBYLIB'] = $LOAD_PATH.join(':')
  ENV['PATH'] = "#{BINDIR}:#{ENV['PATH']}"
end

desc 'Run tests'
task :test => :environment do
  $LOAD_PATH.unshift "#{ROOTDIR}/test"
  Dir['test/*_test.rb'].each { |f| require(f) }
end

desc 'Build the manual'
task :man => :environment do
  ENV['RONN_MANUAL']  = 'Ron Manual'
  ENV['RONN_ORGANIZATION'] = 'Ryan Tomayko'
  sh "ronn -w -s toc man/*.ronn"
end

desc 'Start the server'
task :server => :environment do
  if system('type shotgun >/dev/null 2>&1')
    exec "shotgun config.ru"
  else
    require 'ronn/server'
    Ronn::Server.run('man/*.ronn')
  end
end

# PACKAGING ============================================================

require 'rubygems'
$spec = eval(File.read('ronn.gemspec'))

def package(ext='')
  "pkg/ronn-#{$spec.version}" + ext
end

desc 'Build packages'
task :package => %w[.gem .tar.gz].map { |ext| package(ext) }

desc 'Build and install as local gem'
task :install => package('.gem') do
  sh "gem install #{package('.gem')}"
end

directory 'pkg/'
CLOBBER.include('pkg')

file package('.gem') => %w[pkg/ ronn.gemspec] + $spec.files do |f|
  sh "gem build ronn.gemspec"
  mv File.basename(f.name), f.name
end

file package('.tar.gz') => %w[pkg/] + $spec.files do |f|
  sh <<-SH
    git archive --prefix=ronn-#{source_version}/ --format=tar HEAD |
    gzip > #{f.name}
  SH
end

def source_version
  line = File.read('lib/ronn.rb')[/^\s*VERSION = .*/]
  line.match(/.*VERSION = '(.*)'/)[1]
end

file 'ronn.gemspec' => FileList['{lib,test,bin}/**','Rakefile'] do |f|
  # read spec file and split out manifest section
  spec = File.read(f.name)
  head, manifest, tail = spec.split("  # = MANIFEST =\n")
  # replace version and date
  head.sub!(/\.version = '.*'/, ".version = '#{source_version}'")
  head.sub!(/\.date = '.*'/, ".date = '#{Date.today.to_s}'")
  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").
    sort.
    reject{ |file| file =~ /^\./ }.
    reject { |file| file =~ /^doc/ }.
    map{ |file| "    #{file}" }.
    join("\n")
  # piece file back together and write...
  manifest = "  s.files = %w[\n#{files}\n  ]\n"
  spec = [head,manifest,tail].join("  # = MANIFEST =\n")
  File.open(f.name, 'w') { |io| io.write(spec) }
  puts "updated #{f.name}"
end

# Misc ===============================================================

def require_library(name)
  require name
rescue LoadError => boom
  if !defined?(Gem)
    warn "warn: #{boom}. trying again with rubygems."
    require 'rubygems'
    retry
  end
  abort "fatal: the '#{name}' library is required (gem install #{name})"
end

# make .wrong test files right
task :right do
  Dir['test/*.wrong'].each do |file|
    dest = file.sub(/\.wrong$/, '')
    mv file, dest
  end
end

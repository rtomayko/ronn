require 'rake/clean'

task :default => :test

task :environment do
  require_library 'hpricot'
  require_library 'rdiscount'
  ENV['RUBYLIB'] = "#{$:.join(':')}:#{ENV['RUBYLIB']}"
  ENV['PATH'] = "bin:#{ENV['PATH']}"
end

desc 'Run tests'
task :test => :environment do
  require_library 'contest'
  Dir['test/*_test.rb'].each { |test| require test }
end

desc 'Build the manual'
task :man => :environment do
  sh "ronn -br5 --manual='Ronn Manual' --organization='Ryan Tomayko' man/*.ronn"
end

# PACKAGING ============================================================

require 'rubygems/specification'
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

# Gemspec Helpers ====================================================

def source_version
  line = File.read('lib/ronn.rb')[/^\s*VERSION = .*/]
  line.match(/.*VERSION = '(.*)'/)[1]
end

file 'ronn.gemspec' => FileList['{lib,test}/**','Rakefile'] do |f|
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
  abort "fatal: the '#{name}' library is required (gem install #{name})"
end

# make .wrong test files right
task :right do
  Dir['test/*.wrong'].each do |file|
    dest = file.sub(/\.wrong$/, '')
    mv file, dest
  end
end

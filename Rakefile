require 'rake/clean'

task :default => :test

task :environment do
  require_library 'contest'
  require_library 'nokogiri'
  require_library 'rdiscount'
  ENV['RUBYLIB'] = "#{$:.join(':')}:#{ENV['RUBYLIB']}"
  ENV['PATH'] = "bin:#{ENV['PATH']}"
end

desc 'Run tests'
task :test => :environment do
  if ENV['PATH'].split(':').any? { |p| File.executable?("#{p}/turn") }
    sh 'turn -Ilib test/*_test.rb'
  else
    sh 'testrb Ilib test/*_test.rb'
  end
end

desc 'Build the manual'
task :man => :environment do
  sh "ron -br5 --manual='Ron Manual' --organization='Ryan Tomayko' man/*.ron"
end

# PACKAGING ============================================================

require 'rubygems/specification'
$spec = eval(File.read('ron.gemspec'))

def package(ext='')
  "pkg/ron-#{$spec.version}" + ext
end

desc 'Build packages'
task :package => %w[.gem .tar.gz].map { |ext| package(ext) }

desc 'Build and install as local gem'
task :install => package('.gem') do
  sh "gem install #{package('.gem')}"
end

directory 'pkg/'
CLOBBER.include('pkg')

file package('.gem') => %w[pkg/ ron.gemspec] + $spec.files do |f|
  sh "gem build ron.gemspec"
  mv File.basename(f.name), f.name
end

file package('.tar.gz') => %w[pkg/] + $spec.files do |f|
  sh <<-SH
    git archive --prefix=ron-#{source_version}/ --format=tar HEAD |
    gzip > #{f.name}
  SH
end

# Gemspec Helpers ====================================================

def source_version
  line = File.read('lib/ron.rb')[/^\s*VERSION = .*/]
  line.match(/.*VERSION = '(.*)'/)[1]
end

file 'ron.gemspec' => FileList['{lib,test}/**','Rakefile'] do |f|
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

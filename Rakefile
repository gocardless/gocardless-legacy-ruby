require 'yard'
require 'rspec/core/rake_task'

desc "Generate YARD documentation"
YARD::Rake::YardocTask.new do |t|
  files = ['lib/**/*.rb', '-', 'CHANGELOG.md', 'LICENSE']
  t.files = files.reject { |f| f =~ /seed|example/ }
end

desc "Run an IRB session with gocardless pre-loaded"
task :console do
  exec "irb -I lib -r gocardless"
end

desc "Run the specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
end


def generate_changelog(last_version, new_version)
  commits = `git log v#{last_version}.. --oneline`.split("\n")
  msgs = commits.map { |commit| commit.sub(/^[a-f0-9]+/, '-') }
  date = Time.now.strftime("%B %d, %Y")
  "## #{new_version} - #{date}\n\n#{msgs.join("\n")}\n\n\n"
end

def update_changelog(last_version, new_version)
  contents = File.read('CHANGELOG.md')
  if contents =~ /## #{new_version}/
    puts "CHANGELOG already contains v#{new_version}, skipping"
    return false
  end
  changelog = generate_changelog(last_version, new_version)
  File.open('CHANGELOG.md', 'w') { |f| f.write(changelog + contents) }
end

def update_version_file(new_version)
  path = "lib/#{Dir.glob('*.gemspec').first.split('.').first}/version.rb"
  contents = File.read(path)
  contents.sub!(/VERSION\s+=\s+["'][\d\.]+["']/, "VERSION = '#{new_version}'")
  File.open(path, 'w') { |f| f.write(contents) }
end

def bump_version(part)
  last_version = `git tag -l | tail -1`.strip.sub(/^v/, '')
  major, minor, patch = last_version.scan(/\d+/).map(&:to_i)

  case part
  when :major
    major += 1
    minor = patch = 0
  when :minor
    minor += 1
    patch = 0
  when :patch
    patch += 1
  end
  new_version = "#{major}.#{minor}.#{patch}"

  update_changelog(last_version, new_version)
  puts "Updated CHANGELOG"

  update_version_file(new_version)
  puts "Updated version.rb"
end

desc "Update the version, auto-generating the changelog"
namespace :version do
  namespace :bump do
    task :major do
      bump_version :major
    end
    task :minor do
      bump_version :minor
    end
    task :patch do
      bump_version :patch
    end
  end
end


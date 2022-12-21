#!/usr/bin/ruby
# frozen_string_literal: true

require "net/http"
require "rexml/document"

require "./lib/shared"

formula_file = "Formula/maven-snapshot.rb"
last_revision_file = "last-revision.txt"
snapshot_repo_base_url = "https://repository.apache.org/content/groups/snapshots"
apache_maven_path = "org/apache/maven/apache-maven"

def download_xml(url)
  puts "Fetching #{url}"
  response = Net::HTTP.get(URI(url))
  REXML::Document.new(response)
end

def extract_xpath(document, query)
  REXML::XPath.first(document, query)
end

# First, inspect the Maven metadata for org.apache.maven:apache-maven from
dist_metadata = download_xml("#{snapshot_repo_base_url}/#{apache_maven_path}/maven-metadata.xml")

# Extract /metadata/versioning/latest
latest_version = extract_xpath(dist_metadata, "//metadata/versioning/latest/text()")
puts "Latest version is #{latest_version}"

# Second, inspect the Maven metadata for org.apache.maven:apache-maven:<version> from
# https://repository.apache.org/content/groups/snapshots/org/apache/maven/apache-maven/<version>/maven-metadata.xml
version_metadata = download_xml("#{snapshot_repo_base_url}/#{apache_maven_path}/#{latest_version}/maven-metadata.xml")

# Extract /metadata/versioning/snapshotVersions with ./classifier = bin and ./extension = tar.gz
artifacts = extract_xpath(
  version_metadata,
  "/metadata/versioning/snapshotVersions/snapshotVersion[./classifier='bin' and ./extension='tar.gz']"
)

# Find all necessary metadata
new_revision = extract_xpath(artifacts, "./updated/text()")
new_version = extract_xpath(artifacts, "./value/text()")
binary_url = "#{snapshot_repo_base_url}/#{apache_maven_path}/#{latest_version}/apache-maven-#{new_version}-bin.tar.gz"

# Compare with last revision - if not changed, we're done here
last_revision = File.read(last_revision_file)
if new_revision.to_s.to_i <= last_revision.to_i
  puts "Last revision is #{last_revision}, already up to date"
  return
else
  puts "Last revision is #{new_revision}, newer than #{last_revision}"
end


# Compute SHA256 hash
new_hash = calculate_hash(binary_url)

# Update formula
puts "Updating formula"
puts "    version #{new_version}"
puts "    Brew revision #{new_revision}"
puts "    SHA-256 hash #{new_hash}"
update_formula(formula_file, binary_url, new_hash, new_version, new_revision)

puts "Updating last inspected revision: #{new_revision}"
File.delete(last_revision_file) if File.exist?(last_revision_file)
File.open(last_revision_file, "w") do |f|
  f << new_revision
end
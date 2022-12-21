#!/usr/bin/ruby
# frozen_string_literal: true

require "json"
require "digest"
require "net/http"
require "open-uri"

require "./lib/shared.rb"

formula_file = "Formula/maven-snapshot.rb"
last_build_file = "last-build.txt"
jenkins_base_url = "https://ci-maven.apache.org/job/Maven/job/maven-box/job/maven/job/master"

def download_json(url)
  puts "Fetching #{url}"
  response = Net::HTTP.get(URI(url))
  JSON.parse(response)
end

last_build = File.read(last_build_file)

job = download_json("#{jenkins_base_url}/api/json")

if job["lastBuild"]["number"] <= last_build.to_i
  puts "Last build is #{job["lastBuild"]["number"]}, already inspected"
  return
else
  puts "Last build is #{job["lastBuild"]["number"]}, newer than #{last_build.to_i}"
end

current_url = "-1"
current_sha256 = "-1"

File.foreach(formula_file) do |line|
  current_url    = line.match(/\s*url\s*"(.*)"$/)[1]    if line[/url/]
  current_sha256 = line.match(/\s*sha256\s*"(.*)"$/)[1] if line[/sha256/]
end

puts "Existing    URL \"#{current_url}\""
puts "Existing SHA256 \"#{current_sha256}\""

builds = job["builds"]
builds.each do |build|
  build_num = build["number"]
  puts "Inspecting build #{build_num}"
  build_details = download_json("#{jenkins_base_url}/#{build_num}/api/json")
  status = build_details["result"]
  puts "... status is #{status}"

  next unless status == "SUCCESS"

  build_details["artifacts"].each do |artifact|
    file_name = artifact["fileName"]

    next unless file_name.match?(/^apache-maven-\d.*-bin\.tar\.gz$/)

    puts "Artifact #{file_name} found"

    url = "#{jenkins_base_url}/#{build["number"]}/artifact/#{artifact["relativePath"]}"
    puts "Artifact location is #{url}"

    puts "Calculating SHA-256 hash"
    new_hash = calculate_hash(url)

    puts "Determining version"
    new_version = url.gsub(/.*apache-maven-(.*)-bin\.tar\.gz/, "\\1")

    new_revision = build_num.to_i + 328
    puts "Updating formula"
    puts "    version #{new_version}"
    puts "    Jenkins job #{build_num}"
    puts "    Brew revision #{new_revision}"
    puts "    SHA-256 hash #{new_hash}"
    update_formula(formula_file, url, new_hash, new_version, new_revision)

    puts "Updating last inspected build: #{build_num}"
    File.delete(last_build_file) if File.exist?(last_build_file)
    File.open(last_build_file, "w") do |f|
      f << build_num
    end
    break
  end
  break
end

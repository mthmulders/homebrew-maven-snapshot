#!/usr/bin/ruby
# frozen_string_literal: true

require "json"
require "digest"
require "net/http"
require "tempfile"
require "uri"

formula_file = "Formula/maven-snapshot.rb"
last_build_file = "last-build.txt"
jenkins_base_url = "https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master"

def download_json(url)
  puts "Fetching #{url}"
  response = Net::HTTP.get(URI(url))
  JSON.parse(response)
end

def calculate_hash(url)
  temp_file = "temp.tgz"
  puts "Fetching #{url}"
  uri = URI.parse(url)
  host = uri.host.downcase
  Net::HTTP.start(host) do |http|
    resp = http.get(uri.path)
    File.open(temp_file, "wb") do |file|
      file.write(resp.body)
    end
  end
  hash = Digest::SHA256.hexdigest File.read temp_file
  File.delete(temp_file)
  hash
end

def update_formula(formula_file, url, new_hash, new_version)
  Tempfile.open(".#{File.basename(formula_file)}", File.dirname(formula_file)) do |tempfile|
    File.open(formula_file).each do |line|
      tempfile.puts line
        .gsub(/(\s*url\s*)".*"$/, "\\1\"#{url}\"")
        .gsub(/(\s*sha256\s*)".*"$/, "\\1\"#{new_hash}\"")
        .gsub(/(\s*version\s*)".*"$/, "\\1\"#{new_version}\"")
    end
    tempfile.close
    FileUtils.mv tempfile.path, formula_file
  end
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

IO.foreach(formula_file) do |line|
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

    next unless file_name.match?(/^apache-maven-[^wrapper].*-bin\.tar\.gz$/)

    puts "Artifact #{file_name} found"

    url = "#{jenkins_base_url}/#{build["number"]}/artifact/#{artifact["relativePath"]}"
    puts "Artifact location is #{url}"

    puts "Calculating SHA-256 hash"
    new_hash = calculate_hash(url)

    puts "Determining version"
    new_version = url.gsub(/.*apache-maven-(.*)-bin\.tar\.gz/, "\\1")

    puts "Updating formula with version #{new_version}, location #{url} and SHA-256 hash #{new_hash}"
    update_formula(formula_file, url, new_hash, new_version)

    puts "Updating last inspected build: #{build_num}"
    File.delete(last_build_file) if File.exist?(last_build_file)
    File.open(last_build_file, "w") do |f|
      f << build_num
    end
    break
  end
  break
end

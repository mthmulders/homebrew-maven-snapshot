#!/usr/bin/ruby

require 'net/http'
require 'json'
require 'tempfile'

formula_file = "Formula/maven-snapshot.rb"
last_build_file = "last-build.txt"
jenkins_base_url = "https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master"

def download_json(url)
    puts "Fetching #{url}"
    response = Net::HTTP.get(URI(url))
    JSON.parse(response)
end

def update_formula(formula_file, url)
    Tempfile.open(".#{File.basename(formula_file)}", File.dirname(formula_file)) do |tempfile|
      File.open(formula_file).each do |line|
        tempfile.puts line.gsub(/(\s*url\s*)".*"$/, '\1' + "\"#{url}\"")
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
    current_url    = line.match(/\s*url\s*"(.*)"$/)[1] if (line[/url/])
    current_sha256 = line.match(/\s*sha256\s*"(.*)"$/)[1] if (line[/sha256/])
end

puts "Found    URL \"#{current_url}\""
puts "Found SHA256 \"#{current_sha256}\""

builds = job["builds"]
builds.each do |build|
    build_num = build['number']
    puts "Inspecting build #{build_num}"
    build_details = download_json("#{jenkins_base_url}/#{build_num}/api/json")
    
    next unless build_details["result"] == "SUCCESS"
        
    build_details["artifacts"].each do |artifact|
        file_name = artifact["fileName"]
    
        next unless file_name.match?(/^apache-maven-[^wrapper].*-bin\.tar\.gz$/)

        puts "Artifact #{file_name} found"
    
        url = "#{jenkins_base_url}/#{build["number"]}/artifact/#{artifact["relativePath"]}"
        puts "Artifact location is #{url}"

        puts "Updating formula with new URL: #{url}"
        update_formula(formula_file, url)

        puts "Updating last inspected build: #{build_num}"
        File.delete(last_build_file) if File.exist?(last_build_file)
        open(last_build_file, "w") do |f|
            f << build_num
        end
        return
    end
end



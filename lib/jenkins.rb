#!/usr/bin/ruby

require 'net/http'
require 'json'

jenkins_base_url = 'https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master/'
jenkins_builds_url = "#{jenkins_base_url}/api/json"
response = Net::HTTP.get(URI(jenkins_builds_url))
builds = JSON.parse(response)['builds']

builds.each do |build|
    build_num = build['number']
    puts "Inspecting build #{build_num}"
    jenkins_build_url = "#{jenkins_base_url}/#{build_num}/api/json"

    response = Net::HTTP.get(URI(jenkins_build_url))
    build_details = JSON.parse(response)
    build_result = build_details['result']
    if "SUCCESS" == build_result then
        puts "Build #{build['number']} is #{build_result}, inspecting artifacts"
        artifacts = build_details['artifacts']
        artifacts.each do |artifact|
            file_name = artifact['fileName']
            
            if file_name.match(/^apache\-maven\-[^wrapper].*-bin\.tar\.gz$/)
                relative_path = artifact['relativePath']
                artifact_url = "#{jenkins_base_url}/#{build_num}/artifact/#{relative_path}"
                puts "Artifact #{file_name} available at #{artifact_url}"
                return artifact_url
            end
        end
        return
    else
        puts "Skipping build #{build['number']} as it is #{build_result}"
    end
end

return nil

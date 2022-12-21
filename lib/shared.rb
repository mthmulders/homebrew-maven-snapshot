require "digest"
require "net/http"
require "open-uri"

#
# Some shared functions
#

# Calculates the SHA-256 digest of the contents of a remote file.
def calculate_hash(url)
  puts "Fetching #{url}"
  digest = Digest::SHA256.new
  URI.parse(url).open do |tempfile|
    digest.update File.read(tempfile.path)
  end
  digest.hexdigest
end

# Updates a formula with with a new download URL, hash, version and revision.
def update_formula(formula_file, url, new_hash, new_version, new_revision)
  Tempfile.open(".#{File.basename(formula_file)}", File.dirname(formula_file)) do |tempfile|
    File.open(formula_file).each do |line|
      tempfile.puts line
        .gsub(/(\s*url\s*)".*"$/, "\\1\"#{url}\"")
        .gsub(/(\s*sha256\s*)".*"$/, "\\1\"#{new_hash}\"")
        .gsub(/(\s*version\s*)".*"$/, "\\1\"#{new_version}\"")
        .gsub(/(\s*revision\s*)\d*$/, "\\1#{new_revision}")
    end
    tempfile.close
    FileUtils.mv tempfile.path, formula_file
  end
end
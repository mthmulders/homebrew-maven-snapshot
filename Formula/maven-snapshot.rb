class MavenSnapshot < Formula
  desc "Java-based project management (latest snapshot)"
  homepage "https://maven.apache.org/"
  url "https://ci-builds.apache.org/job/Maven/job/maven-box/job/maven/job/master/121/artifact/org/apache/maven/apache-maven/4.0.0-alpha-1-SNAPSHOT/apache-maven-4.0.0-alpha-1-SNAPSHOT-bin.tar.gz"
  version "4.0.0-alpha-1-SNAPSHOT"
  sha256 "a81a21fa91e2b280b414b694ed41c41bd75fc4f6061fb77061d0be13b3f4ea9f"
  license "Apache-2.0"
  revision 121

  depends_on "openjdk"

  conflicts_with "maven", because: "also installs a 'mvn' executable"

  # Copied from the official Maven formula
  def install
    # Remove windows files
    rm_f Dir["bin/*.cmd"]

    # Fix the permissions on the global settings file.
    chmod 0644, "conf/settings.xml"

    libexec.install Dir["*"]

    # Leave conf file in libexec. The mvn symlink will be resolved and the conf
    # file will be found relative to it
    Pathname.glob("#{libexec}/bin/*") do |file|
      next if file.directory?

      basename = file.basename
      next if basename.to_s == "m2.conf"

      (bin/basename).write_env_script file, Language::Java.overridable_java_home_env
    end
  end

  # Copied from the official Maven formula
  test do
    (testpath/"pom.xml").write <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <project xmlns="https://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="https://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>org.homebrew</groupId>
        <artifactId>maven-test</artifactId>
        <version>1.0.0-SNAPSHOT</version>
        <properties>
          <maven.compiler.source>1.8</maven.compiler.source>
          <maven.compiler.target>1.8</maven.compiler.target>
          <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        </properties>
      </project>
    EOS
    (testpath/"src/main/java/org/homebrew/MavenTest.java").write <<~EOS
      package org.homebrew;
      public class MavenTest {
        public static void main(String[] args) {
          System.out.println("Testing Maven with Homebrew!");
        }
      }
    EOS
    system "#{bin}/mvn", "compile", "-Duser.home=#{testpath}"
  end
end

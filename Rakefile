# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"

require_relative "lib/qpdf_binary/version"
require_relative "lib/qpdf_binary/platform"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  t.warning = false
end

RuboCop::RakeTask.new

desc "Build the static qpdf binaries with Docker (ARCH=x86_64 for just one)"
task :binaries do
  sh "bin/build-binaries", *ENV.fetch("ARCH", "").split(/[\s,]+/).reject(&:empty?)
end

namespace :binaries do
  desc "Fail unless libexec/ holds a binary for every supported platform"
  task :check do
    missing = QpdfBinary::Platform::SUPPORTED.reject do |platform|
      File.file?(File.join(__dir__, "libexec", "qpdf-#{platform}.gz"))
    end
    unless missing.empty?
      abort "libexec/ is missing binaries for: #{missing.join(", ")}. " \
            "Run `rake binaries` (or download the CI artifacts) before packaging."
    end
    puts "libexec/ has binaries for #{QpdfBinary::Platform::SUPPORTED.join(", ")}"
  end
end

# A gem without its binaries installs fine and then fails at first use, so
# never package one. `gem build` alone skips this check; `rake build` and
# `rake release` (which the release workflow runs) do not.
Rake::Task["build"].enhance(["binaries:check"])

task default: %i[test rubocop]

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/vendor/"
end

require "fileutils"
require "tmpdir"
require "zlib"
require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require "qpdf_binary"

module TestHelpers
  ROOT = File.expand_path("..", __dir__)

  # A shell script that stands in for qpdf: it prints its arguments, one per
  # line, so tests can see exactly what reached the binary.
  FAKE_QPDF = <<~SH
    #!/bin/sh
    for arg in "$@"; do printf '%s\\n' "$arg"; done
  SH

  def write_gzip(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    Zlib::GzipWriter.open(path) { |gz| gz.write(content) }
    path
  end

  # Runs the block with the given environment variables set (nil unsets),
  # restoring the previous values afterwards.
  def with_env(vars)
    saved = vars.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| ENV[key] = value }
  end

  def real_binary_available?
    File.file?(QpdfBinary.archive_path)
  rescue QpdfBinary::UnsupportedPlatformError
    false
  end
end

module Minitest
  class Test
    include TestHelpers
  end
end

# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "zlib"

module QpdfBinary
  # Decompresses a gzipped executable into the first writable directory.
  #
  # This is the technique the wkhtmltopdf-binary gem uses: ship compressed
  # binaries, and inflate the one for the running platform on first use. Two
  # changes make it safer to run in production:
  #
  # * The binary is written to a temporary file and renamed into place, so a
  #   second process starting at the same moment never executes a half-written
  #   file.
  # * When the gem directory is read-only (gems installed by root, read-only
  #   container images), extraction moves on to the next candidate directory
  #   instead of failing.
  class Extractor
    # @param archive [String] path to the gzipped executable
    # @param dirs [Array<String>] directories to extract into, most preferred first
    def initialize(archive, dirs)
      @archive = archive
      @dirs = dirs
      @name = File.basename(archive, ".gz")
    end

    # @return [String] path to the executable, extracting it if no candidate
    #   directory already holds one
    # @raise [MissingBinaryError] if nothing is extracted yet and the archive does not exist
    # @raise [ExtractionError] if every candidate directory fails
    def extract
      existing = @dirs.map { |dir| target_in(dir) }.find { |path| usable?(path) }
      return existing if existing

      unless File.file?(@archive)
        raise MissingBinaryError,
              "#{@archive} is missing. This copy of qpdf-binary was packaged without a binary for " \
              "this platform; if you built it from source, run `rake binaries` before `rake build`."
      end

      failures = []
      @dirs.each do |dir|
        return write_into(dir)
      rescue SystemCallError, IOError, Zlib::Error => e
        failures << "  #{dir}: #{e.message}"
      end

      raise ExtractionError, "could not extract #{@archive} into any of:\n#{failures.join("\n")}"
    end

    private

    def target_in(dir)
      File.join(dir, @name)
    end

    def usable?(path)
      File.file?(path) && File.executable?(path)
    end

    def write_into(dir)
      FileUtils.mkdir_p(dir)
      target = target_in(dir)
      temp = "#{target}.#{Process.pid}.#{SecureRandom.hex(4)}.tmp"

      begin
        Zlib::GzipReader.open(@archive) do |gz|
          File.open(temp, File::WRONLY | File::CREAT | File::EXCL, 0o700) { |out| IO.copy_stream(gz, out) }
        end
        File.chmod(0o755, temp)
        File.rename(temp, target)
      ensure
        FileUtils.rm_f(temp)
      end

      target
    end
  end
end

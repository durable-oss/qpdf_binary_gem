# frozen_string_literal: true

require "qpdf_binary/version"
require "qpdf_binary/errors"
require "qpdf_binary/platform"
require "qpdf_binary/extractor"

# Ships a statically linked qpdf executable inside a Ruby gem.
#
# The gem carries one gzipped binary per supported platform in +libexec/+.
# The first time qpdf is needed, the binary for the running platform is
# decompressed next to its archive, or into a per-user cache directory when
# the gem directory is read-only, and that copy is reused from then on.
#
# @example Run qpdf from Ruby
#   system(QpdfBinary.path, "--check", "invoice.pdf", exception: true)
#
# @example Capture qpdf's output
#   stdout, stderr, status = Open3.capture3(QpdfBinary.path, "--show-npages", "invoice.pdf")
module QpdfBinary
  # Directory holding the gzipped binaries.
  LIBEXEC_DIR = File.expand_path("../libexec", __dir__)

  class << self
    # Returns the path to a qpdf executable for this platform, decompressing
    # it on first use.
    #
    # @return [String] absolute path to an executable qpdf binary
    # @raise [UnsupportedPlatformError] if no build exists for this platform
    # @raise [MissingBinaryError] if the gem was packaged without this platform's binary
    # @raise [ExtractionError] if no candidate directory could be written to
    def path
      @path ||= Extractor.new(archive_path, extraction_dirs).extract
    end

    # @return [String] the identifier of the running platform, such as "linux-x86_64"
    # @raise [UnsupportedPlatformError] if no build exists for this platform
    def platform
      Platform.current
    end

    # @param platform [String] a platform identifier from {Platform::SUPPORTED}
    # @return [String] path to that platform's gzipped binary
    def archive_path(platform = self.platform)
      File.join(LIBEXEC_DIR, "qpdf-#{platform}.gz")
    end

    # Directories tried, in order, when the binary has to be decompressed.
    #
    # +QPDF_BINARY_CACHE_DIR+ comes first when set, which suits deployments
    # whose gem directory and home directory are both read-only. The gem's own
    # +libexec/+ is next, as in the wkhtmltopdf-binary gem, followed by a
    # per-user cache under +XDG_CACHE_HOME+ (or +~/.cache+). Cache directories
    # get a per-version subdirectory, so upgrading the gem never reuses an
    # older qpdf.
    #
    # @return [Array<String>]
    def extraction_dirs
      dirs = []
      override = ENV.fetch("QPDF_BINARY_CACHE_DIR", "")
      dirs << File.join(File.expand_path(override), VERSION) unless override.empty?
      dirs << LIBEXEC_DIR
      user_cache = user_cache_dir
      dirs << File.join(user_cache, "qpdf-binary", VERSION) if user_cache
      dirs
    end

    # Forgets the memoized path. Intended for tests.
    #
    # @return [void]
    def reset!
      @path = nil
    end

    private

    # Never falls back to a shared temporary directory: another local user
    # could plant an executable there before this process writes its own.
    def user_cache_dir
      xdg = ENV.fetch("XDG_CACHE_HOME", "")
      return xdg unless xdg.empty?

      File.join(Dir.home, ".cache")
    rescue ArgumentError
      # Dir.home raises when HOME is unset and the user has no passwd entry.
      nil
    end
  end
end

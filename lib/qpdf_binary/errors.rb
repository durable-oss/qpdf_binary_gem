# frozen_string_literal: true

module QpdfBinary
  # Base class for every error this gem raises.
  class Error < StandardError; end

  # Raised when the running OS or CPU has no static qpdf build.
  class UnsupportedPlatformError < Error; end

  # Raised when the installed gem lacks the binary for a supported platform,
  # which happens when it was built from a git checkout without running
  # `rake binaries` first.
  class MissingBinaryError < Error; end

  # Raised when the binary cannot be decompressed into any candidate directory.
  class ExtractionError < Error; end
end

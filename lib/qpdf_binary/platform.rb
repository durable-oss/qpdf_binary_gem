# frozen_string_literal: true

require "rbconfig"

module QpdfBinary
  # Maps the running Ruby's host triple onto the platforms that have a static
  # qpdf build.
  #
  # Only Linux is supported. The binaries are linked against musl, so they run
  # on glibc and musl distributions alike, but macOS and Windows have no
  # equivalent of a fully static executable.
  module Platform
    # Platforms with a binary in libexec/.
    SUPPORTED = %w[linux-x86_64 linux-aarch64].freeze

    CPU_ALIASES = {
      "x86_64" => "x86_64",
      "amd64" => "x86_64",
      "x64" => "x86_64",
      "aarch64" => "aarch64",
      "arm64" => "aarch64"
    }.freeze
    private_constant :CPU_ALIASES

    module_function

    # @return [String] the running platform's identifier
    # @raise [UnsupportedPlatformError] if it has no static build
    def current
      detect(RbConfig::CONFIG["host_os"], RbConfig::CONFIG["host_cpu"])
    end

    # @param host_os [String] a value like RbConfig::CONFIG["host_os"], e.g. "linux-gnu"
    # @param host_cpu [String] a value like RbConfig::CONFIG["host_cpu"], e.g. "x86_64"
    # @return [String] the matching identifier from {SUPPORTED}
    # @raise [UnsupportedPlatformError] if there is no match
    def detect(host_os, host_cpu)
      os = host_os.to_s.downcase
      cpu = CPU_ALIASES[host_cpu.to_s.downcase]

      unless os.start_with?("linux") && cpu
        raise UnsupportedPlatformError,
              "qpdf-binary has no static qpdf build for #{host_os}/#{host_cpu}. " \
              "Supported platforms: #{SUPPORTED.join(", ")}. " \
              "Install qpdf with your system package manager instead."
      end

      "linux-#{cpu}"
    end
  end
end

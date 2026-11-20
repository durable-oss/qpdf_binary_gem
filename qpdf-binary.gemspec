# frozen_string_literal: true

require_relative "lib/qpdf_binary/version"

Gem::Specification.new do |spec|
  spec.name        = "qpdf-binary"
  spec.version     = QpdfBinary::VERSION
  spec.authors     = ["David J. Berube"]
  spec.email       = ["commercial@durableprogramming.com"]

  spec.summary     = "Statically linked qpdf #{QpdfBinary::QPDF_VERSION} executables for Linux, packaged as a gem"
  spec.description = <<~DESC
    Ships qpdf #{QpdfBinary::QPDF_VERSION} as fully static executables for Linux x86_64 and
    aarch64, built against musl with zlib, libjpeg-turbo and OpenSSL linked in. Installing
    the gem puts a working `qpdf` on the PATH with no system packages, and
    QpdfBinary.path hands the executable to Ruby code. The binaries run on any glibc or
    musl distribution, including slim and distroless container images.
  DESC
  spec.homepage    = "https://github.com/durable-oss/qpdf_binary_gem"
  # The Ruby wrapper is MIT. The bundled qpdf, OpenSSL and libjpeg-turbo are
  # Apache-2.0 / BSD-style; see THIRD_PARTY_NOTICES.md and licenses/.
  spec.licenses    = ["MIT", "Apache-2.0"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/qpdf-binary"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["qpdf_version"] = QpdfBinary::QPDF_VERSION

  # Library code, the executable, docs and license texts come from git. The
  # binaries in libexec/ are build products, kept out of git and produced by
  # `rake binaries` (or the release workflow) before the gem is built, so they
  # are picked up from disk.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    tracked = `git ls-files -z`.split("\x0").select do |f|
      f.match(%r{\A(?:lib/|exe/|licenses/)}) ||
        %w[README.md CHANGELOG.md MIT-LICENSE THIRD_PARTY_NOTICES.md].include?(f)
    end
    tracked + Dir["libexec/qpdf-linux-*.{gz,buildinfo}"]
  end
  spec.bindir        = "exe"
  spec.executables   = ["qpdf"]
  spec.require_paths = ["lib"]

  # No runtime dependencies.

  # Development dependencies
  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.5"
  spec.add_development_dependency "rake", ">= 12.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-minitest", "~> 0.36"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "simplecov", "~> 0.22"
end

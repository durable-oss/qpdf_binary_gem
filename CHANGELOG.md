# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions are the packaged qpdf version plus a packaging revision; see the
README's Versioning section.

## [Unreleased]

### Added
- Fully static qpdf 12.4.2 executables for Linux x86_64 and aarch64, built
  against musl with zlib, libjpeg-turbo and OpenSSL linked in. The build
  verifies the source tarball's SHA-256 and rejects any binary that needs a
  dynamic loader or shared libraries.
- A `qpdf` executable that passes all arguments to the bundled binary.
- `QpdfBinary.path`, which decompresses the binary for the running platform
  on first use and returns its path. It falls back from the gem directory to
  a per-user cache when the gem directory is read-only, and honours
  `QPDF_BINARY_CACHE_DIR`.
- `QpdfBinary::UnsupportedPlatformError`, `MissingBinaryError` and
  `ExtractionError`, all subclasses of `QpdfBinary::Error`.

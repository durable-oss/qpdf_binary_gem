# qpdf-binary

[![CI](https://github.com/durable-oss/qpdf_binary_gem/actions/workflows/ci.yml/badge.svg)](https://github.com/durable-oss/qpdf_binary_gem/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/qpdf-binary.svg)](https://rubygems.org/gems/qpdf-binary)

[qpdf](https://qpdf.readthedocs.io/) as a Ruby gem. qpdf is a command-line
tool that splits, merges, encrypts, decrypts, linearizes and repairs PDFs
without changing their content.

The gem ships qpdf 12.4.2 as **fully static Linux executables** for x86_64 and
aarch64. They are built against musl, with zlib, libjpeg-turbo, OpenSSL and
libstdc++ linked in, so they depend on no shared libraries at all. The same
binary runs on Debian, Ubuntu, RHEL, Alpine, and distroless or `scratch`
container images. You don't need to `apt-get install qpdf` in your Dockerfile.

Packaging follows the
[wkhtmltopdf-binary](https://github.com/zakird/wkhtmltopdf_binary_gem) gem:
the gzipped binaries live inside the gem, and the one for your platform is
decompressed the first time it runs.

## Installation

```ruby
gem "qpdf-binary"
```

```bash
bundle install
```

## Usage

### From the command line

Installing the gem puts `qpdf` on your `PATH`:

```bash
qpdf --version
qpdf --linearize input.pdf output.pdf
qpdf --empty --pages a.pdf b.pdf -- merged.pdf
qpdf --encrypt --user-password=secret --owner-password=owner --bits=256 -- in.pdf out.pdf
```

Every argument goes to qpdf unchanged. The
[qpdf manual](https://qpdf.readthedocs.io/en/stable/cli.html) covers the rest.

Under `bundle exec`, or wherever the RubyGems executable directory comes
before `/usr/bin` on your `PATH`, this `qpdf` shadows a system-installed one.
Call `/usr/bin/qpdf` explicitly when you want the system copy.

### From Ruby

`QpdfBinary.path` returns the path to the executable, extracting it on first
use:

```ruby
require "qpdf_binary"
require "open3"

system(QpdfBinary.path, "--linearize", "in.pdf", "out.pdf", exception: true)

pages, status = Open3.capture2(QpdfBinary.path, "--show-npages", "report.pdf")
pages.to_i if status.success?
```

Pass arguments as separate strings, as above. qpdf is then run without a
shell, so file names with spaces or shell metacharacters are safe.

Other libraries that shell out to qpdf can usually be pointed at
`QpdfBinary.path`.

### Errors

Everything raised is a subclass of `QpdfBinary::Error`:

| Error | When |
| --- | --- |
| `QpdfBinary::UnsupportedPlatformError` | The host is not Linux x86_64 or aarch64 |
| `QpdfBinary::MissingBinaryError` | The gem was built without this platform's binary (see [Building from source](#building-from-source)) |
| `QpdfBinary::ExtractionError` | No candidate directory was writable |

## Where the binary is extracted

On first use, the binary is decompressed into the first of these directories
that works:

1. `$QPDF_BINARY_CACHE_DIR/<gem version>/`, if `QPDF_BINARY_CACHE_DIR` is set
2. The gem's own `libexec/` directory
3. `${XDG_CACHE_HOME:-~/.cache}/qpdf-binary/<gem version>/`

After that, the extracted copy is reused. It is written to a temporary file
and renamed into place, so concurrent first runs, such as several Puma workers
booting at once, never see a partial file.

Gems installed by root, or baked into a read-only image, fall through to the
user cache. If neither directory is writable at runtime, set
`QPDF_BINARY_CACHE_DIR` to a writable location, or run `qpdf --version` once
at image build time so the binary is already extracted into `libexec/`:

```dockerfile
RUN bundle install && bundle exec qpdf --version
```

The gem never extracts into a shared temporary directory such as `/tmp`, where
another local user could plant an executable first.

## Supported platforms

| Platform | Binary |
| --- | --- |
| Linux x86_64 (glibc or musl) | `libexec/qpdf-linux-x86_64.gz` |
| Linux aarch64 (glibc or musl) | `libexec/qpdf-linux-aarch64.gz` |

macOS and Windows have no fully static equivalent, so they aren't packaged.
Install qpdf with Homebrew (`brew install qpdf`) or from the
[qpdf releases](https://github.com/qpdf/qpdf/releases).

## Versioning

The gem version is the qpdf version plus a packaging revision. `12.4.2.0` is
the first release of qpdf 12.4.2, and `12.4.2.1` repackages that same qpdf
(a build fix, a wrapper change). To stay on one qpdf release, pin all three
leading numbers:

```ruby
gem "qpdf-binary", "~> 12.4.2.0"
```

The constants are available at runtime:

```ruby
QpdfBinary::QPDF_VERSION # => "12.4.2"
QpdfBinary::VERSION      # => "12.4.2.0"
```

## How the binaries are built

[`builder/Dockerfile`](builder/Dockerfile) compiles qpdf from the release
tarball on Alpine Linux. The tarball's SHA-256 is pinned in
[`lib/qpdf_binary/version.rb`](lib/qpdf_binary/version.rb), and the build
aborts if it doesn't match. The resulting executable has to pass these checks
before it is exported:

- It has no `PT_INTERP` program header and no `DT_NEEDED` entries, so it
  needs no dynamic loader and no shared libraries.
- `qpdf --version` reports the pinned version.
- `qpdf --show-crypto` reports exactly `openssl`. qpdf's built-in crypto is
  meant for testing and isn't hardened, so it is compiled out.
- It encrypts a PDF with AES-256, decrypts it, and checks the result.
- It decodes a JPEG stream through libjpeg-turbo.

CI builds each architecture on a native GitHub runner, then runs the binary in
`gcr.io/distroless/static-debian12`, an image that contains no libc. The
release workflow publishes those same artifacts, and attaches the raw `.gz`
files to the GitHub Release.

Each binary ships with a `.buildinfo` file listing the exact Alpine package
versions (OpenSSL, zlib, libjpeg-turbo, musl) linked into it.

### Building from source

The binaries are build products and are not in git. A gem built from a fresh
checkout has to produce them first. This needs Docker:

```bash
bin/build-binaries            # x86_64 and aarch64
bin/build-binaries x86_64     # just one
rake binaries ARCH=x86_64     # the same, through rake
```

Building for an architecture other than the host's goes through QEMU
emulation. Register it first with
`docker run --privileged --rm tonistiigi/binfmt --install arm64`, and expect
the build to be slow.

`rake build` refuses to package the gem unless every supported platform has a
binary in `libexec/`.

## Licensing

The Ruby code in this gem is MIT licensed; see [MIT-LICENSE](MIT-LICENSE).

The bundled qpdf binary is a separate work under the Apache License 2.0, and
it statically links other open source libraries. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and the texts in
[`licenses/`](licenses/), all of which are packaged with the gem.

## Development

```bash
bundle install
bin/test                 # unit tests; real-binary tests skip without libexec/
bundle exec rubocop
bin/build-binaries x86_64 && bin/test   # include the real-binary tests
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the release process.

## Contact

Durable Programming, LLC: commercial@durableprogramming.com

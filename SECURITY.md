# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version  | Supported          |
| -------- | ------------------ |
| 12.4.2.x | :white_check_mark: |

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Security vulnerabilities should be reported privately to help protect users while a fix is being developed.

### How to Report

Please report security vulnerabilities to: **security@durableprogramming.com**

### What to Include

To help us understand and address the vulnerability quickly, please include:

1. **Description**: A clear description of the vulnerability
2. **Impact**: What the vulnerability could allow an attacker to do
3. **Steps to Reproduce**: Detailed steps to reproduce the issue
4. **Affected Versions**: Which versions of the gem are affected
5. **Suggested Fix**: If you have a proposed solution (optional)
6. **Proof of Concept**: Code demonstrating the vulnerability (if applicable)

### What to Expect

- **Initial Response**: Within 48 hours of your report
- **Status Updates**: Every 3-5 business days on our progress
- **Disclosure Timeline**: We aim to release a fix within 90 days
- **Coordinated Disclosure**: We will work with you on responsible disclosure timing
- **Credit**: We will publicly acknowledge your contribution (unless you prefer to remain anonymous)

## Vulnerabilities in qpdf or its libraries

This gem repackages qpdf, OpenSSL, libjpeg-turbo and zlib. A vulnerability in
one of them is fixed upstream first; report it to that project. qpdf's policy
is at https://github.com/qpdf/qpdf/security.

Because those libraries are statically linked, updating the system's OpenSSL
or zlib does **not** patch the qpdf in this gem. A fix reaches you only
through a new qpdf-binary release. When an upstream advisory affects the
bundled qpdf, or a library linked into it, we rebuild against the fixed
version and publish a new packaging revision. If you notice we haven't, tell
us at the address below. Each binary's `.buildinfo` file lists the library
versions it was built with.

## How the binaries are produced

- qpdf is compiled from the release tarball, whose SHA-256 is pinned in
  `lib/qpdf_binary/version.rb`. The build stops on a mismatch.
- The Alpine base image is pinned by digest in `builder/Dockerfile`.
- Release binaries are built by GitHub Actions from the tagged commit, not on
  a developer machine.

## Running qpdf on untrusted PDFs

qpdf parses complex, attacker-controlled input. When processing PDFs from
users:

- Pass arguments as separate strings (`system(QpdfBinary.path, "--check", path)`),
  never as one interpolated shell string.
- Run it with a timeout and resource limits, and preferably in a sandbox.
- Keep the gem current.

## Extraction

The binary is extracted into the gem directory, `QPDF_BINARY_CACHE_DIR`, or
the user's cache directory, and never into a shared temporary directory.
Anyone who can write to those directories can replace the executable, so keep
them writable only by the user that runs your application.

## Contact

For security concerns: **security@durableprogramming.com**

For other questions: **commercial@durableprogramming.com**

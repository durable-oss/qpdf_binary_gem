# Contributing to qpdf-binary

Thanks for helping. This gem is small on purpose: a static qpdf build, plus
just enough Ruby to find and run it. Please keep changes in that spirit.

## Development setup

You need Ruby 2.7 or newer, Bundler, Git, and Docker if you want to build the
binaries.

```bash
git clone https://github.com/durable-oss/qpdf_binary_gem.git
cd qpdf_binary_gem
bundle install
bin/test
```

The unit tests run against fake binaries. Three tests need the real qpdf and
skip until it is built:

```bash
bin/build-binaries x86_64   # or aarch64 on an ARM machine
bin/test
```

Run `bundle exec rubocop` before pushing, or use `bin/push`, which runs
RuboCop, the tests, and a `gem build` before it pushes.

## Changing the build

Everything that affects the binary lives in `builder/Dockerfile`. The checks
in its final `RUN` step are the contract: the binary must stay free of a
dynamic loader and shared libraries, use OpenSSL as its only crypto provider,
and pass the encrypt/decrypt and JPEG round trips. If a change needs one of
those checks relaxed, explain why in the pull request.

If a dependency's license text changes, `bin/build-binaries` rewrites
`licenses/` and CI fails until the new texts are committed. Update
`THIRD_PARTY_NOTICES.md` when a linked component is added or removed.

## Upgrading qpdf

1. Find the new release on https://github.com/qpdf/qpdf/releases and take the
   SHA-256 of `qpdf-X.Y.Z.tar.gz` from the release's `qpdf-X.Y.Z.sha256`
   file. The file is signed by the qpdf maintainers; check the signature.
2. In `lib/qpdf_binary/version.rb`, set `QPDF_VERSION` and
   `QPDF_SOURCE_SHA256`. Leave `VERSION` alone; `bin/release` sets it.
3. Run `bin/build-binaries x86_64 && bin/test`.
4. Add a CHANGELOG entry under `## [Unreleased]`, and update the version in
   `README.md` and the supported row in `SECURITY.md`.

Consider bumping the Alpine image digest in `builder/Dockerfile` at the same
time, to pick up OpenSSL and zlib fixes.

## Releasing

Releases are cut from `main` with `bin/release`:

```bash
bin/release --dry-run   # show what would change
bin/release             # release the next version
```

The script works out the version: `QPDF_VERSION.0` after a qpdf upgrade,
otherwise the next packaging revision (`12.4.2.0` -> `12.4.2.1`). Pass an
explicit `X.Y.Z.N` to override. It checks that you are on a clean `main` that
matches `origin/main` with a non-empty `## [Unreleased]` section, runs RuboCop
and the tests, then commits, tags and pushes.

The pushed tag triggers `.github/workflows/release.yml`. It builds both
architectures on native runners, re-runs the checks against the real
binaries, publishes to RubyGems through
[trusted publishing](https://guides.rubygems.org/trusted-publishing/), and
creates a GitHub Release with the changelog entry, the gem, and the raw
binaries. `rake build` refuses to package the gem if either binary is missing.

### One-time setup

`bin/setup-github` applies the repository settings and prints the steps for
linking trusted publishing on rubygems.org. Run it with `--dry-run` first.

## Reporting issues

Include `ruby -v`, `uname -m`, the gem version, the qpdf command you ran, and
its full output. Report problems in qpdf's own behaviour to
https://github.com/qpdf/qpdf/issues. Security issues go to
security@durableprogramming.com, not a public issue; see SECURITY.md.

# frozen_string_literal: true

module QpdfBinary
  # The qpdf release this gem packages.
  QPDF_VERSION = "12.4.2"

  # SHA-256 of qpdf-QPDF_VERSION.tar.gz as published on the qpdf GitHub
  # release. The static build refuses to compile a tarball that does not
  # match, so bump this together with QPDF_VERSION.
  QPDF_SOURCE_SHA256 = "8a58af5b6141319287c1883bec8bd1bd545b7567b7fc5e6ce5d25a1c85f36397"

  # The gem version is the qpdf version plus a packaging revision, so
  # 12.4.2.0 is the first build of qpdf 12.4.2 and 12.4.2.1 is a repackaging
  # of the same qpdf (a build fix, a new platform, a wrapper change).
  VERSION = "12.4.2.0"
end

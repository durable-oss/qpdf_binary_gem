# frozen_string_literal: true

# Bundler.require loads a gem by its name, "qpdf-binary", but the library's
# entry point is qpdf_binary.rb. This file bridges the two.
require "qpdf_binary"

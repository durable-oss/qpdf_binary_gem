# frozen_string_literal: true

require "test_helper"

class PlatformTest < Minitest::Test
  def test_linux_x86_64
    assert_equal "linux-x86_64", QpdfBinary::Platform.detect("linux-gnu", "x86_64")
  end

  def test_linux_amd64_alias
    assert_equal "linux-x86_64", QpdfBinary::Platform.detect("linux", "amd64")
  end

  def test_linux_aarch64
    assert_equal "linux-aarch64", QpdfBinary::Platform.detect("linux-gnu", "aarch64")
  end

  def test_linux_arm64_alias
    assert_equal "linux-aarch64", QpdfBinary::Platform.detect("linux-musl", "arm64")
  end

  def test_musl_hosts_use_the_same_binary
    assert_equal QpdfBinary::Platform.detect("linux-gnu", "x86_64"),
                 QpdfBinary::Platform.detect("linux-musl", "x86_64")
  end

  def test_macos_is_unsupported
    error = assert_raises(QpdfBinary::UnsupportedPlatformError) do
      QpdfBinary::Platform.detect("darwin23", "arm64")
    end
    assert_includes error.message, "darwin23/arm64"
    assert_includes error.message, "linux-x86_64"
  end

  def test_windows_is_unsupported
    assert_raises(QpdfBinary::UnsupportedPlatformError) do
      QpdfBinary::Platform.detect("mingw32", "x64")
    end
  end

  def test_unknown_cpu_is_unsupported
    assert_raises(QpdfBinary::UnsupportedPlatformError) do
      QpdfBinary::Platform.detect("linux-gnu", "riscv64")
    end
  end

  def test_every_supported_platform_is_reachable
    detected = [%w[linux x86_64], %w[linux aarch64]].map { |os, cpu| QpdfBinary::Platform.detect(os, cpu) }

    assert_equal QpdfBinary::Platform::SUPPORTED.sort, detected.sort
  end
end

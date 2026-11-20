# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class QpdfBinaryTest < Minitest::Test
  EXE = File.join(TestHelpers::ROOT, "exe", "qpdf")

  def setup
    QpdfBinary.reset!
    @tmp = Dir.mktmpdir("qpdf-binary-test")
  end

  def teardown
    QpdfBinary.reset!
    FileUtils.rm_rf(@tmp)
  end

  def test_gem_version_extends_the_qpdf_version
    assert_match(/\A#{Regexp.escape(QpdfBinary::QPDF_VERSION)}\.\d+\z/o, QpdfBinary::VERSION)
  end

  def test_source_checksum_is_a_sha256
    assert_match(/\A\h{64}\z/, QpdfBinary::QPDF_SOURCE_SHA256)
  end

  def test_archive_path_names_the_platform
    assert_equal File.join(QpdfBinary::LIBEXEC_DIR, "qpdf-linux-aarch64.gz"),
                 QpdfBinary.archive_path("linux-aarch64")
  end

  def test_extraction_dirs_default_to_libexec_then_the_user_cache
    with_env("QPDF_BINARY_CACHE_DIR" => nil, "XDG_CACHE_HOME" => "/xdg") do
      assert_equal [QpdfBinary::LIBEXEC_DIR, "/xdg/qpdf-binary/#{QpdfBinary::VERSION}"],
                   QpdfBinary.extraction_dirs
    end
  end

  def test_extraction_dirs_use_home_without_xdg
    with_env("QPDF_BINARY_CACHE_DIR" => nil, "XDG_CACHE_HOME" => nil) do
      assert_equal File.join(Dir.home, ".cache", "qpdf-binary", QpdfBinary::VERSION),
                   QpdfBinary.extraction_dirs.last
    end
  end

  def test_cache_dir_override_comes_first_and_is_versioned
    with_env("QPDF_BINARY_CACHE_DIR" => "/srv/cache", "XDG_CACHE_HOME" => "/xdg") do
      assert_equal File.join("/srv/cache", QpdfBinary::VERSION), QpdfBinary.extraction_dirs.first
      assert_equal 3, QpdfBinary.extraction_dirs.size
    end
  end

  def test_empty_override_is_ignored
    with_env("QPDF_BINARY_CACHE_DIR" => "", "XDG_CACHE_HOME" => "") do
      assert_equal QpdfBinary::LIBEXEC_DIR, QpdfBinary.extraction_dirs.first
    end
  end

  def test_exe_passes_arguments_through_verbatim
    skip "no static build for this platform" unless supported_platform?

    with_fake_binary do |env|
      args = ["--check", "file with spaces.pdf", "$HOME", "; echo injected"]
      stdout, status = Open3.capture2(env, RbConfig.ruby, EXE, *args)

      assert_predicate status, :success?
      assert_equal args, stdout.lines.map(&:chomp)
    end
  end

  def test_exe_without_arguments_does_not_use_a_shell
    skip "no static build for this platform" unless supported_platform?

    with_fake_binary do |env|
      stdout, status = Open3.capture2(env, RbConfig.ruby, EXE)

      assert_predicate status, :success?
      assert_empty stdout
    end
  end

  def test_real_binary_reports_the_packaged_version
    skip "libexec/ has no binary for this platform; run `rake binaries`" unless real_binary_available?

    with_env("QPDF_BINARY_CACHE_DIR" => @tmp) do
      stdout, status = Open3.capture2(RbConfig.ruby, EXE, "--version")

      assert_predicate status, :success?
      assert_equal "qpdf version #{QpdfBinary::QPDF_VERSION}", stdout.lines.first.chomp
    end
  end

  def test_real_binary_is_statically_linked
    skip "libexec/ has no binary for this platform; run `rake binaries`" unless real_binary_available?

    with_env("QPDF_BINARY_CACHE_DIR" => @tmp) do
      elf = File.binread(QpdfBinary.path)

      assert_equal "\x7FELF".b, elf[0, 4]
      refute_includes elf, "ld-linux", "binary references a dynamic loader"
      refute_includes elf, "ld-musl", "binary references a dynamic loader"
    end
  end

  def test_real_binary_uses_openssl
    skip "libexec/ has no binary for this platform; run `rake binaries`" unless real_binary_available?

    with_env("QPDF_BINARY_CACHE_DIR" => @tmp) do
      stdout, status = Open3.capture2(QpdfBinary.path, "--show-crypto")

      assert_predicate status, :success?
      assert_equal "openssl", stdout.strip
    end
  end

  private

  def supported_platform?
    QpdfBinary.platform
    true
  rescue QpdfBinary::UnsupportedPlatformError
    false
  end

  # Places a pre-extracted fake qpdf where QPDF_BINARY_CACHE_DIR points, so
  # the executable finds it without needing a real archive in libexec/.
  def with_fake_binary
    dir = File.join(@tmp, QpdfBinary::VERSION)
    FileUtils.mkdir_p(dir)
    fake = File.join(dir, "qpdf-#{QpdfBinary.platform}")
    File.write(fake, FAKE_QPDF)
    File.chmod(0o755, fake)

    yield({ "QPDF_BINARY_CACHE_DIR" => @tmp })
  end
end

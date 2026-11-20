# frozen_string_literal: true

require "test_helper"

class ExtractorTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir("qpdf-binary-test")
    @archive = write_gzip(File.join(@tmp, "archive", "qpdf-linux-x86_64.gz"), FAKE_QPDF)
  end

  def teardown
    FileUtils.chmod_R("u+w", @tmp)
    FileUtils.rm_rf(@tmp)
  end

  def test_extracts_into_the_first_directory
    first = File.join(@tmp, "first")
    path = QpdfBinary::Extractor.new(@archive, [first, File.join(@tmp, "second")]).extract

    assert_equal File.join(first, "qpdf-linux-x86_64"), path
    assert_equal FAKE_QPDF, File.read(path)
    assert File.executable?(path)
  end

  def test_extracted_binary_is_world_executable_but_not_writable
    path = QpdfBinary::Extractor.new(@archive, [File.join(@tmp, "out")]).extract

    assert_equal 0o755, File.stat(path).mode & 0o777
  end

  def test_reuses_an_existing_extraction
    dir = File.join(@tmp, "out")
    path = QpdfBinary::Extractor.new(@archive, [dir]).extract
    File.write(path, "already here")

    assert_equal path, QpdfBinary::Extractor.new(@archive, [dir]).extract
    assert_equal "already here", File.read(path)
  end

  def test_reuses_an_extraction_in_a_later_directory
    later = File.join(@tmp, "later")
    existing = QpdfBinary::Extractor.new(@archive, [later]).extract

    assert_equal existing, QpdfBinary::Extractor.new(@archive, [File.join(@tmp, "earlier"), later]).extract
    refute_path_exists File.join(@tmp, "earlier", "qpdf-linux-x86_64")
  end

  def test_ignores_a_non_executable_leftover
    dir = File.join(@tmp, "out")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "qpdf-linux-x86_64"), "")

    path = QpdfBinary::Extractor.new(@archive, [dir]).extract

    assert_equal FAKE_QPDF, File.read(path)
  end

  def test_falls_back_when_a_directory_is_read_only
    skip "root can write to read-only directories" if Process.uid.zero?

    read_only = File.join(@tmp, "read-only")
    FileUtils.mkdir_p(read_only)
    FileUtils.chmod(0o555, read_only)
    fallback = File.join(@tmp, "fallback")

    path = QpdfBinary::Extractor.new(@archive, [read_only, fallback]).extract

    assert_equal File.join(fallback, "qpdf-linux-x86_64"), path
  end

  def test_leaves_no_temporary_files_behind
    dir = File.join(@tmp, "out")
    QpdfBinary::Extractor.new(@archive, [dir]).extract

    assert_equal ["qpdf-linux-x86_64"], Dir.children(dir)
  end

  def test_raises_when_every_directory_fails
    skip "root can write to read-only directories" if Process.uid.zero?

    read_only = File.join(@tmp, "read-only")
    FileUtils.mkdir_p(read_only)
    FileUtils.chmod(0o555, read_only)

    error = assert_raises(QpdfBinary::ExtractionError) do
      QpdfBinary::Extractor.new(@archive, [read_only]).extract
    end
    assert_includes error.message, read_only
  end

  def test_raises_on_a_corrupt_archive
    corrupt = File.join(@tmp, "archive", "qpdf-linux-aarch64.gz")
    File.write(corrupt, "this is not gzip")
    dir = File.join(@tmp, "out")

    assert_raises(QpdfBinary::ExtractionError) { QpdfBinary::Extractor.new(corrupt, [dir]).extract }
    assert_empty Dir.children(dir)
  end

  def test_raises_when_the_archive_is_missing
    missing = File.join(@tmp, "archive", "qpdf-linux-aarch64.gz")

    error = assert_raises(QpdfBinary::MissingBinaryError) do
      QpdfBinary::Extractor.new(missing, [File.join(@tmp, "out")]).extract
    end
    assert_includes error.message, "rake binaries"
  end

  def test_missing_archive_is_fine_once_extracted
    dir = File.join(@tmp, "out")
    path = QpdfBinary::Extractor.new(@archive, [dir]).extract
    File.delete(@archive)

    assert_equal path, QpdfBinary::Extractor.new(@archive, [dir]).extract
  end
end

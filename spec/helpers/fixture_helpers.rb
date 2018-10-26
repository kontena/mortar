module FixtureHelpers
  FIXTURES_PATH = File.join(File.dirname(__FILE__), '../fixtures')

  # @return [String] file path
  def fixture_path(*path)
    File.join(FIXTURES_PATH, *path)
  end

  # @return [String] file contents
  def fixture(*path)
    File.read(fixture_path(*path))
  end
end

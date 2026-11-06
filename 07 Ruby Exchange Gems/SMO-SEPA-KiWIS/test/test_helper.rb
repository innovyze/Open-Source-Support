require "minitest/autorun"
require "smo_sepa_kiwis"

FIXTURES_DIR = File.expand_path("fixtures", __dir__)

def fixture(name)
  File.read(File.join(FIXTURES_DIR, name))
end

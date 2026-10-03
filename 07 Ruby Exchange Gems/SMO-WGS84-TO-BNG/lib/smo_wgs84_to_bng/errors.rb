module SmoWgs84ToBng
  class Error < StandardError; end
  class MissingIdError < Error; end
  class MissingCoordinateError < Error; end
  class InvalidCoordinateError < Error; end
  class OutOfBoundsError < Error; end
end

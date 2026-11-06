module SmoSepaKiwis
  class Error < StandardError; end

  class ApiError < Error
    attr_reader :status

    def initialize(message, status:)
      super(message)
      @status = status
    end
  end

  class ParseError < Error; end
end

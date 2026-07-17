# frozen_string_literal: true

module SmoEaHydrology
  class Error < StandardError; end

  class ApiError < Error
    attr_reader :status

    def initialize(msg, status: nil)
      super(msg)
      @status = status
    end
  end

  class ParseError < Error; end
end

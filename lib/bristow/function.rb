module Bristow
  class Function
    attr_reader :name, :description, :parameters

    def initialize(name:, description:, parameters: {}, &block)
      @name = name
      @description = description
      @parameters = parameters
      @block = block
    end

    def call(**args)
      @block.call(**args)
    end
  end
end

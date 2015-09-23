module Rubykon
  class Stone
    attr_reader :x, :y, :color, :group, :captures

    def initialize(x, y, color)
      @x     = x
      @y     = y
      @color = color
      @group = nil
    end

    def remove
      @group = nil
    end

    def join(group)
      @group = group
    end

    def self.other_color(color)
      if color == :black
        :white
      else
        :black
      end
    end

    def enemy_color
      self.class.other_color(color)
    end

    def capture(stones)
      @captures ||= []
      @captures += stones
    end

    def empty?
      color == Board::EMPTY_COLOR
    end

    def pass?
      @x.nil? || @y.nil?
    end

    def ==(other_stone)
      (color == other_stone.color) &&
        (x == other_stone.x) &&
        (y == other_stone.y)
    end

    def identifier
      "#{x}-#{y}".freeze
    end
  end
end
module Scheduling::Ilp
  class Term

    attr_accessor :mult, :var

    def initialize(var, mult = 1)
      @mult = mult
      @var = var
    end

    def +(vars)
      TermArray.new(self) + vars
    end

    def -(vars)
      TermArray.new(self) - vars
    end

    def *(mult)
      raise ArgumentError, 'Argument is not numeric' unless mult.is_a? Numeric
      Term.new(@var, @mult * mult)
    end

    def coerce(num)
      [Constant.new(num), self]
    end

    def to_s
      "#{mult} #{var.name}"
    end
  end
end

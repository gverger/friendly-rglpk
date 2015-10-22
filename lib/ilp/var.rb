module Ilp
  class Var
    attr_accessor :kind, :name, :lower_bound, :upper_bound

    BINARY_KIND = Rglpk::GLP_BV
    INTEGER_KIND = Rglpk::GLP_IV
    CONTINUOUS_KIND = Rglpk::GLP_CV

    def initialize(name: nil, kind: INTEGER_KIND, lower_bound: nil, upper_bound: nil)
      @kind = kind
      @name = name
      @name = ('a'..'z').to_a.shuffle[0,8].join if name.nil?
      @lower_bound = lower_bound
      @upper_bound = upper_bound
    end

    def bounds=(range)
      @lower_bound = range.min
      @upper_bound = range.max
    end

    def bounds
      @lower_bound..@upper_bound
    end

    def +(vars)
      Term.new(self) + vars
    end

    def -(vars)
      Term.new(self) - vars
    end

    def -@
      Term.new(self, -1)
    end

    def *(mult)
      Term.new(self) * mult
    end

    def coerce(num)
      [Constant.new(num), self]
    end

  end

end

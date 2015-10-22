require "set"

module Ilp
  class Model

    INF = 1.0 / 0.0 # Useful for ranges

    attr_accessor :vars, :constraints, :objective

    def initialize
      @vars = Set.new
      @constraints = Set.new
      @objective = nil
    end

    def int_var(range = nil, name: nil)
      var(Var::INTEGER_KIND, range, name)
    end

    def int_var_array(length, range = nil, names: nil)
      array_var(length, Var::INTEGER_KIND, range, names)
    end

    def bin_var(name: nil)
      var(Var::BINARY_KIND, nil, name)
    end

    def bin_var_array(length, names: nil)
      array_var(length, Var::BINARY_KIND, range, names)
    end

    def cont_var(range = nil)
      var(Var::CONTINUOUS_KIND, range, name)
    end

    def cont_var_array(length, range = nil)
      array_var(length, Var::CONTINUOUS_KIND, range, names)
    end

    def enforce(constraint)
      constraints << constraint
    end

    def minimize(expression)
      @objective = Objective.new(expression, Objective::MINIMIZE)
      self
    end

    def maximize(expression)
      @objective = Objective.new(expression, Objective::MAXIMIZE)
      self
    end

    def to_problem
      p = Ilp::Problem.new
      p.read(self)
      p
    end

  private
    def array_var(length, kind, range, names)
      ar = Array.new(length) { var(kind, range, nil) }
      ar.zip(names).map{ |var, name| var.name = name } unless names.nil?
      ar
    end

    def var(kind, range, name)
      if range.nil?
        v = Var.new(kind: kind, name: name)
        @vars << v
        return v
      end
      v = Var.new(kind: kind, name: name, lower_bound: range.min, upper_bound: range.max)
      @vars << v
      v
    end
  end
end

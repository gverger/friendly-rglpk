module Scheduling::Ilp
  class Objective

    MINIMIZE = Rglpk::GLP_MIN
    MAXIMIZE = Rglpk::GLP_MAX

    attr_accessor :terms, :objective_function
    def initialize(terms, objective_function = MAXIMIZE)
      @terms = terms
      @objective_function = objective_function
    end

  end
end

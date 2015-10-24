module Ilp
  class Objective

    MINIMIZE = Rglpk::GLP_MIN
    MAXIMIZE = Rglpk::GLP_MAX

    attr_accessor :terms, :objective_function
    def initialize(terms, objective_function = MAXIMIZE)
      @terms = terms
      @terms.normalize!
      cste = @terms.send(:pop_constant)
      puts "Removing constant [#{cste}] in objective" if cste != 0
      @objective_function = objective_function
    end

  end
end

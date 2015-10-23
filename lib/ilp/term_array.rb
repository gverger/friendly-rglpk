module Ilp
  class TermArray
    include Enumerable

    attr_accessor :terms

    def initialize(*terms)
      @terms = terms
    end

    def +(vars)
      if vars.is_a? Ilp::Var
        @terms << Ilp::Term.new(vars)
      elsif vars.is_a? Ilp::Term
        @terms << vars
      elsif vars.is_a? Ilp::TermArray
        @terms += vars.terms
      else
        raise ArgumentError, "Argument is not allowed: #{vars} of type #{vars.class}"
      end
      self
    end

    def -(vars)
      self + -1 * vars
    end

    def *(mult)
      raise ArgumentError, 'Argument is not numeric' unless mult.is_a? Numeric
      @terms.map! { |term| term * mult }
      self
    end

    def <=(value)
      Ilp::Constraint.new(self, Ilp::Constraint::LESS_OR_EQ, value)
    end

    def >=(value)
      Ilp::Constraint.new(self, Ilp::Constraint::GREATER_OR_EQ, value)
    end

    def ==(value)
      Ilp::Constraint.new(self, Ilp::Constraint::EQUALS, value)
    end

    def coerce(value)
      [Ilp::Constant.new(value), self]
    end

    def each(&block)
      @terms.each(&block)
    end

    def to_s
      @terms.join(' + ')
    end
  end
end

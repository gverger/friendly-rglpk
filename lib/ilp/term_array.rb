module Scheduling::Ilp
  class TermArray
    include Enumerable

    attr_accessor :terms

    def initialize(*terms)
      @terms = terms
    end

    def +(vars)
      if vars.is_a? Scheduling::Ilp::Var
        @terms << Term.new(vars)
      elsif vars.is_a? Scheduling::Ilp::Term
        @terms << vars
      elsif vars.is_a? Scheduling::Ilp::TermArray
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
      Constraint.new(self, Constraint::LESS_OR_EQ, value)
    end

    def >=(value)
      Constraint.new(self, Constraint::GREATER_OR_EQ, value)
    end

    def ==(value)
      Constraint.new(self, Constraint::EQUALS, value)
    end

    def coerce(value)
      [Constant.new(value), self]
    end

    def each(&block)
      @terms.each(&block)
    end

    def to_s
      @terms.join(' + ')
    end
  end
end

module Scheduling::Ilp
class Constant
  attr_accessor :value
  def initialize(value)
    @value = value
  end
  def <= (term)
    term >= value
  end
  def <(term)
    term > value
  end
  def >=(term)
    term <= value
  end
  def > (term)
    term < value
  end
  def ==(term)
    term == value
  end

  def *(term)
    term * value
  end
end

end

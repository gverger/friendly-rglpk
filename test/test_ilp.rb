require_relative 'helper'

class TestIlp < Minitest::Test

  def test_brief_example
    # The same Brief Example as found in section 1.3 of 
    # glpk-4.44/doc/glpk.pdf.
    #
    # maximize
    #   z = 10 * x1 + 6 * x2 + 4 * x3
    #
    # subject to
    #   p:      x1 +     x2 +     x3 <= 100
    #   q: 10 * x1 + 4 * x2 + 5 * x3 <= 600
    #   r:  2 * x1 + 2 * x2 + 6 * x3 <= 300
    #
    # where all variables are non-negative
    #   x1 >= 0, x2 >= 0, x3 >= 0
    #
    m = Rglpk::Model.new
    x1, x2, x3 = m.int_var_array(3, 0..Rglpk::INF)
    m.maximize(10 * x1 + 6 * x2 + 4 * x3)

    m.enforce(x1 + x2 + x3 <= 100)
    m.enforce(10 * x1 + 4 * x2 + 5 * x3 <= 600)
    m.enforce(2 * x1 + 2 * x2 + 6* x3 <= 300)

    p = m.to_problem

    p.simplex
    puts
    puts "z = #{p.obj_value}, x1 = #{p.value_of(x1)}, x2 = #{p.value_of(x2)}, x3 = #{p.value_of(x3)}"
    p.mip
    puts "z = #{p.obj_value}, x1 = #{p.value_of(x1)}, x2 = #{p.value_of(x2)}, x3 = #{p.value_of(x3)}"
  end

  def test_send_more_money
    model = Rglpk::Model.new
    var_names = [ 'S', 'E', 'N', 'D', 'M', 'O', 'R', 'Y' ]
    vars = model.int_var_array(8, 0..9, names: var_names)
    s,e,n,d,m,o,r,y = vars

    value_of = Hash.new
    value_taken = Hash.new{ |hash, key| hash[key] = []}
    vars.each do |var|
      value_of[var] = Array.new(10)
      0.upto(9).each do |i|
        tmp_var = model.bin_var(name: "#{var.name}_#{i}")
        value_of[var][i] = tmp_var
        value_taken[i] << tmp_var
      end
    end
    value_of.each do |var, values|
      model.enforce(values.inject(:+) == 1)
      model.enforce(values.each_with_index.map{ |v, i| i * v }.inject(:+) - var == 0 )
    end
    value_taken.each do |idx, values|
      model.enforce(values.inject(:+) <= 1)
    end

    s.lower_bound = 1
    m.lower_bound = 1
    model.enforce( number(s,e,n,d) + number(m,o,r,e) - number(m,o,n,e,y) == 0)

    problem = model.to_problem 
    problem.mip(presolve: Rglpk::GLP_ON)

    assert_equal [o,m,y,e,n,d,r,s].map{ |var| problem.value_of(var) }, [0, 1, 2, 5, 6, 7, 8, 9]
  end


  def test_send_most_money
    model = Rglpk::Model.new

    var_names = [ 'S', 'E', 'N', 'D', 'M', 'O', 'T', 'Y' ]
    vars = model.int_var_array(8, 0..9, names: var_names)
    s,e,n,d,m,o,t,y = vars

    value_of = Hash.new
    value_taken = Hash.new{ |hash, key| hash[key] = []}
    vars.each do |var|
      value_of[var] = Array.new(10)
      0.upto(9).each do |i|
        tmp_var = model.bin_var(name: "#{var.name}_#{i}")
        value_of[var][i] = tmp_var
        value_taken[i] << tmp_var
      end
    end
    value_of.each do |var, values|
      model.enforce(values.inject(:+) == 1)
      model.enforce(values.each_with_index.map{ |v, i| i * v }.inject(:+) - var == 0 )
    end
    value_taken.each do |idx, values|
      model.enforce(values.inject(:+) <= 1)
    end

    s.lower_bound = 1
    m.lower_bound = 1
    model.enforce( number(s,e,n,d) + number(m,o,s,t) - number(m,o,n,e,y) == 0)

    model.maximize(number(m,o,n,e,y))

    problem = model.to_problem
    problem.mip(presolve: Rglpk::GLP_ON)
    assert_equal problem.obj_value, 10876
  end

  # Changes [ a, b, c] into 100*a + 10*b + c
  def number(*vars)
    vars.inject { |res, var| 10 * res + var }
  end
end


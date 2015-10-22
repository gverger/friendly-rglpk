require_relative '../spec_helper'

module Scheduling
  describe "Integer Linear Programming" do
    let(:model) { Ilp::Model.new }
    describe "Send more money" do
      before do
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

      end

      it "finds the solution" do
        problem = Ilp::Problem.new
        problem.read(model)
        problem.mip
        expect( [ problem.value_of('O'), problem.value_of('M'), problem.value_of('Y'), problem.value_of('E'), problem.value_of('N'), problem.value_of('D'), problem.value_of('R'), problem.value_of('S')]).to eq([0, 1, 2, 5, 6, 7, 8, 9])
      end
    end

    describe "Send most money" do
      before do
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

      end

      it "finds the solution" do
        problem = Ilp::Problem.new
        problem.read(model)
        problem.mip
        expect(problem.obj_value).to eq(10876)
      end
    end

    # Changes [ a, b, c] into 100*a + 10*b + c
    def number(*vars)
      vars.inject { |res, var| 10 * res + var }
    end
  end
end


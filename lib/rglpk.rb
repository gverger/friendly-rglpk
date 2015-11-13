require 'glpk_wrapper'

module Rglpk
  Glpk_wrapper.constants.each do |c|
    v = Glpk_wrapper.const_get(c)
    self.const_set(c, v) if v.kind_of? Numeric
  end
  TypeConstants = [GLP_FR, GLP_LO, GLP_UP, GLP_DB, GLP_FX]

  class RowColArray
    include Enumerable

    def initialize
      @array = []
    end

    def size
      @array.size
    end

    def each(&block)
      @array.each(&block)
      self
    end

    def [](i)
      if i.kind_of?(String)
        raise RuntimeError, "no rows" if self[1].nil?
        idx = Glpk_wrapper.send(glp_find_method, self[1].p.lp, i)
        raise ArgumentError, "no row with name #{i.inspect}" if idx == 0
        @array[idx - 1]
      else
        @array[i]
      end
    end

  protected

    def push(rc)
      @array << rc
    end

    def delete_at(index)
      @array.delete_at(index)
    end
  end

  class RowArray < RowColArray    
  protected
    def glp_find_method
      :glp_find_row
    end
  end

  class ColArray < RowColArray
  protected
    def glp_find_method
      :glp_find_col
    end
  end

  class Problem
    attr_accessor :rows, :cols, :obj, :lp

    def initialize(model = nil)
      @lp = Glpk_wrapper.glp_create_prob
      @obj = ObjectiveFunction.new(self)
      @rows = RowArray.new
      @cols = ColArray.new
      Glpk_wrapper.glp_create_index(@lp)

      ObjectSpace.define_finalizer(self, self.class.finalizer(@lp))
      read model unless model.nil?

      @default_solve_params = {
        presolve: Rglpk::GLP_ON,
      }
    end

    def self.finalizer(lp)
      proc do
        Glpk_wrapper.glp_delete_index(lp)
        Glpk_wrapper.glp_delete_prob(lp)
      end
    end

    def name=(n)
      Glpk_wrapper.glp_set_prob_name(@lp, n)
    end

    def name
      Glpk_wrapper.glp_get_prob_name(@lp)
    end

    def nz
      Glpk_wrapper.glp_get_num_nz(@lp)
    end

    def add_row
      Glpk_wrapper.glp_add_rows(@lp, 1)
      new_row = Row.new(self, @rows.size + 1)
      @rows.send(:push, new_row)
      new_row
    end

    def add_rows(n)
      Glpk_wrapper.glp_add_rows(@lp, n)
      s = @rows.size
      n.times.map do |i|
        new_row = Row.new(self, s + i + 1)
        @rows.send(:push, new_row)
        new_row
      end
    end

    def add_col
      Glpk_wrapper.glp_add_cols(@lp, 1)
      new_column = Column.new(self, @cols.size + 1)
      @cols.send(:push, new_column)
      new_column
    end

    def add_cols(n)
      Glpk_wrapper.glp_add_cols(@lp, n)
      s = @cols.size
      n.times.map do |i|
        new_col = Column.new(self, s + i + 1)
        @cols.send(:push, new_col)
        new_col
      end
    end

    def del_rows(a)
      # Ensure the array of rows to delete is sorted and unique.
      a = a.sort.uniq

      r = Glpk_wrapper.new_intArray(a.size + 1)
      a.each_with_index{|n, i| Glpk_wrapper.intArray_setitem(r, i + 1, n)}
      Glpk_wrapper.glp_del_rows(@lp, a.size, r)
      Glpk_wrapper.delete_intArray(r)

      a.each do |n|
        @rows.send(:delete_at, n)
        a.each_with_index do |nn, i|
          a[i] -= 1
        end
      end
      @rows.each_with_index{|r, i| r.i = i + 1}
      a
    end

    def del_cols(a)
      # Ensure the array of rows to delete is sorted and unique.
      a = a.sort.uniq

      r = Glpk_wrapper.new_intArray(a.size + 1)
      a.each_with_index{|n, i| Glpk_wrapper.intArray_setitem(r, i + 1, n)}
      Glpk_wrapper.glp_del_cols(@lp, a.size, r)
      Glpk_wrapper.delete_intArray(r)

      a.each do |n|
        @cols.send(:delete_at, n)
        a.each_with_index do |nn, i|
          a[i] -= 1
        end
      end
      @cols.each_with_index{|c, i| c.j = i + 1}
      a
    end

    def set_matrix(v)
      nc = Glpk_wrapper.glp_get_num_cols(@lp)

      ia = Glpk_wrapper.new_intArray(v.size + 1)
      ja = Glpk_wrapper.new_intArray(v.size + 1)
      ar = Glpk_wrapper.new_doubleArray(v.size + 1)

      v.each_with_index do |x, y|
        rn = (y + nc) / nc
        cn = (y % nc) + 1

        Glpk_wrapper.intArray_setitem(ia, y + 1, rn)
        Glpk_wrapper.intArray_setitem(ja, y + 1, cn)
        Glpk_wrapper.doubleArray_setitem(ar, y + 1, x)
      end

      Glpk_wrapper.glp_load_matrix(@lp, v.size, ia, ja, ar)

      Glpk_wrapper.delete_intArray(ia)
      Glpk_wrapper.delete_intArray(ja)
      Glpk_wrapper.delete_doubleArray(ar)
    end

  private

    def apply_options_to_parm(options, parm)
      options.each do |k, v|
        begin
          parm.send("#{k}=".to_sym, v)
        rescue NoMethodError
          raise ArgumentError, "Unrecognised option: #{k}"
        end
      end
    end

  public

    def simplex(options = {})
      @sol_type = :simplex
      parm = Glpk_wrapper::Glp_smcp.new
      Glpk_wrapper.glp_init_smcp(parm)

      # Default to errors only temrinal output.
      parm.msg_lev = GLP_MSG_ERR

      apply_options_to_parm(options, parm)
      Glpk_wrapper.glp_simplex(@lp, parm)
    end

    def status
      Glpk_wrapper.glp_get_status(@lp)
    end

    def solve(options = {})
      mip(options)
    end

    def mip(options = {})
      @sol_type = :mip

      options = @default_solve_params.merge(options)
      parm = Glpk_wrapper::Glp_iocp.new
      Glpk_wrapper.glp_init_iocp(parm)

      # Default to errors only temrinal output.
      parm.msg_lev = GLP_MSG_ERR

      apply_options_to_parm(options, parm)
      Glpk_wrapper.glp_intopt(@lp, parm)
    end

    def mip_status
      Glpk_wrapper.glp_mip_status(@lp)
    end


    def write_lp(filename)
      Glpk_wrapper.glp_write_lp(@lp, nil, filename)
    end

    def proven_infeasible?
      mip_status == Rglpk::GLP_INFEAS
    end

    def proven_optimal?
      mip_status == Rglpk::GLP_OPT
    end

    def set_time_limit(seconds)
      @default_solve_params[:tm_lim] = seconds * 1000
    end

  private
    def read(model)
      vars = model.vars
      constraints = model.constraints
      objective = model.objective

      unless vars.empty?
        add_cols(vars.length)
        current_col_idx = 0
        @column_idx = Hash.new
        vars.each do |var|
          col = @cols[current_col_idx]
          @column_idx[var] = col.j - 1
          col.name = var.name unless var.name.nil?
          col.kind = var.kind
          if var.kind == Rglpk::GLP_BV
            var.bounds = 0..1
          end
          if var.upper_bound.nil?
            if var.lower_bound.nil?
              col.set_bounds(Rglpk::GLP_FR, nil, nil)
            else
              col.set_bounds(Rglpk::GLP_LO, var.lower_bound, nil)
            end
          else
            if var.lower_bound.nil?
              col.set_bounds(Rglpk::GLP_UP, nil, var.upper_bound)
            else
              if var.lower_bound != var.upper_bound
                col.set_bounds(Rglpk::GLP_DB, var.lower_bound, var.upper_bound)
              else
                col.set_bounds(Rglpk::GLP_FX, var.lower_bound, var.upper_bound)
              end
            end
          end
          current_col_idx += 1
        end
      end

      unless constraints.empty?
        add_rows(constraints.length)
        current_row_idx = 0
        constraints.each do |constraint|
          coefs = Array.new(@cols.size, 0)
          constraint.terms.each do |term|
            coefs[@column_idx[term.var]] += term.mult
          end
          row = @rows[current_row_idx]
          row.set(coefs)
          row.set_bounds(constraint.type, constraint.bound, constraint.bound)
          current_row_idx += 1
        end
      end

      unless objective.nil?
        @obj.dir = objective.objective_function
        coefs = Array.new(@cols.size, 0)
        objective.terms.each do |term|
          coefs[@column_idx[term.var]] = term.mult
        end
        @obj.coefs = coefs
      end
    end

  public

    def value_of(var)
      if var.is_a? String
        col = @cols[var]
      else
        col = @cols[@column_idx[var]]
      end
      if @sol_type == :mip
        col.mip_val
      else
        col.get_prim
      end
    end

    def objective_value
      if @sol_type == :mip
        Glpk_wrapper.glp_mip_obj_val(@lp)
      else
        Glpk_wrapper.glp_get_obj_val(@lp)
      end

    end

    def solution_found
      status = Glpk_wrapper.glp_mip_status(@lp)
      status == Rglpk::GLP_FEAS || status == Rglpk::GLP_OPT
    end

  end

  class Row
    attr_accessor :i, :p

    def initialize(problem, i)
      @p = problem
      @i = i
    end

    def name=(n)
      Glpk_wrapper.glp_set_row_name(@p.lp, @i, n)
    end

    def name
      Glpk_wrapper.glp_get_row_name(@p.lp, @i)
    end

    def set_bounds(type, lb, ub)
      raise ArgumentError unless TypeConstants.include?(type)
      lb = 0.0 if lb.nil?
      ub = 0.0 if ub.nil?
      Glpk_wrapper.glp_set_row_bnds(@p.lp, @i, type, lb.to_f, ub.to_f)
    end

    def bounds
      t = Glpk_wrapper.glp_get_row_type(@p.lp, @i)
      lb = Glpk_wrapper.glp_get_row_lb(@p.lp, @i)
      ub = Glpk_wrapper.glp_get_row_ub(@p.lp, @i)

      lb = (t == GLP_FR or t == GLP_UP) ? nil : lb
      ub = (t == GLP_FR or t == GLP_LO) ? nil : ub

      [t, lb, ub]
    end

    def set(v, i = nil)
      raise RuntimeError unless v.size == @p.cols.size or (not i.nil? and i.size == v.size)
      ind = Glpk_wrapper.new_intArray(v.size + 1)
      val = Glpk_wrapper.new_doubleArray(v.size + 1)

      if i.nil?
        i = 1.upto(v.size)
      end

      i.each_with_index{|x, y|
        Glpk_wrapper.intArray_setitem(ind, y + 1, x)}
      v.each_with_index{|x, y|
        Glpk_wrapper.doubleArray_setitem(val, y + 1, x)}

      Glpk_wrapper.glp_set_mat_row(@p.lp, @i, v.size, ind, val)

      Glpk_wrapper.delete_intArray(ind)
      Glpk_wrapper.delete_doubleArray(val)
    end

    def get
      ind = Glpk_wrapper.new_intArray(@p.cols.size + 1)
      val = Glpk_wrapper.new_doubleArray(@p.cols.size + 1)
      len = Glpk_wrapper.glp_get_mat_row(@p.lp, @i, ind, val)
      row = Array.new(@p.cols.size, 0)
      len.times do |i|
        v = Glpk_wrapper.doubleArray_getitem(val, i + 1)
        j = Glpk_wrapper.intArray_getitem(ind, i + 1)
        row[j - 1] = v
      end
      Glpk_wrapper.delete_intArray(ind)
      Glpk_wrapper.delete_doubleArray(val)
      row
    end

    def get_stat
      Glpk_wrapper.glp_get_row_stat(@p.lp, @i)
    end

    def get_prim
      Glpk_wrapper.glp_get_row_prim(@p.lp, @i)
    end

    def mip_val
      Glpk_wrapper.glp_mip_row_val(@p.lp, @i)
    end

    def get_dual
      Glpk_wrapper.glp_get_row_dual(@p.lp, @i)
    end
  end

  class Column
    attr_accessor :j, :p

    def initialize(problem, i)
      @p = problem
      @j = i
    end

    def name=(n)
      Glpk_wrapper.glp_set_col_name(@p.lp, @j, n)
    end

    def name
      Glpk_wrapper.glp_get_col_name(@p.lp, @j)
    end

    def kind=(kind)
      Glpk_wrapper.glp_set_col_kind(@p.lp, j, kind)
    end

    def kind
      Glpk_wrapper.glp_get_col_kind(@p.lp, @j)
    end

    def set_bounds(type, lb, ub)
      raise ArgumentError unless TypeConstants.include?(type)
      lb = 0.0 if lb.nil?
      ub = 0.0 if ub.nil?
      Glpk_wrapper.glp_set_col_bnds(@p.lp, @j, type, lb, ub)
    end

    def bounds
      t = Glpk_wrapper.glp_get_col_type(@p.lp, @j)
      lb = Glpk_wrapper.glp_get_col_lb(@p.lp, @j)
      ub = Glpk_wrapper.glp_get_col_ub(@p.lp, @j)

      lb = (t == GLP_FR or t == GLP_UP) ? nil : lb
      ub = (t == GLP_FR or t == GLP_LO) ? nil : ub

      [t, lb, ub]
    end

    def set(v)
      raise RuntimeError unless v.size == @p.rows.size
      ind = Glpk_wrapper.new_intArray(v.size + 1)
      val = Glpk_wrapper.new_doubleArray(v.size + 1)

      1.upto(v.size){|x| Glpk_wrapper.intArray_setitem(ind, x, x)}
      v.each_with_index{|x, y|
        Glpk_wrapper.doubleArray_setitem(val, y + 1, x)}

      Glpk_wrapper.glp_set_mat_col(@p.lp, @j, v.size, ind, val)

      Glpk_wrapper.delete_intArray(ind)
      Glpk_wrapper.delete_doubleArray(val)
    end

    def get
      ind = Glpk_wrapper.new_intArray(@p.rows.size + 1)
      val = Glpk_wrapper.new_doubleArray(@p.rows.size + 1)
      len = Glpk_wrapper.glp_get_mat_col(@p.lp, @j, ind, val)
      col = Array.new(@p.rows.size, 0)
      len.times do |i|
        v = Glpk_wrapper.doubleArray_getitem(val, i + 1)
        j = Glpk_wrapper.intArray_getitem(ind, i + 1)
        col[j - 1] = v
      end
      Glpk_wrapper.delete_intArray(ind)
      Glpk_wrapper.delete_doubleArray(val)
      col
    end

    def get_prim
      Glpk_wrapper.glp_get_col_prim(@p.lp, @j)
    end

    def mip_val
      Glpk_wrapper.glp_mip_col_val(@p.lp, @j)
    end
  end

  class ObjectiveFunction

    def initialize(problem)
      @p = problem
    end

    def name=(n)
      Glpk_wrapper.glp_set_obj_name(@p.lp, n)
    end

    def name
      Glpk_wrapper.glp_get_obj_name(@p.lp)
    end

    def dir=(d)
      raise ArgumentError if d != GLP_MIN and d != GLP_MAX
      Glpk_wrapper.glp_set_obj_dir(@p.lp, d)
    end

    def dir
      Glpk_wrapper.glp_get_obj_dir(@p.lp)
    end

    def set_coef(j, coef)
      Glpk_wrapper.glp_set_obj_coef(@p.lp, j, coef)
    end

    def coefs=(a)
      @p.cols.each{|c| Glpk_wrapper.glp_set_obj_coef(@p.lp, c.j, a[c.j - 1])}
      a
    end

    def coefs
      @p.cols.map{|c| Glpk_wrapper.glp_get_obj_coef(@p.lp, c.j)}
    end

    def get
      Glpk_wrapper.glp_get_obj_val(@p.lp)
    end

    def mip
      Glpk_wrapper.glp_mip_obj_val(@p.lp)
    end
  end
end
require 'model'
%w(constant constraint objective term term_array var).map{|name| "ilp/#{name}" }.each(&method(:require))

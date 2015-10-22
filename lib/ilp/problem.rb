module Ilp
  class Problem

    attr_accessor :problem


    def read(model)
      vars = model.vars
      constraints = model.constraints
      objective = model.objective

      @problem = Rglpk::Problem.new

      unless vars.empty?
        problem.add_cols(vars.length)
        current_col_idx = 0
        @column_idx = Hash.new
        vars.each do |var|
          col = problem.cols[current_col_idx]
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
        problem.add_rows(constraints.length)
        current_row_idx = 0
        constraints.each do |constraint|
          coefs = Array.new(problem.cols.size, 0)
          constraint.terms.each do |term|
            coefs[@column_idx[term.var]] += term.mult
          end
          row = problem.rows[current_row_idx]
          row.set(coefs)
          row.set_bounds(constraint.type, constraint.bound, constraint.bound)
          current_row_idx += 1
        end
      end

      unless objective.nil?
        problem.obj.dir = objective.objective_function
        coefs = Array.new(problem.cols.size, 0)
        objective.terms.each do |term|
          coefs[@column_idx[term.var]] = term.mult
        end
        problem.obj.coefs = coefs
      end
    end

    def mip(params = {})
      @sol_type = :mip
      params[:presolve] = Rglpk::GLP_ON

      problem.mip(params)
    end

    def simplex(params = {})
      @sol_type = :simplex
      problem.simplex(params)
    end


    def value_of(var)
      if var.is_a? String
        col = problem.cols[var]
      else
        col = problem.cols[@column_idx[var]]
      end
      if @sol_type == :mip
        col.mip_val
      else
        col.get_prim
      end
    end

    def obj_value
      if @sol_type == :mip
        Glpk_wrapper.glp_mip_obj_val(problem.lp)
      else
        Glpk_wrapper.glp_get_obj_val(problem.lp)
      end

    end

    def write_to_file(filename)
      Glpk_wrapper.glp_write_lp(problem.lp, nil, filename)
    end

    def found_solution
      status = Glpk_wrapper.glp_mip_status(problem.lp)
      status == Rglpk::GLP_FEAS || status == Rglpk::GLP_OPT
    end

  private
  end



end

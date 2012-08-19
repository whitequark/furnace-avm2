module Furnace::AVM2
  module Transform
    class PartialEvaluation
      # Fuck you, ECMA-262. Fuck you ten thousand times.
      class ConstantFolder
        # Either returns an astlet, which should then be
        # constant, or nil, which means a non-constant expression.
        def fold(expr)
          case expr.type
          when :true, :false, :null, :nan, :undefined, :integer, :double
            expr

          when :"===", :"!==", :"==", :"!="
            args = expr.children.map { |e| fold e }
            return nil unless args.all?

            case expr.type
            when :"==="
              emit strict_compare(*args)
            when :"!=="
              emit !strict_compare(*args)

            when :"=="
              emit compare(*args)
            when :"!="
              emit !compare(*args)
            end
          end
        end

        # Part 11.9.6
        def strict_compare(x, y)
          # .1
          if x.type != y.type
            return false
          end

          # .2, .3
          if undefined?(x) || null?(x)
            return true
          end

          # .4, .5, .6
          # Subpoints of .4 are implemented by Ruby.
          if string?(x) || number?(x) || boolean?(x)
            return value(x) == value(y)
          end

          # .7
          # No objects here.

          false
        end

        # Part 11.9.3
        # Fuck you, ECMA-262, once again.
        # Relevant: http://destroyallsoftware.com/talks/wat
        def compare(x, y)
          # .1
          if x.type == y.type
            return strict_compare(x, y)
          end

          # .2, .3
          if null?(x) && undefined?(y) ||
             undefined?(x) && null?(x)
            return true
          end

          # .4
          if number?(x) && string?(y)
            return compare(x, to_number(y))
          end

          # .5
          if string?(x) && number?(y)
            return compare(to_number(x), y)
          end

          # .6
          if boolean?(x)
            return compare(to_number(x), y)
          end

          # .7
          if boolean?(y)
            return compare(x, to_number(y))
          end

          # .8, .9
          # No objects here.

          # .10
          false
        end

        # Part 9.2
        def to_boolean(x)
          if undefined?(x)
            emit false
          elsif null?(x)
            emit false
          elsif boolean?(x)
            x
          elsif number?(x)
            num = value(x)
            emit (num == 0 || num.nan?)
          elsif string?(x)
            str = value(x)
            emit (str == "")
          else
            true
          end
        end

        # Part 9.3
        def to_number(x)
          if undefined?(x)
            emit Float::NAN
          elsif null?(x)
            emit 0
          elsif boolean?(x)
            emit value(x) ? 1 : 0
          elsif number?(x)
            x
          elsif string?(x)
            # .1 I hate you all.
            str = value(x).strip
            if str =~ %r{^([+-]?)Infinity$}
              if $1 == "-"
                emit -Float::Infinity
              else
                emit Float::Infinity
              end
            elsif str =~ %r{^[+-]?(\d+\.?\d*|\.\d+)[eE][+-]?\d+$}
              emit str.to_f
            elsif str =~ %r{^0[xX]([\da-fA-F]+)$}
              emit $1.to_i(16)
            else
              emit Float::NaN
            end
          end
        end

        def undefined?(x)
          x.type == :undefined
        end

        def null?(x)
          x.type == :null
        end

        def nan?(x)
          x.type == :nan
        end

        def number?(x)
          x.type == :integer || x.type == :double
        end

        def string?(x)
          x.type == :string
        end

        def boolean?(x)
          x.type == :true || x.type == :false
        end

        def value(x)
          if x.type == :true
            true
          elsif x.type == :false
            false
          elsif x.type == :null || x.type == :undefined
            x.type
          elsif x.type == :nan
            Float::NAN
          else
            x.children[0]
          end
        end

        def emit(what)
          case what
          when true
            AST::Node.new(:true)
          when false
            AST::Node.new(:false)
          when :null
            AST::Node.new(:null)
          when :undefined
            AST::Node.new(:undefined)
          when Integer
            AST::Node.new(:integer, [ what ])
          when Float
            if what.nan?
              AST::Node.new(:nan)
            else
              AST::Node.new(:double, [ what ])
            end
          when String
            AST::Node.new(:string, [ what ])
          else
            raise "cannot emit #{what.inspect}"
          end
        end
      end

      def transform(cfg)
        changed = false

        constant_folder = ConstantFolder.new

        cfg.nodes.each do |block|
          if block.cti && block.cti.type == :branch_if
            compare_to, expr = block.cti.children
            if folded = constant_folder.fold(expr)
              folded = constant_folder.to_boolean(folded)
              value = constant_folder.value folded

              if value ^ compare_to
                block.target_labels = [ block.target_labels[1] ]
              else
                block.target_labels = [ block.target_labels[0] ]
              end

              block.insns.delete block.cti
              block.cti = nil

              changed = true
            end
          end
        end

        if changed
          cfg
        end
      end
    end
  end
end
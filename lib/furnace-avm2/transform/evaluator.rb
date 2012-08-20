module Furnace::AVM2
  module Transform
    # Fuck you, ECMA-262. Fuck you ten thousand times.
    class Evaluator
      # Either returns an astlet, which should then be
      # constant, or nil, which means a non-constant expression.
      def fold(expr)
        if immediate? expr
          expr
        else
          case expr.type
          when :this
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

          when :or, :and
            left, right = expr.children
            if left = fold(left)
              left_value = value(to_boolean(left))
              compare_to = (expr.type == :and ? true : false)

              if left_value ^ compare_to
                left
              else
                right
              end
            end
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
          emit true
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

      def immediate?(x)
        [ :true, :false, :null, :nan, :undefined,
          :integer, :double, :string ].include? x.type
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
        elsif x.type == :null ||
              x.type == :undefined
          x.type
        elsif x.type == :nan
          Float::NAN
        elsif x.type == :string  ||
              x.type == :integer ||
              x.type == :double
          x.children[0]
        else
          raise "cannot get value of #{x.inspect}"
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
  end
end
module Mutant
  class Mutator
    class Node
      module NamedValue

        # Mutation emitter to handle value access nodes
        class Access < Node

          handle(:gvar, :cvar, :ivar, :lvar)

        private

          # Emit mutations
          #
          # @return [undefined]
          #
          # @api private
          #
          def dispatch
            emit_nil
          end

        end # Access
      end # NamedValue
    end # Node
  end # Mutator
end # Mutant

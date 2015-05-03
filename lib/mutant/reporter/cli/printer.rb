module Mutant
  class Reporter
    class CLI
      # CLI runner status printer base class
      class Printer
        include AbstractType, Delegator, Adamantium::Flat, Concord.new(:output, :object)

        private_class_method :new

        delegate(:success?)

        NL = "\n".freeze

        # Run printer on object to output
        #
        # @param [IO] output
        # @param [Object] object
        #
        # @return [self]
        #
        # @api private
        #
        def self.run(output, object)
          new(output, object).run
          self
        end

        # Run printer
        #
        # @return [self]
        #
        # @api private
        #
        abstract_method :run

      private

        # Return status color
        #
        # @return [Color]
        #
        # @api private
        #
        def status_color
          success? ? Color::GREEN : Color::RED
        end

        # Visit a collection of objects
        #
        # @return [Class::Printer] printer
        # @return [Enumerable<Object>] collection
        #
        # @return [undefined]
        #
        # @api private
        #
        def visit_collection(printer, collection)
          collection.each do |object|
            visit(printer, object)
          end
        end

        # Visit object
        #
        # @param [Class::Printer] printer
        # @param [Object] object
        #
        # @return [undefined]
        #
        # @api private
        #
        def visit(printer, object)
          printer.run(output, object)
        end

        # Print an info line to output
        #
        # @return [undefined]
        #
        # @api private
        #
        def info(string, *arguments)
          puts(format(string, *arguments))
        end

        # Print a status line to output
        #
        # @return [undefined]
        #
        # @api private
        #
        def status(string, *arguments)
          puts(colorize(status_color, format(string, *arguments)))
        end

        # Print a line to output
        #
        # @return [undefined]
        #
        # @api private
        #
        def puts(string)
          output.puts(string)
        end

        # Colorize message
        #
        # @param [Color] color
        # @param [String] message
        #
        # @api private
        #
        # @return [String]
        #   if color is enabled
        #   unmodified message otherwise
        #
        def colorize(color, message)
          color = Color::NONE unless tty?
          color.format(message)
        end

        # Test if output is a tty
        #
        # @return [Boolean]
        #
        # @api private
        #
        def tty?
          output.tty?
        end

        # Test if output can be colored
        #
        # @return [Boolean]
        #
        # @api private
        #
        alias_method :color?, :tty?

        # Env progress printer
        class EnvProgress < self

          delegate(
            :coverage,
            :amount_subjects,
            :amount_mutations,
            :amount_mutations_alive,
            :amount_mutations_killed,
            :runtime,
            :killtime,
            :overhead,
            :env
          )

          # Run printer
          #
          # @return [undefined]
          #
          # @api private
          #
          # rubocop:disable MethodLength
          #
          def run
            visit(Config, env.config)
            info 'Subjects:        %s',        amount_subjects
            info 'Mutations:       %s',        amount_mutations
            info 'Kills:           %s',        amount_mutations_killed
            info 'Alive:           %s',        amount_mutations_alive
            info 'Runtime:         %0.2fs',    runtime
            info 'Killtime:        %0.2fs',    killtime
            info 'Overhead:        %0.2f%%',   overhead_percent
            status 'Coverage:        %0.2f%%', coverage_percent
            status 'Expected:        %0.2f%%', (env.config.expected_coverage * 100)
          end

        private

          # Return coverage percent
          #
          # @return [Float]
          #
          # @api private
          #
          def coverage_percent
            coverage * 100
          end

          # Return overhead percent
          #
          # @return [Float]
          #
          # @api private
          #
          def overhead_percent
            (overhead / killtime) * 100
          end

        end # EnvProgress

        # Full env result reporter
        class EnvResult < self

          delegate(:failed_subject_results)

          # Run printer
          #
          # @return [undefined]
          #
          # @api private
          #
          def run
            visit_collection(SubjectResult, failed_subject_results)
            visit(EnvProgress, object)
          end

        end # EnvResult

        # Subject report printer
        class SubjectResult < self

          delegate :subject, :failed_mutations, :tests

          # Run report printer
          #
          # @return [undefined]
          #
          # @api private
          #
          def run
            status(subject.identification)
            tests.each do |test|
              puts("- #{test.identification}")
            end
            visit_collection(MutationResult, object.alive_mutation_results)
          end

        end # Subject

        # Printer for mutation progress results
        class MutationProgressResult < self

          SUCCESS = '.'.freeze
          FAILURE = 'F'.freeze

          # Run printer
          #
          # @return [undefined]
          #
          # @api private
          #
          def run
            char(success? ? SUCCESS : FAILURE)
          end

        private

          # Write colorized char
          #
          # @param [String] char
          #
          # @return [undefined]
          #
          # @api private
          #
          def char(char)
            output.write(colorize(status_color, char))
          end

        end # MutationProgressResult

        # Reporter for progressive output format on scheduler Status objects
        class StatusProgressive < self

          FORMAT = '(%02d/%02d) %3d%% - killtime: %0.02fs runtime: %0.02fs overhead: %0.02fs'.freeze

          delegate(
            :coverage,
            :runtime,
            :amount_mutations_killed,
            :amount_mutations,
            :amount_mutation_results,
            :killtime,
            :overhead
          )

          # Run printer
          #
          # @return [undefined]
          #
          # @api private
          #
          def run
            status(
              FORMAT,
              amount_mutations_killed,
              amount_mutations,
              coverage * 100,
              killtime,
              runtime,
              overhead
            )
          end

        private

          # Return object being printed
          #
          # @return [Result::Env]
          #
          # @api private
          #
          def object
            super.payload
          end
        end

        # Reporter for subject progress
        class SubjectProgress < self

          FORMAT = '(%02d/%02d) %3d%% - killtime: %0.02fs runtime: %0.02fs overhead: %0.02fs'.freeze

          delegate(
            :tests,
            :subject,
            :coverage,
            :runtime,
            :amount_mutations_killed,
            :amount_mutations,
            :amount_mutation_results,
            :killtime,
            :overhead
          )

          # Run printer
          #
          # @return [undefined]
          #
          # @api private
          #
          def run
            puts("#{subject.identification} mutations: #{amount_mutations}")
            print_mutation_results
            print_progress_bar_finish
            print_stats
            print_tests
          end

        private

          # Print stats
          #
          # @return [undefined]
          #
          # @api private
          #
          def print_stats
            status(
              FORMAT,
              amount_mutations_killed,
              amount_mutations,
              coverage * 100,
              killtime,
              runtime,
              overhead
            )
          end

          # Print tests
          #
          # @return [undefined]
          #
          # @api private
          #
          def print_tests
            tests.each do |test|
              puts "- #{test.identification}"
            end
          end

          # Print progress bar finish
          #
          # @return [undefined]
          #
          # @api private
          #
          def print_progress_bar_finish
            puts(NL) unless amount_mutation_results.zero?
          end

          # Print mutation results
          #
          # @return [undefined]
          #
          # @api private
          #
          def print_mutation_results
            visit_collection(MutationProgressResult, object.mutation_results)
          end

        end # Subject

        # Test result reporter
        class TestResult < self

          delegate :tests, :runtime

          STATUS_FORMAT = '- %d @ runtime: %s'.freeze

          # Run test result reporter
          #
          # @return [undefined]
          #
          # @api private
          #
          def run
            status(STATUS_FORMAT, tests.length, runtime)
            tests.each do |test|
              puts("  - #{test.identification}")
            end
            puts('Test Output:')
            puts(object.output)
          end

        private

          # Test if test result is successful
          #
          # Only used to determine color.
          #
          # @return [false]
          #
          # @api private
          #
          def success?
            false
          end

        end # TestResult
      end # Printer
    end # CLI
  end # Reporter
end # Mutant

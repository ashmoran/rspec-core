require 'drb/drb'

module Rspec
  module Core

    class Runner

      def self.installed_at_exit?
        @installed_at_exit ||= false
      end

      def self.autorun
        return if installed_at_exit?
        @installed_at_exit = true
        at_exit { new.run(ARGV, $stderr, $stdout) ? exit(0) : exit(1) }
      end

      def require_all_files(configuration)
        configuration.files_to_run.map {|f| require f }
      end

      # TODO drb port
      class DRbProxy
        def initialize(options)
          @argv = options[:argv]
          @remote_port = options[:remote_port] # TODO default remote DRb port
        end

        # def self.port(options)
        #   (options.drb_port || ENV["RSPEC_DRB"] || 8989).to_i
        # end

        def run(err, out)
          begin
            begin; \
              DRb.start_service("druby://localhost:0"); \
            rescue SocketError, Errno::EADDRNOTAVAIL; \
              DRb.start_service("druby://:0"); \
            end
            spec_server = DRbObject.new_with_uri("druby://127.0.0.1:#{@remote_port}")
            spec_server.run(@argv, err, out)
            true
          rescue DRb::DRbConnError
            err.puts "No server is running"
            false
          end
        end
      end

      class InProcess
        attr_reader :configuration

        def initialize(configuration)
          @configuration = configuration
        end

        def reporter
          configuration.formatter
        end

        def require_all_files(configuration)
          configuration.files_to_run.map {|f| require f }
        end

        def run(err, out)
          configuration.output = out # TODO move!

          require_all_files(configuration)

          total_examples_to_run = Rspec::Core.world.total_examples_to_run

          old_sync, reporter.output.sync = reporter.output.sync, true if reporter.output.respond_to?(:sync=)

          suite_success = true

          reporter_supports_sync = reporter.output.respond_to?(:sync=)
          old_sync, reporter.output.sync = reporter.output.sync, true if reporter_supports_sync

          reporter.start(total_examples_to_run) # start the clock
          start = Time.now

          Rspec::Core.world.example_groups_to_run.each do |example_group|
            suite_success &= example_group.run(reporter)
          end

          reporter.start_dump(Time.now - start)

          reporter.dump_failures
          reporter.dump_summary
          reporter.dump_pending
          reporter.close

          reporter.output.sync = old_sync if reporter_supports_sync

          suite_success
        end
      end

      # TODO WIP
      def run(args = [], err, out)
        options = Rspec::Core::CommandLineOptions.parse(args)

        if options.version?
          out.puts("rspec " + ::Rspec::Core::Version::STRING)
          # TODO this is copied in from RSpec 1.3
          # exit if stdout?
        elsif options.drb?
          # TODO check if it's possible to send a Configuration over Drb, and if so, unify the interface
          DRbProxy.new(:argv => options.to_drb_argv, :remote_port => options.drb_port || ENV['RSPEC_DRB'].to_i).run(err, out)
        else
          configuration = Rspec.configuration
          options.apply(configuration)
          InProcess.new(configuration).run(err, out)
        end
      end

    end

  end
end

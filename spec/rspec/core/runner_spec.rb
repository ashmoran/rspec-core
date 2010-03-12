require 'spec_helper'

describe Rspec::Core::Runner do

  describe 'reporter' do
    
    pending 'should return the configured formatter' do
      Rspec::Core::Runner.new.reporter.should == Rspec.configuration.formatter
    end

  end  
  
  describe 'at_exit' do
    
    it 'should set an at_exit hook if none is already set' do
      Rspec::Core::Runner.stub!(:installed_at_exit?).and_return(false)
      Rspec::Core::Runner.should_receive(:at_exit)
      Rspec::Core::Runner.autorun
    end
    
    it 'should not set the at_exit hook if it is already set' do
      Rspec::Core::Runner.stub!(:installed_at_exit?).and_return(true)
      Rspec::Core::Runner.should_receive(:at_exit).never
      Rspec::Core::Runner.autorun
    end
    
  end
  
  # This is added in because the examples use --version
  describe "running with --version" do
    it "prints the version" do
      err, out = StringIO.new, StringIO.new
      Rspec::Core::Runner.new.run(%w[ --version ], err, out)
      out.rewind
      out.read.should match(/rspec \d+\.\d+\.\d+/n)
    end
  end
  
  # TODO move collaboration specs into this and cover the other situations
  describe "#run" do
    context "options indicate DRb" do
      before(:each) do
        @err, @out = mock("error stream"), mock("output stream")
        @drb_port, @drb_argv = mock(Fixnum), mock(Array)
        
        @options = stub(Rspec::Core::CommandLineOptions, :version? => false, :drb? => true, :drb_port => @drb_port, :to_drb_argv => @drb_argv)
        Rspec::Core::CommandLineOptions.stub(:parse => @options)
        
        @drb_proxy = mock(Rspec::Core::Runner::DRbProxy, :run => nil)
        Rspec::Core::Runner::DRbProxy.stub(:new => @drb_proxy)
      end
      
      it "builds a DRbProxy" do
        Rspec::Core::Runner::DRbProxy.should_receive(:new).with(:argv => @drb_argv, :remote_port => @drb_port)
        Rspec::Core::Runner.new.run(%w[ --unused-args ], @err, @out)
      end
      
      it "runs specs over the proxy" do
        @drb_proxy.should_receive(:run).with(@err, @out)
        Rspec::Core::Runner.new.run(%w[ --unused-args ], @err, @out)
      end
    end
  end
  
  # TODO unless jruby?
  describe "::DRbProxy" do
    context "without server running" do
      it "prints error" do
        # options = mock(Rspec::Core::CommandLineOptions, :drb? => true, :to_drb_argv => %w[ --version --drb ])
        err = out = StringIO.new
        Rspec::Core::Runner::DRbProxy.new(:argv => %w[ --version ], :remote_port => 1234).run(err, out)

        err.rewind
        err.read.should =~ /No server is running/
      end
      
      it "returns false" do
        err = out = StringIO.new
        result = Rspec::Core::Runner::DRbProxy.new(:argv => %w[ --version ], :remote_port => 1234).run(err, out)
        result.should be_false
      end
    end
    
    context "with server running" do
      class ::FakeDrbSpecServer
        def self.run(argv, stderr, stdout)
          # TODO fix nasty hackarounds for the singletons
          orig_configuration = Rspec.configuration
          Rspec.instance_variable_set("@configuration", Rspec::Core::Configuration.new)
          
          orig_world = Rspec::Core.world
          Rspec::Core.instance_variable_set("@world", Rspec::Core::World.new)
          
          Rspec::Core::Runner.new.run(argv, stderr, stdout)
        ensure
          Rspec::Core.instance_variable_set("@world", orig_world)
          Rspec.instance_variable_set("@configuration", orig_configuration)
        end
      end
    
      before(:all) do
        @@drb_port = 8989
        @@drb_example_file_counter = 0
      end
    
      before(:each) do
        @drb_port = @@drb_port
        # TODO cycling through the ports is a hack - why do we need to do it?
        @@drb_port += 1
        @fake_drb_server = DRb::DRbServer.new("druby://127.0.0.1:#{@drb_port}", ::FakeDrbSpecServer)
        create_dummy_spec_file
        @@drb_example_file_counter = @@drb_example_file_counter + 1
      end
  
      after(:each) do
        File.delete(@dummy_spec_filename)
        @fake_drb_server.stop_service
      end
    
      after(:all) do
        # DRb.stop_service
      end
    
      def create_dummy_spec_file
        @dummy_spec_filename = File.expand_path(File.dirname(__FILE__)) + "/_dummy_spec#{@@drb_example_file_counter}.rb"
        File.open(@dummy_spec_filename, 'w') do |f|
          f.write %{
            describe "DUMMY CONTEXT for 'DrbCommandLine with -c option'" do
              it "should be output with green bar" do
                true.should be_true
              end
    
              it "should be output with red bar" do
                fail "I want to see a red bar!"
              end
            end
          }
        end
      end
    
      def run_spec_via_druby(argv)
        err, out = StringIO.new, StringIO.new
        out.instance_eval do
          # TODO figure out why this makes 3specs fail
          # def tty?; true end
          def tty?; false end
        end
        Rspec::Core::Runner::DRbProxy.new(:argv => argv, :remote_port => drb_port).run(err, out)
        out.rewind
        out.read
      end
      
      def drb_port
        @drb_port
      end
    
      it "returns true" do
        err = out = StringIO.new
        result = Rspec::Core::Runner::DRbProxy.new(:argv => %w[ --version ], :remote_port => drb_port).run(err, out)
        result.should be_true
      end
    
      it "should run against local server" do
        out = run_spec_via_druby(['--version'])
        out.should =~ /rspec \d+\.\d+\.\d+.*/n
      end
    
      it "should output green colorized text when running with --colour option" do
        out = run_spec_via_druby(["--colour", @dummy_spec_filename])
        out.should =~ /\e\[32m/n
      end
    
      it "should output red colorized text when running with -c option" do
        out = run_spec_via_druby(["-c", @dummy_spec_filename])
        out.should =~ /\e\[31m/n
      end
      
      it "integrates via #run" do
        puts "QUACK"
        err = out = StringIO.new
        result = Rspec::Core::Runner.new.run(%W[ --drb --drb-port #{drb_port} --version ], err, out)
        result.should be_true
      end
    end
    
    context "port" do
      # before do
      #   @options = stub(Rspec::Core::CommandLineOptions, :drb? => true, :drb_port => nil)
      #   Rspec::Core::CommandLineOptions.stub(:parse => @options)
      # end
      # 
      # context "with no additional configuration" do
      #   it "defaults to 8989" do
      #     Rspec::Core::Runner::should == 8989
      #   end
      # end
      # 
      # context "with RSPEC_DRB environment variable set" do
      #   def with_RSPEC_DRB_set_to(val)
      #     original = ENV['RSPEC_DRB']
      #     begin
      #       ENV['RSPEC_DRB'] = val
      #       yield
      #     ensure
      #       ENV['RSPEC_DRB'] = original
      #     end
      #   end
      #   
      #   it "uses RSPEC_DRB value" do
      #     with_RSPEC_DRB_set_to('9000') do
      #       Spec::Runner::DrbCommandLine.port(@options).should == 9000
      #     end
      #   end
      #     
      #   context "and config variable set" do
      #     it "uses configured value" do
      #       @options.stub(:drb_port => '5000')
      #       with_RSPEC_DRB_set_to('9000') do
      #         Spec::Runner::DrbCommandLine.port(@options).should == 5000
      #       end
      #     end
      #   end
      #     
      # end
    end
  end
  
end

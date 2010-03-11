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
  
  describe "::Drb" do
    
  end
  
  # TODO unless jruby?
  describe "::Drb old" do
    context "without server running" do
      pending "prints error" do
        err = out = StringIO.new
        options = Rspec::Core::CommandLineOptions.parse(%w[ --version --drb ])
        Rspec::Core::Runner.new(options).run(options, err, out)

        err.rewind
        err.read.should =~ /No server is running/
      end
      
      # it "returns nil" do
      #   err = out = StringIO.new
      #   result = DrbCommandLine.run(OptionParser.parse(['--version'], err, out))
      #   result.should be_false
      # end
    end    

    # context "with server running" do
    #   class ::CommandLineForDrbSpec
    #     def self.run(argv, stderr, stdout)
    #       orig_options = Spec::Runner.options
    #       tmp_options = Spec::Runner::OptionParser.parse(argv, stderr, stdout)
    #       Spec::Runner.use tmp_options
    #       Spec::Runner::CommandLine.run(tmp_options)
    #     ensure
    #       Spec::Runner.use orig_options
    #     end
    #   end
    # 
    #   before(:all) do
    #     DRb.start_service("druby://127.0.0.1:8989", ::CommandLineForDrbSpec)
    #     @@drb_example_file_counter = 0
    #   end
    # 
    #   before(:each) do
    #     create_dummy_spec_file
    #     @@drb_example_file_counter = @@drb_example_file_counter + 1
    #   end
    # 
    #   after(:each) do
    #     File.delete(@dummy_spec_filename)
    #   end
    # 
    #   after(:all) do
    #     DRb.stop_service
    #   end
    # 
    #   it "returns true" do
    #     err = out = StringIO.new
    #     result = DrbCommandLine.run(OptionParser.parse(['--version'], err, out))
    #     result.should be_true
    #   end
    # 
    #   it "should run against local server" do
    #     out = run_spec_via_druby(['--version'])
    #     out.should =~ /rspec \d+\.\d+\.\d+.*/n
    #   end
    # 
    #   it "should output green colorized text when running with --colour option" do
    #     out = run_spec_via_druby(["--colour", @dummy_spec_filename])
    #     out.should =~ /\e\[32m/n
    #   end
    # 
    #   it "should output red colorized text when running with -c option" do
    #     out = run_spec_via_druby(["-c", @dummy_spec_filename])
    #     out.should =~ /\e\[31m/n
    #   end
    # 
    #   def create_dummy_spec_file
    #     @dummy_spec_filename = File.expand_path(File.dirname(__FILE__)) + "/_dummy_spec#{@@drb_example_file_counter}.rb"
    #     File.open(@dummy_spec_filename, 'w') do |f|
    #       f.write %{
    #         describe "DUMMY CONTEXT for 'DrbCommandLine with -c option'" do
    #           it "should be output with green bar" do
    #             true.should be_true
    #           end
    # 
    #           it "should be output with red bar" do
    #             violated("I want to see a red bar!")
    #           end
    #         end
    #       }
    #     end
    #   end
    # 
    #   def run_spec_via_druby(argv)
    #     err, out = StringIO.new, StringIO.new
    #     out.instance_eval do
    #       def tty?; true end
    #     end
    #     options = ::Spec::Runner::Options.new(err, out)
    #     options.argv = argv
    #     Spec::Runner::DrbCommandLine.run(options)
    #     out.rewind; out.read
    #   end
    # end

    # context "#port" do
    #   before do
    #     @options = stub("options", :drb_port => nil)
    #   end
    #   
    #   context "with no additional configuration" do
    #     it "defaults to 8989" do
    #       Spec::Runner::DrbCommandLine.port(@options).should == 8989
    #     end
    #   end
    #   
    #   context "with RSPEC_DRB environment variable set" do
    #     def with_RSPEC_DRB_set_to(val)
    #       original = ENV['RSPEC_DRB']
    #       begin
    #         ENV['RSPEC_DRB'] = val
    #         yield
    #       ensure
    #         ENV['RSPEC_DRB'] = original
    #       end
    #     end
    #     
    #     it "uses RSPEC_DRB value" do
    #       with_RSPEC_DRB_set_to('9000') do
    #         Spec::Runner::DrbCommandLine.port(@options).should == 9000
    #       end
    #     end
    # 
    #     context "and config variable set" do
    #       it "uses configured value" do
    #         @options.stub(:drb_port => '5000')
    #         with_RSPEC_DRB_set_to('9000') do
    #           Spec::Runner::DrbCommandLine.port(@options).should == 5000
    #         end
    #       end
    #     end
    # 
    #   end
    # end
  end
  
  # describe "#run" do
  #   before(:each) do
  #     @parsed_options = mock("Parsed Options", :drb? => nil, :apply => nil)
  #     Rspec::Core::CommandLineOptions.stub(:parse => @parsed_options)
  #     @runner_strategy = mock("Runner Strategy")
  # 
  #     @runner = Rspec::Core::Runner.new
  #   end
  #   
  #   it "parses the options" do
  #     Rspec::Core::CommandLineOptions.should_receive(:parse).with([])# => @parsed_options)
  #     @runner.run(%[ --colour --drb ])
  #   end
  #   
  #   context "when the options indicate Drb" do
  #     before(:each) do
  #       @parsed_options.stub(:drb? => true)
  #     end
  # 
  #     it "uses a Drb runner" do
  #       Rspec::Core::Runner::Drb.should_receive(:new).with(@parsed_options).and_return(@runner_strategy)
  #       @runner_strategy.should_receive(:run)
  #       @runner.run
  #     end
  #   end
  #   
  #   context "when the options indicate no Drb" do
  #     before(:each) do
  #       @parsed_options.stub(:drb? => false)
  #       @configuration = mock(Rspec::Core::Configuration)
  #       Rspec::Core::Runner.stub(:configuration).and_return(@configuration)
  #     end
  #     
  #     it "applies the options to the Configuration" do
  #       @parsed_options.should_receive(:apply).with(@configuration)
  #     end
  #     
  #     it "uses an InProcess runner" do
  #       Rspec::Core::Runner::InProcess.should_receive(:new).with(@configuration).and_return(@runner_strategy)
  #       @runner_strategy.should_receive(:run)
  #       @runner.run
  #     end
  #   end
  # end
end

require 'spec_helper'
require 'ostruct'

describe Rspec::Core::CommandLineOptions do
  
  def options_from_args(*args)
    parse(*args).options
  end
  
  def options_from_args_and_options_file(*args)
    parse(*args).merge_options_file.options
  end
  
  def parse(*args)
    Rspec::Core::CommandLineOptions.new(args).parse
  end

  describe 'color_enabled' do
    example "-c, --colour, or --color should be parsed as true" do
      options_from_args('-c').should include(:color_enabled => true)
      options_from_args('--color').should include(:color_enabled => true)
      options_from_args('--colour').should include(:color_enabled => true)
    end

    example "--no-color should be parsed as false" do
      options_from_args('--no-color').should include(:color_enabled => false)
    end
  end

  describe  'formatter' do
    example '-f or --formatter with no arguments should be parsed as nil' do
      options_from_args('--formatter').should include(:formatter => nil)
    end

    example '-f or --formatter with an argument should parse' do
      options_from_args('--formatter', 'd').should include(:formatter => 'd')
      options_from_args('-f', 'd').should include(:formatter => 'd')
      options_from_args('-fd').should include(:formatter => 'd')
    end
  end

  describe 'profile_examples' do
    example "-p or --profile should be parsed as true" do
      options_from_args('-p').should include(:profile_examples => true)
      options_from_args('--profile').should include(:profile_examples => true)
    end
  end

  describe 'line_number' do
    it "is parsed from -l or --line_number" do
      options_from_args('-l','3').should include(:line_number => '3')
      options_from_args('--line_number','3').should include(:line_number => '3')
    end
  end

  describe "example" do
    it "is parsed from --example or -e" do
      options_from_args('--example','foo').should include(:full_description => /foo/)
      options_from_args('-e','bar').should include(:full_description => /bar/)
    end
  end

  describe "options" do
    it "is parsed from --options or -o" do
      options_from_args('--options', 'spec/spec.opts').should include(:options_file => "spec/spec.opts")
      options_from_args('-o', 'foo/spec.opts').should include(:options_file => "foo/spec.opts")
    end

    it "defaults to spec/spec.opts when you don't give it a file path" do
      options_from_args('-o').should include(:options_file => "spec/spec.opts")
      options_from_args('--options').should include(:options_file => "spec/spec.opts")
    end

    it "loads automatically" do
      cli_options = Rspec::Core::CommandLineOptions.new([]).parse
      File.stub(:exist?) { true }
      File.stub(:readlines) { ["--formatter", "doc"] }
      config = OpenStruct.new
      cli_options.apply(config)
      config.formatter.should == 'doc'
    end

    it "allows options on one line" do
      cli_options = Rspec::Core::CommandLineOptions.new([]).parse
      File.stub(:exist?) { true }
      File.stub(:readlines) { ["--formatter doc"] }
      config = OpenStruct.new
      cli_options.apply(config)
      config.formatter.should == 'doc'
    end
    
    it "merges options from the CLI and file options gracefully" do
      cli_options = Rspec::Core::CommandLineOptions.new(['--formatter', 'progress', '--options', 'spec/spec.opts']).parse
      cli_options.stub!(:parse_spec_file_contents).and_return(:full_backtrace => true)
      config = OpenStruct.new
      cli_options.apply(config)
      config.full_backtrace.should == true
      config.formatter.should == 'progress'
    end

    it "CLI options trump file options" do
      cli_options = Rspec::Core::CommandLineOptions.new(['--formatter', 'progress', '--options', 'spec/spec.opts']).parse
      cli_options.stub!(:parse_spec_file_contents).and_return(:formatter => 'documentation')
      config = OpenStruct.new
      cli_options.apply(config)
      config.formatter.should == 'progress'
    end
  end

  describe "files_or_directories_to_run" do
    it "parses files from '-c file.rb dir/file.rb'" do
      options_from_args("-c", "file.rb", "dir/file.rb").should include(:files_or_directories_to_run => ["file.rb", "dir/file.rb"])
    end

    it "parses dir from 'dir'" do
      options_from_args("dir").should include(:files_or_directories_to_run => ["dir"])
    end

    it "parses dir and files from 'spec/file1_spec.rb, spec/file2_spec.rb'" do
      options_from_args("dir", "spec/file1_spec.rb", "spec/file2_spec.rb").should include(:files_or_directories_to_run => ["dir", "spec/file1_spec.rb", "spec/file2_spec.rb"])
    end

  end

  describe "--backtrace (-b)" do
    it "sets full_backtrace on config" do
      options_from_args("--backtrace").should include(:full_backtrace => true)
      options_from_args("-b").should include(:full_backtrace => true)
    end
  end

  describe "--debug (-d)" do
    it "sets debug on config" do
      options_from_args("--debug").should include(:debug => true)
      options_from_args("-d").should include(:debug => true)
    end
  end
  
  describe "--drb (-X)" do
    context "combined with --debug" do
      it "turns off the debugger if --drb is specified first" do
        options_from_args("--drb", "--debug").should include(:debug => false)
        options_from_args("--drb", "-d"     ).should include(:debug => false)
        options_from_args("-X",    "--debug").should include(:debug => false)
        options_from_args("-X",    "-d"     ).should include(:debug => false)
      end
      
      it "turns off the debugger option if --drb is specified later" do      
        options_from_args("--debug", "--drb").should include(:debug => false)
        options_from_args("-d",      "--drb").should include(:debug => false)
        options_from_args("--debug", "-X"   ).should include(:debug => false)
        options_from_args("-d",      "-X"   ).should include(:debug => false)
      end
      
      it "turns off the debugger option if --drb is specified in the options file" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb  ] }
        options_from_args_and_options_file("--debug").should include(:debug => false)
        options_from_args_and_options_file("-d"     ).should include(:debug => false)        
      end
      
      it "turns off the debugger option if --debug is specified in the options file" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --debug  ] }
        options_from_args_and_options_file("--drb").should include(:debug => false)
        options_from_args_and_options_file("-X"   ).should include(:debug => false)
      end
    end
    
    it "sends all the arguments other than --drb back to the parser after parsing options" do
      options_from_args("--drb", "--colour").should_not have_key(:drb)
    end
    
    it "records that it is a drb" do
      options = parse("--colour", "--drb")
      options.should be_drb
    end
    
    it "records that it is a drb if --drb comes from the options file" do
      File.stub(:exist?) { true }
      File.stub(:readlines) { %w[ --drb  ] }
      options = parse.merge_options_file
      options.should be_drb
    end
    
    it "does not record that it is a drb if --drb is absent" do
      options = parse("--colour")
      options.should_not be_drb
    end  
  end
  
  describe "--drb-port" do
    it "sets the DRb port" do
      parse("--drb-port", "1234").drb_port.should == 1234
      parse("--drb-port", "5678").drb_port.should == 5678
    end
  end
  
  # TODO #to_drb_argv may not be the best name
  # TODO ensure all options are output
  # TODO check if we need to spec that the short options are "expanded"
  describe "#to_drb_argv" do
    context "--drb specified in ARGV" do
      it "renders all the original arguments except --drb" do
        # no --options
        # using eq rather than =~ because of the arguments that take options
        parse(*%w[ --drb --colour --formatter s --line_number 1 --example pattern --profile --backtrace]).
          to_drb_argv.should eq(%w[ --colour --formatter s --line_number 1 --example pattern --profile --backtrace ])
      end
    end

    context "--drb specified in the options file" do
      it "renders all the original arguments except --drb" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb --colour ] }
        parse(*%w[ --formatter s --line_number 1 --example pattern --profile --backtrace ]).merge_options_file.
          to_drb_argv.should eq(%w[ --colour --formatter s --line_number 1 --example pattern --profile --backtrace ])
      end
    end

    context "--drb specified in ARGV and the options file" do
      it "renders all the original arguments except --drb" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb --colour ] }
        parse(*%w[ --drb --formatter s --line_number 1 --example pattern --profile --backtrace]).merge_options_file.
          to_drb_argv.should eq(%w[ --colour --formatter s --line_number 1 --example pattern --profile --backtrace ])          
      end
    end

    context "--drb specified in ARGV and in as ARGV-specified --options file" do
      it "renders all the original arguments except --drb and --options" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb --colour ] }
        parse(*%w[ --drb --options my_spec.opts --formatter s --line_number 1 --example pattern --profile --backtrace]).merge_options_file.
          to_drb_argv.should eq(%w[ --colour --formatter s --line_number 1 --example pattern --profile --backtrace ])          
      end
    end
  end

  describe "version?" do
    it "is set to true when --version is detected" do
      parse("--version").version?.should be_true
      parse("-v"       ).version?.should be_true
    end

    it "is set to false when --version is absent" do
      parse([]).version?.should be_false
    end
  end
  
end


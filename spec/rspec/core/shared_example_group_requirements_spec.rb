require 'spec_helper'

module RSpec::Core
  describe SharedExampleGroup::Requirements do
    it "lets you specify requirements for shared example groups" do
      shared_examples_for("thing") do
        require_instance_method :configuration_instance_method, "message"
        require_instance_method :host_instance_method, "message"
        
        require_instance_method :configuration_let, "message"
        require_instance_method :host_let, "message"
        
        # TODO: Should we allow an alias specifically for `let`? eg:
        # parameter :host_variable, "message"
        # (`let` currently just uses `define_method`)
        
        require_instance_variable :@configuration_instance_variable, "message"
        require_instance_variable :@host_instance_variable, "message"
        
        require_class_method :configuration_class_method, "message"
        require_class_method :host_class_method, "message"
        
        it "lets you access the instance methods" do
          configuration_instance_method.should eq "configuration_instance_method"
          host_instance_method.should eq "host_instance_method"

          configuration_let.should eq "configuration_let"
          host_let.should eq "host_let"
          
          @configuration_instance_variable.should  eq "@configuration_instance_variable"
          @host_instance_variable.should eq "@host_instance_variable"
        end
        
        it "lets you access #{configuration_class_method}s and #{host_class_method}s" do
          self.class.configuration_class_method.should eq "configuration_class_method"
          self.class.host_class_method.should eq "host_class_method"
        end

        it "lets you access #{configuration_class_method}s and #{host_class_method}s in the example" do
          configuration_class_method.should eq "configuration_class_method"
          host_class_method.should eq "host_class_method"
        end
      end

      group = ExampleGroup.describe("group") do
        def self.host_class_method
          "host_class_method"
        end 
        def host_instance_method
          "host_instance_method"
        end 
        let(:host_let) { "host_let" }
        before(:each) { @host_instance_variable = "@host_instance_variable" }
        
        it_should_behave_like "thing" do
          def self.configuration_class_method
            "configuration_class_method"
          end 
          def configuration_instance_method
            "configuration_instance_method"
          end
          let(:configuration_let) { "configuration_let" }
          before(:each) { @configuration_instance_variable = "@configuration_instance_variable" }
        end
      end
      
      group.run_all.should be_true
    end
    
    describe "#require_instance_method" do
      it "raises an ArgumentError if the host example group doesn't provide the specified instance method" do
        shared_examples_for("thing") do
          require_instance_method :provided_method, "description of what provided_method provides"
          it "will fail this example" do
            provided_method
          end
          it "but it doesn't depend on the method being called" do
          end          
        end

        group = ExampleGroup.describe("group") do
          it_should_behave_like "thing"
        end

        # I don't know why the examples are wrapped in another array
        examples = group.descendant_filtered_examples.flatten
      
        group.run_all
      
        examples.each do |example|
          example.execution_result[:status].should eq 'failed'
          example.execution_result[:exception_encountered].should be_an(ArgumentError)
          example.execution_result[:exception_encountered].message.should eq 'Shared example group requires instance method :provided_method (description of what provided_method provides)'
          # TODO: Will require storing the fact that groups generated from shared examples were generated so
          # example.execution_result[:exception_encountered].message.should eq 'Shared example group "thing" ...'
        end
      end
    end
    
    describe "#require_class_method" do
      it "raises an ArgumentError if the host example group doesn't provide the specified class method" do
        shared_examples_for("thing") do
          require_class_method :example_class_method, "description of what example_class_method provides"
          it "will fail this example #{example_class_method}" do
            example_class_method.should eq "a comparison that should never get run"
          end
        end
      
        group = ExampleGroup.describe("group") do
          it_should_behave_like "thing"
        end
      
        # I don't know why the examples are wrapped in another array
        example = group.descendant_filtered_examples.flatten.first
      
        group.run_all
      
        example.execution_result[:status].should eq 'failed'
        example.execution_result[:exception_encountered].should be_an(ArgumentError)
        example.execution_result[:exception_encountered].message.should eq 'Shared example group requires class method :example_class_method (description of what example_class_method provides)'
        # TODO: Will require storing the fact that groups generated from shared examples were generated so
        # example.execution_result[:exception_encountered].message.should eq 'Shared example group "thing" ...'
      end
      
      it "raises an ArgumentError even if the class method is used in the example definitions" do
        shared_examples_for("thing") do
          require_class_method :example_class_method, "description of what example_class_method provides"
          it "will fail this example but not because we use #{example_class_method} here" do
            example_class_method.should eq "a comparison that should never get run"
          end
        end

        group = ExampleGroup.describe("group") do
          it_should_behave_like "thing"
        end

        # I don't know why the examples are wrapped in another array
        example = group.descendant_filtered_examples.flatten.first
      
        group.run_all
      
        example.execution_result[:status].should eq 'failed'
        example.execution_result[:exception_encountered].should be_an(ArgumentError)
        example.execution_result[:exception_encountered].message.should eq 'Shared example group requires class method :example_class_method (description of what example_class_method provides)'
        # TODO: Will require storing the fact that groups generated from shared examples were generated so
        # example.execution_result[:exception_encountered].message.should eq 'Shared example group "thing" ...'
      end
      
      it "defaults the class method to a message that indicates the error" do
        shared_examples_for("thing") do
          require_class_method :example_class_method, "description of what example_class_method provides"
          it "puts a descriptive message here: #{example_class_method}" do
          end
        end

        group = ExampleGroup.describe("group") do
          it_should_behave_like "thing"
        end

        # I don't know why the examples are wrapped in another array
        example = group.descendant_filtered_examples.flatten.first
              
        example.description.should eq 'puts a descriptive message here: <missing class method "example_class_method">'
      end
    end 
  end
end

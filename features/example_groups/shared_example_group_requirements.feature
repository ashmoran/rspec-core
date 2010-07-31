Feature: Shared example group

  As an RSpec user
  I want to define the requirements of my shared examples
  So that other RSpec users can re-use them more easily

  Scenario: Provide all shared examples requirements
    Given a file named "shared_example_group_spec.rb" with:
    """
    shared_examples_for "a collection object" do
      require_class_method :class_name, "the name of collection class"
      require_instance_method :collection_class, "the collection class to be instantiated"
      require_instance_variable :@initial_collection, "the values used to seed the collection"
      
      let(:instance) { collection_class.new(@initial_collection) }

      it "preserves all the initial elements" do
        instance.size.should == @initial_collection.size
      end
      
      it "has class name #{class_name}" do
        collection_class.name.should eq class_name
      end

      describe "#first" do
        it "returns the first item" do
          instance.first.should == 7
        end
      end
    end

    describe Array do
      it_should_behave_like "a collection object" do
        def self.class_name; "Array"; end
        let(:collection_class) { Array }
        before(:each) { @initial_collection = [7, 2, 4] }
      end
    end
    """
    When I run "rspec shared_example_group_spec.rb --format documentation"
    Then the output should contain "3 examples, 0 failures"
    And the output should contain:
      """
      Array
        it should behave like a collection object
          preserves all the initial elements
          has class name Array
          #first
            returns the first item
      """
  

  Scenario: Omit required instance method from the host example group
    Given a file named "shared_example_group_spec.rb" with:
    """
    shared_examples_for "a collection object" do
      require_instance_method :collection_class, "the collection class to be instantiated"
      
      it "fails this example" do
      end
    end

    describe Array do
      it_should_behave_like "a collection object"
    end
    """
    When I run "rspec shared_example_group_spec.rb --format documentation"
    Then the output should contain "1 example, 1 failure"
    And the output should contain:
      """
      Shared example group requires instance method :collection_class (the collection class to be instantiated)
      """
  
  Scenario: Omit required class method from the host example group
    Given a file named "shared_example_group_spec.rb" with:
    """
    shared_examples_for "a collection object" do
      require_class_method :class_name, "the name of collection class"
      
      it "fails this example which uses #{class_name}" do
      end
    end

    describe Array do
      it_should_behave_like "a collection object"
    end
    """
    When I run "rspec shared_example_group_spec.rb --format documentation"
    Then the output should contain "1 example, 1 failure"
    And the output should contain:
      """
      Shared example group requires class method :class_name (the name of collection class)
      """
  
  Scenario: Omit required instance variable from the host example group
    Given a file named "shared_example_group_spec.rb" with:
    """
    shared_examples_for "a collection object" do
      require_instance_variable :@initial_collection, "the values used to seed the collection"
    
      it "fails this example" do
      end
    end

    describe Array do
      it_should_behave_like "a collection object"
    end
    """
    When I run "rspec shared_example_group_spec.rb --format documentation"
    Then the output should contain "1 example, 1 failure"
    And the output should contain:
      """
      Shared example group requires instance variable @initial_collection (the values used to seed the collection)
      """

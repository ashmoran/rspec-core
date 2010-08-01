# Enable this spectaculary useful Ruby 1.9 method in Ruby 1.8
# If this stays in the code, it needs a proper home - leaving it
# here in the mean time for readablility's sake.
unless respond_to?(:define_singleton_method)
  class Object
    def define_singleton_method(name, &block)
      class << self; self; end.class_eval do
        define_method(name, &block)
      end
    end
  end
end

module RSpec
  module Core
    module SharedExampleGroup

      module Requirements
        def require_instance_method(name, description)
          before(:each) do
            unless respond_to?(name)
              raise ArgumentError.new(%'Shared example group requires instance method :#{name} (#{description})')
            end
          end
        end
        
        def require_instance_variable(name, description)
          before(:each) do
            unless instance_variable_defined?(name)
              raise ArgumentError.new(%'Shared example group requires instance variable #{name} (#{description})')
            end
          end
        end
        
        def require_class_method(name, description)
          if respond_to?(name)
            define_method(name) do |*args|
              self.class.send(name, *args)
            end
          else
            before(:each) do
              raise ArgumentError.new(%'Shared example group requires class method :#{name} (#{description})')
            end
            define_singleton_method(name) do |*args|
              %'<missing class method "#{name}">'
            end
          end
        end
      end
      
    end
  end
end
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
            self.class.class_eval do
              define_method(name) do |*args|
                # TODO: This needs a spec, but there are issues with class methods in general
                %'<missing class method "#{name}">'
              end
            end
          end
        end
      end
      
    end
  end
end
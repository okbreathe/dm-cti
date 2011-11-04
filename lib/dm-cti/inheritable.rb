module DataMapper
  module CTI
    module Inheritable

      def descendant_of(parent_model)
        parent_model = DataMapper::Inflector.constantize(DataMapper::Inflector.classify(parent_model.to_s))
        parent       = DataMapper::Inflector.underscore(parent_model.to_s).to_sym
        child        = DataMapper::Inflector.underscore(self).to_sym

        class << self
          attr_accessor :table_ancestors, :cti_options
        end

        @cti_options     = {:parent => parent, :parent_model => parent_model}
        @table_ancestors = (parent_model.respond_to?(:table_ancestors) ? parent_model.table_ancestors.dup : []) << parent_model

        parent_model.has 1, child, :constraint => :destroy

        parent_model.validates_with_method child, :method => :valid_child?

        parent_model.send :define_method, :valid_child? do
          return true unless (descendant = send(child))
          descendant.valid?
          descendant.errors.delete(DataMapper::Inflector.foreign_key(self.class).to_sym)
          descendant.errors.any? ? [false, "#{child} was invalid"] : true
        end

        belongs_to parent

        after :destroy do
          send(parent).destroy
        end

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1

          # Always create the parent when initializing if it doesn't exist
          def initialize(attributes = nil) # :nodoc:
            unless #{parent}
              self.#{parent} = #{parent_model}.new 
              self.#{parent}.#{child} = self
            end
            super
          end

          # Return the root ancestor of the current object
          def table_root
            #{table_ancestors.reverse.inject([]){|m,a| m << "#{DataMapper::Inflector.underscore(a)}"}.join('.')}
          end

        RUBY

        extend ClassMethods
        include InstanceMethods

      end

      def is_table_descendant?
        false
      end

      module ClassMethods

        def table_parent_model
          table_ancestors.last
        end

        def table_root_model
          table_ancestors.first
        end

        def is_table_descendant?
          true
        end

        def finalize
          super
          unless cti_options[:finalized]
            cti_options[:finalized] = true

            delegations = []

            table_ancestors.each { |ancestor|
              ancestor.relationships.each do |relationship|
                next if relationship.parent_model.is_table_descendant? || relationship.child_model.is_table_descendant?
                delegations.concat([relationship.name.to_sym,:"#{relationship.name}="])
              end
              delegations.concat ancestor.properties.inject([]) { |m,p| 
                m.concat([p.name,:"#{p.name}="]) unless p.kind_of?(DataMapper::Property::Serial); m 
              }
            } 

            delegate *delegations, :to => cti_options[:parent] 

          end
        end
      end

      module InstanceMethods

        # Destroy resource from the top down
        def destroy_inherited_resource
          table_root.destroy
        end

        # Combine ancestors errors
        def errors
          @errors ||= begin
            errors = ::DataMapper::Validations::ValidationErrors.new(self)
            parent = send("#{DataMapper::Inflector.underscore self.class.table_parent_model}")
            parent.errors.send(:errors).each do |field_name,messages|
              messages.each { |message| errors.add(field_name, message) } 
            end
            errors
          end
        end

        # Combine ancestors attributes
        def attributes(key_on = :name)
          super.merge(send("#{DataMapper::Inflector.underscore self.class.table_parent_model}").attributes)
        end

      end

    end # Inheritable
  end # Is
end # DataMapper

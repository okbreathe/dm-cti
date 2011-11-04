module DataMapper
  module CTI
    module Inheritable

      ##
      # Only if you need top-down access
      # Adds a discriminator column on the super class
      #
      def table_superclass
        property :sub_type, String

        @table_superclass = true

        ## 
        # Get the descendant of the 
        #
        # ==== Usage
        #
        # class Product
        #   ..
        #   table_superclass
        # end
        #
        # class Book
        #   ..
        #   descendant_of :product
        # end
        #
        # class Video
        #   ..
        #   descendant_of :product
        # end
        #
        # product = Product.get_as_descendant 1 # instance of Book
        #
        # product = Product.get_as_descendant 2 # instance of Video
        #
        def self.get_as_descendant(id)
          inflector    = DataMapper::Inflector
          resource     = get(id)
          target_class = inflector.constantize(resource.sub_type)
          ancestors    = target_class.table_ancestors + [target_class]
          ancestors.slice(1,ancestors.length).inject(resource) do |m,tbl|
            m.send(inflector.underscore(tbl))
          end
        end

        ##
        # Same as get_as_descendant, but pass an options hash with :as_descendant
        # to load the objects descendant
        def self.get(*args)
          opts = args.last.kind_of?(Hash) ? args.pop : {}
          opts[:as_descendant] ? get_as_descendant(*args) : super
        end
      end

      def descendant_of(parent_model)
        inflector    = DataMapper::Inflector
        parent_model = inflector.constantize(inflector.classify(parent_model.to_s))
        parent       = inflector.underscore(parent_model.to_s).to_sym
        child        = inflector.underscore(self).to_sym

        @cti_options      = {:parent => parent, :parent_model => parent_model}
        @table_ancestors  = (parent_model.respond_to?(:table_ancestors) ? parent_model.table_ancestors.dup : []) << parent_model
        @table_descendant = true

        parent_model.has 1, child, :constraint => :destroy

        parent_model.validates_with_method child, :method => :valid_child?

        parent_model.send :define_method, :valid_child? do
          return true unless (descendant = send(child))
          descendant.valid?
          descendant.errors.delete(inflector.foreign_key(self.class).to_sym)
          descendant.errors.any? ? [false, "#{child} was invalid"] : true
        end

        belongs_to parent

        before :save do
          table_root.sub_type = self.class.to_s if table_root.class.is_table_superclass?
        end

        after :destroy do
          table_parent.destroy
        end

        extend ClassMethods
        include InstanceMethods

        self.class_eval <<-RUBY, __FILE__, __LINE__ + 1

          # Always create the parent when initializing if it doesn't exist
          def initialize(*) # :nodoc:
            self.#{parent} ||= #{parent_model}.new(:#{child} => self)
            super
          end

          # Return the root ancestor of the current object
          def table_root
            #{table_ancestors.reverse.inject([]){|m,a| m << "#{inflector.underscore(a)}"}.join('.')}
          end

        RUBY
      end

      def is_table_descendant?
        !!@table_descendant
      end

      def is_table_superclass?
        !!@table_superclass
      end

      module ClassMethods

        def table_parent_model
          table_ancestors.last
        end

        def table_root_model
          table_ancestors.first
        end

        def table_ancestors
          @table_ancestors
        end

        def cti_options
          @cti_options
        end

        def finalize
          super
          unless cti_options[:finalized]
            cti_options[:finalized] = true

            delegations = []

            table_ancestors.each { |ancestor|
              ancestor.relationships.each do |relationship|
                next if relationship.parent_model.is_table_descendant? || relationship.child_model.is_table_descendant?
                assoc = [ relationship.name.to_sym, :"#{relationship.name}=" ]
                unless relationship.kind_of?(DataMapper::Associations::OneToMany::Relationship)
                  fk = DataMapper::Inflector.foreign_key(relationship.name)
                  assoc.concat([fk,:"#{fk}="])
                end
                delegations.concat(assoc)
              end
              delegations.concat ancestor.properties.inject([]) { |m,p| 
                m.concat([p.name,:"#{p.name}="]) unless p.kind_of?(DataMapper::Property::Serial); m 
              }
            } 

            delegate *delegations, :to => cti_options[:parent] 

          end
        end
      end # ClassMethods

      module InstanceMethods

        # Destroy resource from the top down
        def destroy_inherited_resource
          table_root.destroy
        end

        def table_parent
          send("#{DataMapper::Inflector.underscore self.class.table_parent_model}")
        end

        # Combine ancestors errors
        def errors
          @errors ||= begin
            errors = super
            table_parent.errors.send(:errors).each do |field_name,messages|
              messages.each { |message| errors.add(field_name, message) } 
            end
            errors
          end
        end

        # Combine ancestors attributes
        def attributes(key_on = :name)
          super.merge(table_parent.attributes)
        end

        def save
          table_parent.save if table_parent.dirty?
          super
        end

      end # InstanceMethods

    end # Inheritable
  end # Is
end # DataMapper

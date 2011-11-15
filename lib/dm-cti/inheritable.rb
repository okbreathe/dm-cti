module DataMapper
  module CTI
    module Inheritable

      ##
      # Only if you need top-down access
      # Adds a discriminator-like String column on the super class
      #
      # ==== Note
      # If you want to specify your own logic, pass false as the argument
      # You'll need to define set_table_type, which should set the
      # discriminator property otherwise it will be unable to save resources.
      def table_superclass(add_discriminator = true)
        @table_superclass  = true
        @table_descendants = []

        def table_descendants
          @table_descendants
        end

        if add_discriminator
          property :sub_type, String

          ## 
          # 'Typecast' a parent model into a descendant model
          #
          # ==== Usage
          #
          # class Product
          #   table_superclass
          # end
          #
          # class Book
          #   descendant_of :product
          # end
          #
          # class Video
          #   descendant_of :product
          # end
          #
          # product = Product.get_as_descendant 1 # instance of Book
          # product = Product.get_as_descendant 2 # instance of Video
          #
          def get_as_descendant(id)
            resource     = get(id)
            target_class = DataMapper::Inflector.constantize(resource.sub_type)
            ancestors    = target_class.table_ancestors + [target_class]
            ancestors.slice(1,ancestors.length).inject(resource) do |m,tbl|
              m.send(DataMapper::Inflector.underscore(tbl))
            end
          end

          define_method :set_table_type do |descendant|
            if self.class.table_descendants.include?(descendant.class)
              self.sub_type = descendant.class.to_s 
            end
          end
        end

      end

      def descendant_of(parent_model)
        inflector         = DataMapper::Inflector
        parent_model_name = inflector.classify(parent_model.to_s)
        parent            = inflector.underscore(parent_model.to_s).to_sym
        child             = inflector.underscore(self).to_sym

        @cti_options      = {:parent => parent, :parent_model_name => parent_model_name, :child => child}
        @table_descendant = true

        belongs_to parent

        after :destroy do
          table_parent.destroy
        end

        extend ClassMethods
        include InstanceMethods

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

            inflector    = DataMapper::Inflector
            parent_model = cti_options[:parent_model] = ::Object.const_get(cti_options[:parent_model_name])
            child        = cti_options[:child]
            parent       = cti_options[:parent]

            parent_model.has 1, child, :constraint => :destroy

            # Parent model may have been finalized at this point
            parent_model.send(:finalize_allowed_writer_methods)

            meth = :"valid_table_child_#{child}?"

            parent_model.validates_with_method child, :method => meth

            parent_model.send(:define_method, meth) do
              return true unless (descendant = send(child))
              descendant.valid?
              errors.send(:errors).inject(descendant.errors) { |m,(field,msgs)| msgs.each { |msg| m.add(field, msg) }; m } 
              fks = descendant.class.table_ancestors.map{|a| DataMapper::Inflector.foreign_key(a).to_sym }
              descendant.errors.send(:errors).delete_if {|k,v| fks.include?(k) }
              descendant.errors.any? ? [false, "#{child} was invalid"] : true
            end

            @table_ancestors = (parent_model.respond_to?(:table_ancestors) ? parent_model.table_ancestors.dup : []) << parent_model

            if (tr = table_ancestors.first).is_table_superclass?
              tr.table_descendants << self
            end

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

            delegations = []

            table_ancestors.each { |ancestor|
              ancestor.relationships.each do |relationship|
                next if relationship.parent_model.is_table_descendant? || relationship.child_model.is_table_descendant?
                assoc = [ relationship.name.to_sym, :"#{relationship.name}=" ]
                unless relationship.kind_of?(DataMapper::Associations::OneToMany::Relationship)
                  fk = DataMapper::Inflector.foreign_key(relationship.name)
                  assoc.concat([fk.to_sym,:"#{fk}="])
                end
                delegations.concat(assoc)
              end
              delegations.concat ancestor.properties.inject([]) { |m,p| 
                m.concat([p.name.to_sym,:"#{p.name}="]) unless p.kind_of?(DataMapper::Property::Serial); m 
              }
            } 

            delegations.uniq!

            delegate *delegations, :to => parent
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

        # Combine ancestors attributes
        def attributes(key_on = :name)
          super.merge(table_parent.attributes)
        end

        def dirty_attributes
          super.merge(table_parent.dirty_attributes)
        end

        def save
          # If one of the parents has relationships not part of the CTI chain, we'll need to force a save
          if self.saved? && table_parent.saved? && table_parent.dirty?
            table_parent.save
          end
          table_root.set_table_type(self) if new? && table_root.class.is_table_superclass?
          super
        end

      end # InstanceMethods

    end # Inheritable
  end # Is
end # DataMapper

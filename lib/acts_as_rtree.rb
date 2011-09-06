require 'active_record/base'

module RTree
  module ActsAsRTree
    
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_rtree(options = {})
        configuration = { 
          :foreign_key => "parent_id", 
          :order => nil,
          :position_column => nil,
          :counter_cache => nil, 
          :after_add => [], 
          :before_add => [], 
          :after_remove => [], 
          :before_remove => [] }
        
        configuration.update(options) if options.is_a?(Hash)
        
        if configuration[:position_column] && self.column_names.include?(configuration[:position_column].to_s)
          configuration[:order] = configuration[:position_column]
        else
          configuration[:position_column] = nil
        end

        belongs_to :parent, 
          :class_name => name, 
          :foreign_key => configuration[:foreign_key], 
          :counter_cache => configuration[:counter_cache]
        
        has_many :children, 
          :class_name => name, 
          :foreign_key => configuration[:foreign_key], 
          :order => configuration[:order], 
          :dependent => :destroy, 
          :before_add => [:validate_node!].concat([configuration[:before_add]].flatten), 
          :after_add => configuration[:after_add], 
          :before_remove => configuration[:before_remove], 
          :after_remove => configuration[:after_remove]

        class_eval <<-EOV
          include RTree::Node
          include RTree::ActsAsRTree::RecordInstanceMethods

          def self.roots
            find(:all, :conditions => "#{configuration[:foreign_key]} IS NULL", :order => #{configuration[:order].nil? ? "nil" : %Q{"#{configuration[:order]}"}})
          end


          def self.root
            find(:first, :conditions => "#{configuration[:foreign_key]} IS NULL", :order => #{configuration[:order].nil? ? "nil" : %Q{"#{configuration[:order]}"}})
          end


          private

          def self.position_column
            #{configuration[:position_column] ? "'#{configuration[:position_column]}'" : "nil"}
          end
        EOV
        
        
        if configuration[:position_column] && (configuration[:position_column].to_s != 'position')
          class_eval <<-EOV
            def position
              #{configuration[:position_column]}
            end


            def position=(position)
              self.#{configuration[:position_column]} = position
            end
          EOV
        end
        
      end
    end
    
    module RecordInstanceMethods
      
      def remove_child(child)
        if children.include?(child)
          if self.class.position_column
            parent_id_key = self.class.reflect_on_association(:parent).options[:foreign_key]
            self.class.update_all("#{self.class.position_column} = (#{self.class.position_column} - 1)", "#{parent_id_key} = #{self.id} AND #{self.class.position_column} >= #{child.position}")
            child.position = nil
          end
          child.parent = nil
          child.save!
          children.reload
          child
        end
      end
      
      
      def remove_children
        removed = children.map do |child|
          child.parent = nil
          child.position = nil if self.class.position_column
          child.save!
          child
        end
        children.reload
        removed
      end
      
      
      protected
      
      def insert_child(child, position = nil)
        raise Exception, "Position not supported for #{self.class.name}" if position && !self.class.position_column
        child.detach!
        if self.class.position_column
          parent_id_key = self.class.reflect_on_association(:parent).options[:foreign_key]
          max_position = self.class.count(:conditions => "#{parent_id_key} = #{self.id}")
          child.position = (position ? [position.to_i, max_position].min : max_position)
          child.save!
          parent_id_key = self.class.reflect_on_association(:parent).options[:foreign_key]
          self.class.update_all("#{self.class.position_column} = (#{self.class.position_column} + 1)", "#{parent_id_key} = #{self.id} AND #{self.class.position_column} >= #{child.position}")
        end
        children << child
        children.reload
      end
      
    end
    
  end
end

ActiveRecord::Base.class_eval { include RTree::ActsAsRTree }

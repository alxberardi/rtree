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
        if children.to_a.include?(child)
          position_column = self.class.position_column
          if position_column
            child_position = child.position || 0
            child.update_attribute(position_column, nil)
          end
          if self.new_record?
            child.parent = nil
            children.delete(child)
            if position_column
              Array.wrap(children[child_position..-1]).each do |c|
                c.position = children.index(c)
              end
            end
          else
            parent_id_key = self.class.reflect_on_association(:parent).options[:foreign_key]
            child.update_attribute(parent_id_key, nil)
            children.reload
            if position_column
              self.class.update_all("#{self.class.position_column} = (#{self.class.position_column} - 1)", "#{parent_id_key} = #{self.id} AND #{self.class.position_column} >= #{child_position}")
            end
          end
          child
        end
      end
      
      
      def remove_children
        children.delete_all
        children
      end
      
      
      protected
      
      def insert_child(child, position = nil)
        position_column = self.class.position_column
        raise Exception, "Position not supported for #{self.class.name}" if position && !position_column
        if self.new_record?
          child.position = position ? [position.to_i, children.size].min : children.size
          if position
            child_position = [position.to_i, children.size].min
            children.insert(child_position, child)
            if position_column
              Array.wrap(children[child_position..-1]).each do |c|
                c.position = children.index(c)
              end
            end
          else
            children << child
          end
          children
        else
          children << child
          if position_column
            parent_id_key = self.class.reflect_on_association(:parent).options[:foreign_key]
            max_position = self.class.count(:conditions => "#{parent_id_key} = #{self.id}")
            child_position = (position ? [position.to_i, max_position].min : max_position)
            child.update_attribute(position_column, child_position)
            self.class.update_all("#{self.class.position_column} = (#{self.class.position_column} + 1)", "#{parent_id_key} = #{self.id} AND #{self.class.position_column} >= #{child_position}")
          end
          children.reload
        end
      end
      
    end
    
  end
end

ActiveRecord::Base.class_eval { include RTree::ActsAsRTree }

require 'active_record/base'

module RTree
  module ActsAsRTree
    
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_rtree(options = {})
        configuration = { 
          :foreign_key => "parent_id", 
          :order => nil, 
          :counter_cache => nil, 
          :after_add => [], 
          :before_add => [], 
          :after_remove => [], 
          :before_remove => [] }
        
        configuration.update(options) if options.is_a?(Hash)

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

          def self.roots
            find(:all, :conditions => "#{configuration[:foreign_key]} IS NULL", :order => #{configuration[:order].nil? ? "nil" : %Q{"#{configuration[:order]}"}})
          end

          def self.root
            find(:first, :conditions => "#{configuration[:foreign_key]} IS NULL", :order => #{configuration[:order].nil? ? "nil" : %Q{"#{configuration[:order]}"}})
          end
        EOV
      end
    end

  end
end

ActiveRecord::Base.class_eval { include RTree::ActsAsRTree }

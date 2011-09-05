require 'enumerator'
require 'active_support/core_ext'

module RTree
  
  module Node
  
    extend ActiveSupport::Concern
    
    module ClassMethods

      def inherited(subclass)
        super
        subclass.acceptable_child_types_array = self.acceptable_child_types
      end


      def acceptable_child_types
        acceptable_child_types_array.clone
      end


      def set_acceptable_child_types(*class_names)
        @acceptable_child_types = class_names.map { |c| c.to_s.classify }.uniq
      end
      
      
      def add_acceptable_child_types(*class_names)
        acceptable_child_types_array.concat(class_names.map { |c| c.to_s.classify }).uniq!
      end
      
      
      def clear_acceptable_child_types
        @acceptable_child_types = []
      end


      def acceptable_child?(child)
        acceptable_child_types_array.any? do |c|
          child.is_a?(c.constantize)
        end
      end


      def force_leaf_node!
        clear_acceptable_child_types
      end


      def leaf_node?
        acceptable_child_types.empty?
      end


      protected

      def acceptable_child_types_array
        @acceptable_child_types ||= [self.to_s]
      end


      def acceptable_child_types_array=(child_types)
        @acceptable_child_types = child_types
      end
      
    end


    module InstanceMethods

      # ----------------------------------------------------------------
      # Children
      # ----------------------------------------------------------------

      def add_child(child)
        if child.is_a?(Array)
          add_children_array(child)
        else
          validate_child!(child).detach!.parent = self
          children << child
        end
      end


      def add_children(*children)
        add_children_array(children)
      end


      def add_children_array(children)
        children.each { |c| add_child(c) }
        self.children
      end


      def remove_child(child)
        child = children.delete(child)
        child && child.parent = nil
        child
      end


      def remove_children
        removed = []
        until children.empty?
          removed_child = children.pop
          removed_child.parent = nil
          removed << removed_child
        end
        removed
      end


      def clear!
        each_node_reverse(&:detach!)
      end


      # ----------------------------------------------------------------
      # Tree nodes
      # ----------------------------------------------------------------

      def ancestors
        node, nodes = self, []
        nodes << node = node.parent while node.parent
        nodes
      end


      def root
        node = self
        node = node.parent while node.parent
        node
      end


      def leafs
        return [self] if leaf?
        children.map(&:leafs).flatten
      end


      # ----------------------------------------------------------------
      # Siblings
      # ----------------------------------------------------------------

      def siblings
        root? ? [] : parent.children - [self]
      end


      def next_sibling
        return nil if root?
        node_index = parent.children.index(self)
        parent.children.at(node_index + 1) if node_index
      end


      def previous_sibling
        return nil if root?
        node_index = parent.children.index(self)
        parent.children.at(node_index - 1) if node_index && node_index > 0
      end


      def first_sibling
        root? ? self : parent.children.first
      end


      def last_sibling
        root? ? self : parent.children.last
      end


      # ----------------------------------------------------------------
      # Node
      # ----------------------------------------------------------------

      def detach!
        return self if root?
        parent.remove_child(self)
      end


      # ----------------------------------------------------------------
      # Node properties
      # ----------------------------------------------------------------

      def root?
        parent.nil?
      end


      def leaf?
        children.empty?
      end


      def has_children?
        !leaf?
      end


      def first_sibling?
        first_sibling == self
      end


      def last_sibling?
        last_sibling == self
      end


      def height
        leaf? ? 0 : 1 + children.map { |child| child.height }.max
      end


      def depth
        root? ? 0 : 1 + parent.depth
      end


      def breadth
        root? ? 1 : parent.children.size
      end


      def size
        children.inject(1) { |sum, node| sum + node.size }
      end


      alias_method :level, :depth
      alias_method :levels, :height



      # ----------------------------------------------------------------
      # Tree traversal
      # ----------------------------------------------------------------


      def each_node(&action)
        action && action.call(self)
        [self] + each_descendant(&action)
      end


      alias_method :each, :each_node


      def each_node_reverse(&action)
        descendants = each_descendant_reverse(&action)
        action && action.call(self)
        descendants + [self]
      end


      def each_child(&action)
        children.each { |c| action && action.call(c) }
      end


      def each_descendant(&action)
        children.map { |c| c.each_node(&action) }.flatten
      end


      def each_descendant_reverse(&action)
        children.reverse.map { |c| c.each_node_reverse(&action) }.flatten
      end


      def depth_nodes(depth = nil)
        if depth.nil?
          root.depth_nodes(self.depth)
        elsif depth.zero?
          [self] if depth.zero?
        else
          children.map { |c| c.depth_nodes(depth - 1) }.flatten
        end
      end


      def height_nodes(height = nil)
        if height.nil?
          return root.height_nodes(self.height)
        end

        current_height = self.height
        queue = [self]

        until current_height == height || queue.empty?
          queue.map!(&:children).flatten!
          current_height -= 1
        end

        queue
      end


      def depth_each(&action)
        each_node(&action)
      end


      def depth_each_reverse(&action)
        each_node_reverse(&action)
      end


      def breadth_each(&action)
        queue = [self]
        nodes = []

        until queue.empty?
          nodes << (next_node = queue.shift)
          action && action.call(next_node)
          next_node.children.each { |child| queue.push(child) }
        end

        nodes
      end


      def path_to_root(&action)
        action && action.call(self)
        [self] + each_ancestor(&action)
      end


      def each_ancestor(&action)
        root? ? [] : parent.path_to_root(&action)
      end


      def path_from_root(&action)
        ancestors = each_ancestor_reverse(&action)
        action && action.call(self)
        ancestors + [self]
      end


      def each_ancestor_reverse(&action)
        root? ? [] : parent.path_from_root(&action)
      end


      def map_path_to_root(&action)
        map = []
        path_to_root { |n| map << ( action ? action.call(n) : n ) }
        map
      end


      def map_path_from_root(&action)
        map = []
        path_from_root { |n| map << ( action ? action.call(n) : n ) }
        map
      end


      def map_ancestors(&action)
        map = []
        each_ancestor { |n| map << ( action ? action.call(n) : n ) }
        map
      end


      def map_nodes(&action)
        map = []
        each_node { |n| map << ( action ? action.call(n) : n ) }
        map
      end
      
      alias_method :map, :map_nodes


      def map_descendants(&action)
        map = []
        each_descendant { |n| map << ( action ? action.call(n) : n ) }
        map
      end


      def depth_map(&action)
        map_nodes(&action)
      end


      def breadth_map(&action)
        map = []
        breadth_each { |n| map << ( action ? action.call(n) : n ) }
        map
      end



      # ----------------------------------------------------------------
      # Tree search
      # ----------------------------------------------------------------


      def find_node_by_content(content)
        find_node { |n| n.content == content }
      end


      def depth_search(&condition)
        find_node(&condition)
      end


      def depth_search_all(&condition)
        find_all_nodes(&condition)
      end


      def breadth_search(&condition)
        return nil unless condition
        breadth_each do |n|
          return n if condition.call(n)
        end
        nil
      end


      def breadth_search_all(&condition)
        nodes = []
        return nodes unless condition
        breadth_each do |n|
          nodes << n if condition.call(n)
        end
        nodes
      end


      def find_node(&condition)
        return nil unless condition
        each_node do |n|
          return n if condition.call(n)
        end
        nil
      end


      def find_all_nodes(&condition)
        nodes = []
        return nodes unless condition
        each_node do |n|
          nodes << n if condition.call(n)
        end
        nodes
      end
      
      
      def find_descendant(&condition)
        return nil unless condition
        each_descendant do |n|
          return n if condition.call(n)
        end
        nil
      end


      def find_all_descendants(&condition)
        nodes = []
        return nodes unless condition
        each_descendant do |n|
          nodes << n if condition.call(n)
        end
        nodes
      end
      
      
      def find_ancestor(&condition)
        return nil unless condition
        each_ancestor do |n|
          return n if condition.call(n)
        end
        nil
      end


      def find_all_ancestors(&condition)
        nodes = []
        return nodes unless condition
        each_ancestor do |n|
          nodes << n if condition.call(n)
        end
        nodes
      end



      # ----------------------------------------------------------------
      # Node content
      # ----------------------------------------------------------------


      def content
        nil
      end


      def has_content?
        !content.nil?
      end



      # ----------------------------------------------------------------
      # Enumerable
      # ----------------------------------------------------------------


      def <=>(other)
        return +1 if other.nil?
        self.content <=> other.content
      end

      include Enumerable


      # ----------------------------------------------------------------
      # Protected
      # ----------------------------------------------------------------

      protected

      def validate_parent!(node)
        node.nil? ? nil : validate_node!(node)
      end


      def validate_child!(node)
        raise Exception, "Instances of #{self.class.name} are set to always be leaf nodes" if self.class.leaf_node?
        child = validate_node!(node)
        raise Exception, "#{child.class.name} is not an acceptable child for #{self.class.name}" unless self.class.acceptable_child?(child)
        child
      end


      private

      def validate_node!(node)
        raise Exception, "#{node} is not a valid tree node" unless node.class <= RTree::Node
        node
      end

    end
    
  end
  
  
  
  module Base
    
    def parent
      @parent
    end
      
      
    def parent=(parent)
      @parent = validate_parent!(parent)
    end
      
    
    def children
      @children ||= []
    end
    
  end
  
  
  module Extended
    
    def [](content)
      find_node_by_content(content)
    end
    
    
    def <<(child)
      add_child(child)
    end
    
  end
  
  
  module TreeNode
    
    def self.included(base)
      base.send(:include, RTree::Base)
      base.send(:include, RTree::Node)
      base.send(:include, RTree::Extended)
      super
    end
    
  end
  
  
  class Tree
    
    include RTree::TreeNode
    
    attr_accessor :content
      
    def initialize(content = nil)
      @content = content
    end
    
    
    def self.wrap(node)
      if node.is_a?(self)
        node
      else
        self.new(node)
      end
    end
    
    
    def to_s
      content.to_s
    end
      
  end
  
end


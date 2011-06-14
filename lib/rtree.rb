require 'enumerator'

module RTree
  module TreeNode
      
    include Enumerable
      
    
    def has_content?
      !content.nil?
    end
      
      
    def parent
      @parent
    end
      
      
    def parent=(parent)
      @parent = validate_parent!(parent)
    end
      
    
    def detach!
      return self if root?
      parent.remove_child(self)
    end
    
      
    def children
      @children ||= []
    end
      
      
    def add_child(child)
      validate_node!(child).parent = self
      children << child
    end
      
      
    def <<(child)
      add_child(child)
    end
      
      
    def add_children(*children)
      add_children_array(children)
    end
      
      
    def add_children_array(children)
      children.each { |c| add_child(c) }
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
      
      
    def root
      node = self
      node = node.parent while node.parent
      node
    end
      
      
    def leafs
      return [self] if leaf?
      children.map(&:leafs).flatten
    end
      
      
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
      
      
    def depth_nodes(depth)
      return [self] if depth.zero?
      children.map { |c| c.depth_nodes(depth - 1) }.flatten
    end
      

    def height_nodes(height)
      current_height = self.height
      queue = [self]
        
      until queue.empty?
        next_node = queue.shift
        next_node.children.each { |child| queue.push child }
        if next_node.last_sibling?
          if current_height == height + 1
            return queue
          else
            current_height -= 1
          end
        end
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


    def each_node(&action)
      action && action.call(self)
      [self] + each_descendant(&action)
    end


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


    def path_to_root(&action)
      action && action.call(self)
      [self] + each_parent(&action)
    end


    def each_parent(&action)
      root? ? [] : parent.path_to_root(&action)
    end


    def path_from_root(&action)
      parents = each_parent_reverse(&action)
      action && action.call(self)
      parents + [self]
    end


    def each_parent_reverse(&action)
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


    def map_parents(&action)
      map = []
      each_parent { |n| map << ( action ? action.call(n) : n ) }
      map
    end
      
      
    def each(&action)
      each_node(&action)
    end

      
    def <=>(other)
      return +1 if other.nil?
      self.content <=> other.content
    end
      
      
    def [](content)
      find_node { |n| n.content == content  }
    end
      

    def map(&action)
      map = []
      each_node { |n| map << ( action ? action.call(n) : n ) }
      map
    end


    def map_descendants(&action)
      map = []
      each_descendant { |n| map << ( action ? action.call(n) : n ) }
      map
    end
      
      
    def depth_map(&action)
      map(&action)
    end
      
      
    def breadth_map(&action)
      map = []
      breadth_each { |n| map << ( action ? action.call(n) : n ) }
      map
    end
      
      
    def depth_search(&condition)
      find_node(&condition)
    end


    def depth_search_all(&condition)
      find_all_nodes(&condition)
    end
      
      
    def breadth_search(&condition)
      breadth_each do |n|
        return n if condition && condition.call(n)
      end
      nil
    end
      
      
    def breadth_search_all(&condition)
      nodes = []
      breadth_each do |n|
        nodes << n if condition && condition.call(n)
      end
      nodes
    end


    def find_node(&condition)
      each_node do |n|
        return n if condition && condition.call(n)
      end
      nil
    end


    def find_all_nodes(&condition)
      nodes = []
      each_node do |n|
        nodes << n if condition && condition.call(n)
      end
      nodes
    end
    
    
    alias_method :find, :find_node
    alias_method :find_all, :find_all_nodes
    
    
    def content
      @content
    end
    
    
    def content=(content)
      @content = content
    end
    
      
    def to_s
      content.to_s
    end
    
      
    protected
      
    def validate_parent!(node)
      node.nil? ? nil : validate_node!(node)
    end
      
      
    def validate_node!(node)
      raise Exception, "#{node} is not a tree node" unless node.class <= RTree::TreeNode
      node
    end
    

  end
    
    
  class Tree
      
    include RTree::TreeNode
      
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
      
  end
end


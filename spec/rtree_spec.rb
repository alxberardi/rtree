require 'rtree'

class TreeBuilder
  def self.build(depth, breadth, node = nil)
    node ||= RTree::Tree.new("root")
    if depth > 0
      breadth.times do |i|
        node.add_child(self.build(depth - 1, breadth, RTree::Tree.new("#{node.content}_child_#{i}")))
      end
    end
    node
  end
end


describe RTree::Tree, "upon creation with content" do
  before do
    @node = RTree::Tree.new("test")
  end
  
  it "should save the content" do
    @node.has_content?.should be_true
    @node.content.should eql "test"
  end
end

describe RTree::Tree, "upon creation without content" do
  it "should have no content" do
    tree = RTree::Tree.new
    tree.has_content?.should be_false
    tree.content.should be_nil
  end
end

describe RTree::Tree, "after creation of the root node" do
  before do
    @root = RTree::Tree.new("root")
  end
  
  it "should allow adding a child" do
    child = RTree::Tree.new("1st child")
    @root.add_child(child)
    @root.children.size.should eql 1
    @root.children.should include child
    child.parent.should eql @root
  end
  
  
  it "should allow adding multiple children" do
    child1 = RTree::Tree.new("1st child")
    child2 = RTree::Tree.new("2nd child")
    child3 = RTree::Tree.new("3rd child")
    @root.add_children child1, child2, child3
    @root.children.size.should eql 3
    @root.children.should include child1
    @root.children.should include child2
    @root.children.should include child3
    child1.parent.should eql @root
    child2.parent.should eql @root
    child3.parent.should eql @root
  end
  
  it "should return the children array when adding a child" do
    child1 = RTree::Tree.new("1st child")
    child2 = RTree::Tree.new("2nd child")
    @root.add_child(child1)
    @root.add_child(child2).should eql @root.children
  end
  
  it "should return the children array when adding multiple children" do
    child1 = RTree::Tree.new("1st child")
    child2 = RTree::Tree.new("2nd child")
    child3 = RTree::Tree.new("3rd child")
    @root.add_child(child1)
    @root.add_children(child2, child3).should eql @root.children
  end
  
  it "shouldn't add the same child twice" do
    child = RTree::Tree.new("1st child")
    @root.add_child(child)
    @root.add_child(child)
    @root.children.size.should eql 1
  end
  
  it "should validate a child before adding it" do
    lambda { @root.add_child("not_a_tree_node") }.should raise_exception
  end
end

describe RTree::Tree, "after creating a tree with children" do
  before do
    @root = TreeBuilder.build(3, 2)
  end
  
  it "should return the correct size" do
    @root.size.should eql 15
  end
  
  it "should allow detaching a child" do
    lambda { @root.children[1].detach! }.should_not raise_exception
  end
  
  it "should correctly detach child when it's removed" do
    removed_child = @root.remove_child(@root.children[1])
    removed_child.should_not be_nil
    removed_child.content.should eql "root_child_1"
    removed_child.parent.should be_nil
    @root.children[1].should be_nil
    @root.size.should eql 8
  end
  
  it "should detach a node from its parent before adding it to the children of another node" do
    root_child = @root.children[1]
    root_child_child = @root.children[1].children[0]
    @root.add_child(root_child_child)
    root_child_child.parent.should eql @root
    @root.children.should include root_child_child
    root_child.children.should_not include root_child_child
  end
  
  it "should allow removing all children from a node" do
    removed_children = @root.children[1].remove_children
    removed_children.map(&:content).should eql ["root_child_1_child_1", "root_child_1_child_0"]
    @root.size.should eql 9
  end
  
  it "should allow clearing the tree by detaching all nodes" do
    detached_children = @root.clear!
    @root.size.should eql 1
    detached_children.each do |c|
      c.parent.should be_nil
    end
  end
  
  it "should return the tree leafs" do
    @root.leafs.map(&:content).should eql [
      "root_child_0_child_0_child_0", 
      "root_child_0_child_0_child_1", 
      "root_child_0_child_1_child_0", 
      "root_child_0_child_1_child_1", 
      "root_child_1_child_0_child_0", 
      "root_child_1_child_0_child_1", 
      "root_child_1_child_1_child_0", 
      "root_child_1_child_1_child_1" ]
  end
  
  it "should return all nodes at a certain depth" do
    @root.depth_nodes(1).map(&:content).should eql ["root_child_0", "root_child_1"]
  end
  
  it "should return all nodes at a certain height" do
    @root.height_nodes(2).map(&:content).should eql ["root_child_0", "root_child_1"]
  end
  
  it "should allow referencing a node by its content" do
    descendant = @root["root_child_1_child_0"]
    descendant.should_not be_nil
    descendant.content.should eql "root_child_1_child_0"
  end
end

describe RTree::Tree, "given the root node" do
  before do
    @root = TreeBuilder.build(3, 2)
  end
  
  it "referencing the root should return the same node" do
    @root.root.should eql @root
  end
  
  it "should return the correct height for the root" do
    @root.height.should eql 3
  end
  
  it "should return the correct depth for the root" do
    @root.depth.should eql 0
  end
  
  it "should return the correct breadth for the root" do
    @root.breadth.should eql 1
  end
  
  it "the root should have no siblings" do
    @root.siblings.should be_empty
  end
  
  it "the root should be the first and last sibling" do
    @root.should be_first_sibling
    @root.should be_last_sibling
  end
  
  it "the path from the node to the root should contain the root only" do
    @root.path_to_root.map(&:content).should eql ["root"]
  end
  
  it "the path from the node to the root should contain the root only" do
    @root.path_from_root.map(&:content).should eql ["root"]
  end
  
  it "should return all nodes on the same depth as the node" do
    @root.depth_nodes.map(&:content).should eql ["root"]
  end
  
  it "should return all nodes on the same height as the node" do
    @root.height_nodes.map(&:content).should eql ["root"]
  end
end

describe RTree::Tree, "given an internal node" do
  before do
    @root = TreeBuilder.build(3, 2)
    @node = @root["root_child_1_child_0"]
  end
  
  it "should allow referencing the root from the node" do
    @node.root.should eql @root
  end
  
  it "should return the correct height for the node" do
    @node.height.should eql 1
  end
  
  it "should return the correct depth for the node" do
    @node.depth.should eql 2
  end
  
  it "should return the correct breadth for the node" do
    @node.breadth.should eql 2
  end
  
  it "should allow referencing the node siblings" do
    @node.siblings.map(&:content).should eql ["root_child_1_child_1"]
    @node.next_sibling.content.should eql "root_child_1_child_1"
    @node.previous_sibling.should be_nil
    @node.next_sibling.previous_sibling.should eql @node
  end
  
  it "should allow to reference the first and last siblings" do
    @node.should be_first_sibling
    @node.next_sibling.should be_last_sibling
  end
  
  it "should return the path from the node to the root" do
    @node.path_to_root.map(&:content).should eql ["root_child_1_child_0", "root_child_1", "root"]
  end
  
  it "should return the path from the root to the node" do
    @node.path_from_root.map(&:content).should eql ["root", "root_child_1", "root_child_1_child_0"]
  end
  
  it "should return all nodes on the same depth as the node" do
    @node.depth_nodes.map(&:content).should eql [
      "root_child_0_child_0", 
      "root_child_0_child_1", 
      "root_child_1_child_0", 
      "root_child_1_child_1"]
  end
  
  it "should return all nodes on the same height as the node" do
    @node.height_nodes.map(&:content).should eql [
      "root_child_0_child_0", 
      "root_child_0_child_1", 
      "root_child_1_child_0", 
      "root_child_1_child_1"]
  end
end

describe RTree::Tree, "given a leaf node" do
  before do
    @root = TreeBuilder.build(3, 2)
    @node = @root["root_child_1_child_0_child_1"]
  end
  
  it "should allow referencing the root from the node" do
    @node.root.should eql @root
  end
  
  it "should return the correct height for the node" do
    @node.height.should eql 0
  end
  
  it "should return the correct depth for the node" do
    @node.depth.should eql 3
  end
  
  it "should return the correct breadth for the node" do
    @node.breadth.should eql 2
  end
  
  it "should allow referencing the node siblings" do
    @node.siblings.map(&:content).should eql ["root_child_1_child_0_child_0"]
    @node.next_sibling.should be_nil
    @node.previous_sibling.content.should eql "root_child_1_child_0_child_0"
    @node.previous_sibling.next_sibling.should eql @node
  end
  
  it "should allow to reference the first and last siblings" do
    @node.previous_sibling.should be_first_sibling
    @node.should be_last_sibling
  end
  
  it "should return the path from the node to the root" do
    @node.path_to_root.map(&:content).should eql ["root_child_1_child_0_child_1", "root_child_1_child_0", "root_child_1", "root"]
  end
  
  it "should return the path from the root to the node" do
    @node.path_from_root.map(&:content).should eql ["root", "root_child_1", "root_child_1_child_0", "root_child_1_child_0_child_1"]
  end
  
  it "should return all nodes on the same depth as the node" do
    @node.depth_nodes.map(&:content).should eql [
      "root_child_0_child_0_child_0",
      "root_child_0_child_0_child_1",
      "root_child_0_child_1_child_0",
      "root_child_0_child_1_child_1",
      "root_child_1_child_0_child_0",
      "root_child_1_child_0_child_1",
      "root_child_1_child_1_child_0",
      "root_child_1_child_1_child_1"]

  end
  
  it "should return all nodes on the same height as the node" do
    @node.height_nodes.map(&:content).should eql [
      "root_child_0_child_0_child_0",
      "root_child_0_child_0_child_1",
      "root_child_0_child_1_child_0",
      "root_child_0_child_1_child_1",
      "root_child_1_child_0_child_0",
      "root_child_1_child_0_child_1",
      "root_child_1_child_1_child_0",
      "root_child_1_child_1_child_1"]

  end
end

describe RTree::Tree, "when visiting the nodes" do
  before do
    @root = TreeBuilder.build(2, 2)
    @depth = [
      "root", 
      "root_child_0", 
      "root_child_0_child_0", 
      "root_child_0_child_1", 
      "root_child_1", 
      "root_child_1_child_0", 
      "root_child_1_child_1"]
    @breadth = [
      "root", 
      "root_child_0", 
      "root_child_1", 
      "root_child_0_child_0", 
      "root_child_0_child_1", 
      "root_child_1_child_0", 
      "root_child_1_child_1"]
  end
  
  it "should allow a depth visit on the nodes" do
    nodes = []
    @root.depth_each do |n|
      nodes << n.content
    end
    nodes.should eql @depth
  end
  
  it "should allow a breadth visit on the nodes" do
    nodes = []
    @root.breadth_each do |n|
      nodes << n.content
    end
    nodes.should eql @breadth
  end
  
  it "should allow a reverse depth visit on the nodes" do
    nodes = []
    @root.depth_each_reverse do |n|
      nodes << n.content
    end
    nodes.should eql @depth.reverse
  end
  
  it "should allow mapping the nodes in depth" do
    @root.depth_map(&:content).should eql @depth
  end
  
  it "should allow mapping the nodes in breadth" do
    @root.breadth_map(&:content).should eql @breadth
  end
end

describe RTree::Tree, "when searching for nodes" do
  before do
    @root = TreeBuilder.build(2, 2)
  end
  
  it "should allow searching for a single node that matches condition" do
    found_node = @root.find { |n| n.content == "root_child_1_child_0"}
    found_node.should_not be_nil
    found_node.content.should eql "root_child_1_child_0"
  end
  
  it "should allow searching for all nodes that match a condition" do
    found_nodes = @root.find_all { |n| n.content.start_with?("root_child_0")}
    found_nodes.should_not be_empty
    found_nodes.map(&:content).sort.should eql ["root_child_0", "root_child_0_child_0", "root_child_0_child_1"]
  end
  
  it "should allow searching in depth for all nodes that match a condition" do
    found_nodes = @root.depth_search_all { |n| n.content.start_with?("root_child")}
    found_nodes.should_not be_empty
    found_nodes.map(&:content).should eql [
      "root_child_0", 
      "root_child_0_child_0", 
      "root_child_0_child_1", 
      "root_child_1", 
      "root_child_1_child_0", 
      "root_child_1_child_1" ]
  end
  
  it "should allow searching in breadth for all nodes that match a condition" do
    found_nodes = @root.breadth_search_all { |n| n.content.start_with?("root_child")}
    found_nodes.should_not be_empty
    found_nodes.map(&:content).should eql [
      "root_child_0", 
      "root_child_1", 
      "root_child_0_child_0", 
      "root_child_0_child_1", 
      "root_child_1_child_0", 
      "root_child_1_child_1"]
  end
end

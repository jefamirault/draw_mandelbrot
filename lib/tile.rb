require 'set'
require 'pry-byebug'
require_relative 'tileset'
require "sinatra/activerecord"

class Tile < ActiveRecord::Base
  validates :coordA, uniqueness: { scope: :coordB}
  belongs_to :parent

  # Span of Complex Plane a single tile covers at Layer 1/Zoom 1.0
  TILE_SIZE = 1
  # Rendered Tile Resolution
  TILE_RESOLUTION = 200

  def pixel_width
    TILE_SIZE / TILE_RESOLUTION
  end

  def tile_width
    TILE_SIZE * 0.5 ** (layer - 1)
  end

  attr_accessor :tileset, :children, :render, :location

  # def initialize(options = {})
  #   options ||= {}
  #   @parent = options[:parent]
  #   @layer = @parent.nil? ? 1 : @parent.layer+1
  #   @neighbors = [nil, nil, nil, nil]
  #   @children = [nil, nil, nil, nil]
  #   @render = false
  #   @location = options[:coord] || [nil, nil]
  #   @tileset = options[:tileset] || Tileset.new
  # end

  # fix problem with 0.0 != 0 in Sets
  def coord
    [coordA, coordB]
  end

  def coord_eq?(x,y)
    @location[0] == x && @location[1] == y
  end

  def eql?(other_tile)
    binding.pry
    @tileset == other_tile.tileset && coord_eq?(*other_tile.coord)
  end

  # def self.at(x, y)
  #   Tile.new
  # end

  def self.origin
    Tile.where(coordA: 0, coordB: 0).first || Tile.create(coordA: 0, coordB: 0, layer: 1)
  end

  def self.at(a, b)
    Tile.where(coordA: a, coordB: b).first
  end

  def up
    Tile.at *coord_up
  end
  def right
    Tile.at *coord_right
  end
  def down
    Tile.at *coord_down
  end
  def left
    Tile.at *coord_left
  end

  def neighbors
    [up, right, down, left]
  end

  # def up=(tile)
  #   @neighbors[0] = tile
  # end
  # def right=(tile)
  #   @neighbors[1] = tile
  # end
  # def down=(tile)
  #   @neighbors[2] = tile
  # end
  # def left=(tile)
  #   @neighbors[3] = tile
  # end

  def child(index)
    children[index]
  end

  def explore_child(index)
    # return child in O(1) time if previously explored
    if @children[index] != nil
      @children[index]
    end
    child = Tile.new(parent: self, tileset: @tileset)
    x,y = @location
    offset = child.tile_width / 2.0
    child_location = case index
               when 0
                 [x - offset, y + offset]
               when 1
                 [x + offset, y + offset]
               when 2
                 [x - offset, y - offset]
               when 3
                 [x + offset, y - offset]
               else
                 raise 'something went wrong'
               end
    child.location = child_location
    @children[index] = child
  end

  def explore_children
    (0..3).each do |i|
      explore_child i
    end
    children
  end

  def which_child
    return nil if parent.nil?
    @parent.children.index(self)
  end

  def coord_up
    [coordA, coordB + tile_width]
  end
  def coord_right
    [coordA + tile_width, coordB]
  end
  def coord_down
    [coordA, coordB - tile_width]
  end
  def coord_left
    [coordA -  tile_width, coordB]
  end

  def explore_up
    self.up || Tile.create do |tile|
      tile.coordA, tile.coordB = *coord_up
      tile.layer = self.layer
      tile.parent = if self.parent.nil?
                      nil
                    else
                    #  use which_child to determine parent
                    end
    end
  end

  def explore_right
    self.right || Tile.create do |tile|
      tile.coordA, tile.coordB = *coord_right
      tile.layer = self.layer
      tile.parent = if self.parent.nil?
                      nil
                    else
                      #  use which_child to determine parent
                    end
    end
  end

  def explore_down
    self.down || Tile.create do |tile|
      tile.coordA, tile.coordB = *coord_down
      tile.layer = self.layer
      tile.parent = if self.parent.nil?
                      nil
                    else
                      #  use which_child to determine parent
                    end
    end
  end

  def explore_left
    self.left || Tile.create do |tile|
      tile.coordA, tile.coordB = *coord_left
      tile.layer = self.layer
      tile.parent = if self.parent.nil?
                      nil
                    else
                      #  use which_child to determine parent
                    end
    end
  end


  # def explore_up
  #   if up != nil
  #     # return neighbor in O(1) time if previously explored
  #     return up
  #   end
  #   if top_layer?
  #   #  spawn neighbor tile and set its location
  #     neighbor = Tile.new tileset: @tileset
  #     neighbor.down = self
  #     self.up = neighbor
  #     # horizontal component unchanged
  #     neighbor.location[0] = self.location[0]
  #     # vertical component changes by tile width
  #     distance = tile_width
  #     neighbor.location[1] = self.location[1] + distance
  #     neighbor
  #   else
  #     # search tree for
  #     self.up = case which_child
  #       when 0
  #         parent.explore_up.explore_child(2)
  #       when 1
  #         parent.explore_up.explore_child(3)
  #       when 2
  #         parent.explore_child(0)
  #       when 3
  #         parent.explore_child(1)
  #       when nil
  #         # should only return nil if current tile is on top layer
  #         # binding.pry
  #         nil
  #       else
  #         raise "Something went wrong."
  #     end
  #   end
  # end
  # def explore_right
  #   if right != nil
  #     return right
  #   end
  #   if top_layer?
  #     #  spawn neighbor tile and set its location
  #     neighbor = Tile.new tileset: @tileset
  #     neighbor.left = self
  #     self.right = neighbor
  #     # vertical component unchanged
  #     neighbor.location[1] = self.location[1]
  #     # horizontal component changes by tile width
  #     distance = tile_width
  #     neighbor.location[0] = self.location[0] + distance
  #     neighbor
  #   else
  #     # search tree for tile
  #     self.right = case which_child
  #       when 0
  #         parent.explore_child(1)
  #       when 1
  #         parent.explore_right.explore_child(0)
  #       when 2
  #         parent.explore_child(3)
  #       when 3
  #         parent.explore_right.explore_child(2)
  #       when nil
  #         nil
  #       else
  #         raise "Something went wrong."
  #     end
  #   end
  # end
  # def explore_down
  #   if down != nil
  #     return down
  #   end
  #   if top_layer?
  #     #  spawn neighbor tile and set its location
  #     neighbor = Tile.new tileset: @tileset
  #     neighbor.up = self
  #     self.down = neighbor
  #     # horizontal component unchanged
  #     neighbor.location[0] = self.location[0]
  #     # vertical component changes by tile width
  #     distance = tile_width
  #     neighbor.location[1] = self.location[1] - distance
  #     neighbor
  #   else
  #     # search tree for tile
  #     self.down = case which_child
  #       when 0
  #         parent.explore_child(2)
  #       when 1
  #         parent.explore_child(3)
  #       when 2
  #         parent.explore_down.explore_child(0)
  #       when 3
  #         parent.explore_down.explore_child(1)
  #       when nil
  #         nil
  #       else
  #         raise "Something went wrong."
  #     end
  #   end
  # end
  # def explore_left
  #   if left != nil
  #     return left
  #   end
  #   if top_layer?
  #     #  spawn neighbor tile and set its location
  #     neighbor = Tile.new tileset: @tileset
  #     neighbor.right = self
  #     self.left = neighbor
  #     # vertical component unchanged
  #     neighbor.location[1] = self.location[1]
  #     # horizontal component changes by tile width
  #     distance = tile_width
  #     neighbor.location[0] = self.location[0] - distance
  #     neighbor
  #   else
  #     # search tree for tile
  #     self.left = case which_child
  #       when 0
  #         parent.explore_left.explore_child(1)
  #       when 1
  #         parent.explore_child(0)
  #       when 2
  #         parent.explore_left.explore_child(3)
  #       when 3
  #         parent.explore_child(2)
  #       when nil
  #         # parent does not point to child (self)
  #         binding.pry
  #       else
  #         raise "Something went wrong."
  #     end
  #   end
  # end

  def explore_neighbors(radius = 1)
    visited = Set[self.coord]
    if radius >= 1
      queue = [[self, radius]]
      until queue.empty?
        current, radius_ = queue.shift
        next if radius_ == 0
        # binding.pry
        visited << current.coord
        north = current.explore_up
        # binding.pry
        # binding.pry if north.nil?

        #TODO Why is current.explore_up returning nil?????????????

        if !visited.include?(north.coord)
          queue << [north, radius_-1]
          # visited << north.coord
        end
        east = current.explore_right
        if !visited.include?(east.coord)
          queue << [east, radius_-1]
          # visited << east.coord
        end
        south = current.explore_down
        if !visited.include?(south.coord)
          queue << [south, radius_-1]
          # visited << south.coord
        end
        west = current.explore_left
        if !visited.include?(west.coord)
          queue << [west, radius_-1]
          # visited << west.coord
        end
      end
    end
    visited
  end
  alias_method :explore, :explore_neighbors

  def count_neighbors
    neighbors.reject(&:nil?).count
  end

  def connected_tiles(radius = 0)
    visited = Set[self.coord]
    if radius >= 1
      queue = [[self, radius]]

      until queue.empty?
        current, radius_ = queue.shift
        next if radius_ == 0

        visited << current.coord

        if current.up && !visited.include?(current.up.coord)
          queue << [current.up, radius_-1]
          visited << current.up.coord
        end
        if current.right && !visited.include?(current.right.coord)
          queue << [current.right, radius_-1]
          visited << current.right.coord
        end
        if current.down && !visited.include?(current.down.coord)
          queue << [current.down, radius_-1]
          visited << current.down.coord
        end
        if current.left && !visited.include?(current.left.coord)
          queue << [current.left, radius_-1]
          visited << current.left.coord
        end
      end
    end
    visited
  end


  def leaf?
    (0..3).map {|i| child(i).nil?}.reduce :&
  end

  # todo rename. this structure is not a tree
  def tree_size
    if self.leaf?
      1
    else
      children.reject(&:nil?).map(&:tree_size).reduce(:+) + 1
    end
  end

  def top_layer?
    @layer == 1
  end

  def to_s
    puts "\nTile: #{@location}\nLayer #{@layer}\nTree Size: #{tree_size}"
    puts "Neighbors:"
    puts "\tUp: #{Tile.tree_size up}"
    puts "\tRight: #{Tile.tree_size right}"
    puts "\tDown: #{Tile.tree_size down}"
    puts "\tLeft: #{Tile.tree_size left}"
    puts "Children:"
    puts "\nFirst: #{Tile.tree_size child(0)}"
    puts "\nSecond: #{Tile.tree_size child(1)}"
    puts "\nThird: #{Tile.tree_size child(2)}"
    puts "\nFourth: #{Tile.tree_size child(3)}"
  end

  # get every tile connected to this tile in the same layer
  def traverse_layer
    visited = {}
    queue = [self]

    until queue.empty?
      current = queue.shift
      visited[current.location] = true
      if current.up && !visited[current.up.location]
        queue << current.up
        visited[current.up.location] = true
      end
      if current.right && !visited[current.right.location]
        queue << current.right
        visited[current.right.location] = true
      end
      if current.down && !visited[current.down.location]
        queue << current.down
        visited[current.down.location] = true
      end
      if current.left && !visited[current.left.location]
        queue << current.left
        visited[current.left.location] = true
      end
    end
    # return an array of tile locations
    visited.map {|t| t.first}
  end


  def self.tree_size(tile)
    return 0 if tile.nil?
    tile.tree_size
  end

  def self.new_origin
    t = Tile.new
    t.location = [0,0]

    t
  end
end
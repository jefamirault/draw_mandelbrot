require 'set'
require 'pry-byebug'
require_relative 'tileset'
require "sinatra/activerecord"

class Tile < ActiveRecord::Base
  validates :coordA, uniqueness: { scope: :coordB}
  belongs_to :parent, class_name: 'Tile', foreign_key: :parent_id
  has_many :children, class_name: 'Tile', foreign_key: :parent_id
  validates_length_of :children, maximum: 4

  enum render_status: [:unqueued, :queued, :processing, :complete], _default: :unqueued

  # Span of Complex Plane a single tile covers at Layer 1/Zoom 1.0
  TILE_SIZE = 1
  # Rendered Tile Resolution
  TILE_RESOLUTION = 400

  def pixel_width
    TILE_SIZE / TILE_RESOLUTION
  end

  def tile_width
    TILE_SIZE * 0.5 ** (layer - 1)
  end
  def self.tile_width(layer)
    TILE_SIZE * 0.5 ** (layer - 1)
  end

  attr_accessor :tileset, :render, :location

  def coord
    [coordA, coordB]
  end

  def coord_eq?(x,y)
    @location[0] == x && @location[1] == y
  end


  def self.origin
    Tile.where(coordA: 0, coordB: 0).first || Tile.create(coordA: 0, coordB: 0, layer: 1)
  end

  def self.at(a, b, layer = nil)
    if a == 0 && b == 0
      Tile.origin
    else
      exact = Tile.where(coordA: a, coordB: b).first
      if exact
        exact
      elsif layer
         Tile.nearest(a,b,layer)
      else
        nil
      end
    end
  end

  # e.g. round a=5.25068 to nearest n=0.25 => 5.25
  def self.round_to(a, n, offset = 0)
    ((a + offset) / n).round * n - offset
  end

  # Calculate coordinates of nearest tile on layer whether it exists or not.
  # Explore if it does not exist and return tile
  def self.nearest(a, b, layer)
    if layer.nil?
      raise "Cannot find nearest tile based on inexact coordinates without layer"
    end
    w=Tile.tile_width(layer)
    coord = [a,b].map {|n| Tile.round_to n, w, w/2.0 }
    explored_tile = Tile.at *coord
    if explored_tile
      explored_tile
    else
      child_index_order = []
      parent = Tile.nearest(*coord, layer - 1)

      t = if parent
        index = parent.coord_children.index [*coord]
        if index.nil?
          binding.pry
          raise "How did we get here?"
        end
        parent.explore_child index
          else
            raise 'parent does not exist'
      #      keep traversing tree
      end

    #  call nearest on lower layer and explore children parent
      t
    end
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
    [up, right, down, left].reject &:nil?
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
    Tile.at *coord_child(index)
  end

  # Tile splits evenly into 4 child tiles with indices (0..3) => (top-left, top-right, bottom-left, bottom-right)
  def explore_child(index)
    current = child index
    if current
      current
    else
      a, b = coord_child index
      tile = Tile.new coordA: a, coordB: b, parent: self, layer: self.layer + 1
      if tile.save
        tile
      else
        raise 'Expected to create new tile but could not'
      end
    end
  end

  # def explore_child(index)
  #   # return child in O(1) time if previously explored
  #   if @children[index] != nil
  #     @children[index]
  #   end
  #   child = Tile.new(parent: self, tileset: @tileset)
  #   x,y = @location
  #   offset = child.tile_width / 2.0
  #   child_location = case index
  #              when 0
  #                [x - offset, y + offset]
  #              when 1
  #                [x + offset, y + offset]
  #              when 2
  #                [x - offset, y - offset]
  #              when 3
  #                [x + offset, y - offset]
  #              else
  #                raise 'something went wrong'
  #              end
  #   child.location = child_location
  #   @children[index] = child
  # end

  def explore_children
    Set[*(0..3).map {|i| explore_child i }]
  end

  # Am I child 0, 1, 2, or 3 of my parent tile?
  def which_child
    return nil if parent.nil?
    if coordA < parent.coordA
      if coordB > parent.coordB
        0
      else
        2
      end
    else
      if coordB > parent.coordB
        1
      else
        3
      end
    end
  end

  def self.which_child

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

  def coord_child(index)
    offset = tile_width / 4.0
    case index
    when 0
      [coordA - offset, coordB + offset]
    when 1
      [coordA + offset, coordB + offset]
    when 2
      [coordA - offset, coordB - offset]
    when 3
      [coordA + offset, coordB - offset]
    else
      raise 'child index must be in range [0, 4]'
    end
  end
  def self.coord_child(a, b, layer)
    tile_width = Tile.tile_width layer
    offset = tile_width / 4.0
    case index
    when 0
      [a - offset, b + offset]
    when 1
      [a + offset, b + offset]
    when 2
      [a - offset, b - offset]
    when 3
      [a + offset, b - offset]
    else
      raise 'child index must be in range [0, 4]'
    end
  end
  def coord_children
    (0..3).map {|i| coord_child i}
  end


  def explore_up
    self.up || Tile.create do |tile|
      tile.coordA, tile.coordB = *coord_up
      tile.layer = self.layer
      tile.parent = if self.parent.nil?
                      nil
                    else
                      case which_child
                      when 0..1
                        parent.explore_up
                      when 2..3
                        parent
                      else
                        raise 'Error: cannot determine child index of parent tile'
                      end
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
                      case which_child
                      when 1,3
                        parent.explore_right
                      when 0,2
                        parent
                      else
                        raise 'Error: cannot determine child index of parent tile'
                      end
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
                      case which_child
                      when 0..1
                        parent
                      when 2..3
                        parent.down
                      else
                        raise 'Error: cannot determine child index of parent tile'
                      end
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
                      case which_child
                      when 0,2
                        parent.explore_left
                      when 1,3
                        parent
                      else
                        raise 'Error: cannot determine child index of parent tile'
                      end                    end
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
        visited << current.coord
        north = current.explore_up

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

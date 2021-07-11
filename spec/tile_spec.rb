require 'pry-byebug'
require_relative '../lib/tile'


RSpec.describe Tile do
  context "Origin: Tile.at(0,0)" do
    before(:example) do
      @tileset = Tileset.new
    end
    it 'Tile.origin should return a Tile object with coord [0,0]' do
      origin = Tile.origin
      expect(origin.class).to be Tile
      expect(origin.coord).to eq [0.0,0.0]
    end
    it 'Tile.at(0,0) should return the origin.' do
      tile = Tile.at(0,0)
      origin = Tile.origin
      expect(tile).to eq origin
    end
    it 'requesting the same coord twice will return the same object.' do
      a = Tile.at(0,0)
      b = Tile.at(0,0)
      expect(a). to eq b
    end
    it 'Tile width should be 1.0' do
      expect(Tile.origin.tile_width).to eq 1

    end
  end
  context "Explore radius around (0,0) layer 1 in a given radius" do
    before(:example) do
      @origin = Tile.origin
    end
    it 'explore tile to the north' do
      north = @origin.explore_up
      expect(north.layer).to eq 1
      expect(north.parent).to be nil
      expect(north.coord).to eq [0.0, 1.0]
    end
    it 'explore tile to the east' do
      east = @origin.explore_right
      expect(east.layer).to eq 1
      expect(east.parent).to be nil
      expect(east.coord).to eq [1.0, 0.0]
    end
    it 'explore tile to the south' do
      south = @origin.explore_down
      expect(south.layer).to eq 1
      expect(south.parent).to be nil
      expect(south.coord).to eq [0.0, -1.0]
    end
    it 'explore tile to the west' do
      west = @origin.explore_left
      expect(west.layer).to eq 1
      expect(west.parent).to be nil
      expect(west.coord).to eq [-1.0, 0.0]
    end
    it 'explore tiles around origin in radius = 1' do
      @origin.explore_neighbors(1)
      expect(@origin.count_neighbors).to eq 4
    end
    it 'explore tiles around origin in radius = 2' do
      @origin.explore_neighbors(2)
      connected_2 = Set[
          [0.0,0.0],
          [0.0,1.0], [1.0,0.0], [0.0,-1.0], [-1.0,0.0],
          [0.0,2.0], [1.0,1.0], [2.0,0.0], [1.0,-1.0], [0.0,-2.0], [-1.0,-1.0], [-2.0,0.0], [-1.0,1.0]
      ]
      expect(@origin.connected_tiles 2).to eq connected_2
    end

    it 'explore tiles around origin in radius = 3' do
      expect(@origin.class).to equal Tile
      @origin.explore_neighbors(3)
      connected_3 = Set[
          [0.0,0.0],
          [0.0,1.0], [1.0,0.0], [0.0,-1.0], [-1.0,0.0],
          [0.0,2.0], [1.0,1.0], [2.0,0.0], [1.0,-1.0], [0.0,-2.0], [-1.0,-1.0], [-2.0,0.0], [-1.0,1.0],
          [0.0,3.0], [1.0,2.0], [2.0,1.0], [3.0,0.0], [2.0,-1.0], [1.0,-2.0], [0.0,-3.0], [-1.0,-2.0], [-2.0,-1.0], [-3.0,0.0], [-2.0,1.0], [-1.0,2.0]
      ]
      expect(@origin.connected_tiles 3).to eq connected_3
    end
  end

  context "Explore second layer using Child 0 of Origin as center" do
    before(:example) do
      Tile.destroy_all
      @origin = Tile.origin
      @center
    end
    it 'Explore children of origin' do
      children = @origin.explore_children.map &:coord
      children_coord = Set[*children]
      expected = Set[
          [0.25,0.25],
          [0.25,-0.25],
          [-0.25,0.25],
          [-0.25,-0.25]
      ]
      expect(children_coord).to eq expected
    end
    it 'Explore radius around center: (-0.25,0.25), layer 2' do
      center = @origin.explore_child 0
      center.explore_neighbors 1

      expected = []
      center.explore_neighbors 2
      expected2 = []
      center.explore_neighbors 3
      expected3 = Set[
          [-0.25, 0.25], [-0.25, 0.75], [0.25, 0.25], [-0.25, -0.25], [-0.75, 0.25], [-0.25, 1.25], [0.25, 0.75], [-0.75, 0.75], [0.75, 0.25], [0.25, -0.25], [-0.25, -0.75], [-0.75, -0.25], [-1.25, 0.25], [-0.25, 1.75], [0.25, 1.25], [-0.75, 1.25], [0.75, 0.75], [-1.25, 0.75], [1.25, 0.25], [0.75, -0.25], [0.25, -0.75], [-0.25, -1.25], [-0.75, -0.75], [-1.25, -0.25], [-1.75, 0.25]
      ]
      expect(center.connected_tiles 3).to eq expected3
      center.explore_neighbors 4
    #  check neighbor coords and parent coords
    end
  end
end

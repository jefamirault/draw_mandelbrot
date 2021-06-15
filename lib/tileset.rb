require_relative 'tile'

class Tileset

  attr_accessor :tiles, :root

  def initialize(options = {})
    @root = Tile.new(coordA: 0, coordB: 0 )
    @tiles = [@root]
  end

  def include?(tile)
    @tiles.include? tile
  end
  def include_coord?(coord)
    @tiles.each do |tile|
      if coord == tile.coord
        return true
      end
    end
    false
  end

  def origin
    @root
  end

  def at(x,y)
    if x == 0 && y == 0
      origin
    else
      @tiles.find {|t| t.coord_eq?(x,y) }
    end
  end

  def count
    @tiles.size
  end

  # add tile if not already present
  def add(tile)
    @tiles.add tile unless include? tile
  end

  def add_by_coord(coord)
  #  check if tile with coord exists -> return existing tile
  #  else -> create and return new tile
    @tiles.each do |tile|
      if tile.coord == coord
        return tile
      end
    end
    tile = Tile.new coord
    tiles << tile
    tile
  end

  def size
    @tiles.size
  end
end
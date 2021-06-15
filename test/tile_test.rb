require_relative 'lib/test'

class TileTest < Test
  def run
    stats_to_zero!
    log "Begin Test"
    t0 = Time.now
    log "Step 1: Initialize tiles on first layer within radius of origin."
    log "Creating origin tile..."
    origin = Tile.new_origin

    assert"Origin location should be [0,0]", [0,0] do
      origin.location
    end

    assert "Tile width should be 1.0", 1.0 do
      origin.tile_width
    end

    assert"Count neighbors, there should be none", 0 do
      origin.count_neighbors
    end

    connected_0 = Set[[0.0,0.0]]
    assert "Connected tiles should include origin and no other tiles: [0,0]", connected_0 do
      origin.connected_tiles 1
    end

    log 'Exploring neighbors within radius = 1...'
    origin.explore_neighbors

    {   up: [0,1],
        right: [1,0],
        down: [0,-1],
        left: [-1,0]
    }.each do |key, value|
      assert "Neighbor #{key.to_s.upcase} should be at #{value}", value do
        neighbor = origin.send key
        neighbor.location
      end
    end

    assert "Count neighbors, there should be 4", 4 do
      origin.count_neighbors
    end

    connected_1 = Set[
        [0.0,0.0],
        [0.0,1.0], [1.0,0.0], [0.0,-1.0], [-1.0,0.0]
    ]
    assert "Connected tiles should include neighbors within 1 tile", connected_1 do
      origin.connected_tiles(1)
    end

    log "Exploring neighbors in radius = 2..."
    origin.explore_neighbors(2)

    connected_2 = Set[
        [0.0,0.0],
        [0.0,1.0], [1.0,0.0], [0.0,-1.0], [-1.0,0.0],
        [0.0,2.0], [1.0,1.0], [2.0,0.0], [1.0,-1.0], [0.0,-2.0], [-1.0,-1.0], [-2.0,0.0], [-1.0,1.0]
    ]
    assert "Connected tiles should include neighbors within 2 tiles", connected_2 do
      origin.connected_tiles 2
    end


    connected_3 = Set[
        [0.0,0.0],
        [0.0,1.0], [1.0,0.0], [0.0,-1.0], [-1.0,0.0],
        [0.0,2.0], [1.0,1.0], [2.0,0.0], [1.0,-1.0], [0.0,-2.0], [-1.0,-1.0], [-2.0,0.0], [-1.0,1.0],
        [0.0,3.0], [1.0,2.0], [2.0,1.0], [3.0,0.0], [2.0,-1.0], [1.0,-2.0], [0.0,-3.0], [-1.0,-2.0], [-2.0,-1.0], [-3.0,0.0], [-2.0,1.0], [-1.0,2.0]
    ]
    assert "Connected tiles should include neighbors within 3 tiles", connected_3 do
      origin.explore_neighbors(3)
      origin.connected_tiles 3
    end

    origin.explore_child 0
    foo = origin.child 0
    assert "Second layer tile width should be 0.5", 0.5 do
      foo.tile_width
    end
    assert "Child 0 of origin should be [-0.25, 0.25]", [-0.25,0.25] do
      foo.coord
    end
    assert "Neighbor UP should be [-0.25, 0.75]", [-0.25, 0.75] do
      foo.explore_up
      foo.up.coord
    end

    assert "Should explore neighbors in layer 2", nil do
      foo.explore_neighbors 3
    end
    # foo.explore_neighbo
    puts foo
    puts foo.connected_tiles 3






    t1 = Time.now
    bench = t1 - t0
    log "Test Complete (#{bench} seconds)"
    log "Passed #{@passed}/#{@assertions} assertions."
    message = "Failed #{@failed}/#{@assertions} assertions."
    if @failed == 0
      log message
    else
      error message
    end
    message = "Pending #{@pending}/#{@assertions} assertions."
    if @pending == 0
      log message
    else
      info message
    end
    origin
  end



end
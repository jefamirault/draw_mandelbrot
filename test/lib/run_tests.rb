require_relative 'test'
require_relative '../tile_test'
require_relative '../tileset_test'

tests = [
    TilesetTest.new,
    TileTest.new
]

tests.each do |t|
  t.run
end

require_relative 'tile'
require_relative '../../mandelbrot/lib/mandelbrot_factory'
require 'pry-byebug'
require 'fileutils'


RESOLUTION = 200

Tile.where(render_path: nil).map do |tile|
  directory = 'public/map'
  label = tile.coord.to_s.delete(' ').delete('[').delete(']').gsub(',','_').gsub('.','d')
  options = {
      resolution: [200, 200],
      directory: directory,
      center: tile.coord,
      max_iterations: 1000,
      step: tile.tile_width / RESOLUTION,
  }
  mapfile_path = './public/map/mapfile'
  File.delete(mapfile_path) if File.exists?(mapfile_path)
  m = MandelbrotFactory.new(options)
  m.run prefix: '', label: label
  tile.update render_path: "map/#{label}.png"
end

binding.pry

puts 'Test Complete.'

require_relative 'tile'
require_relative '../../mandelbrot/lib/mandelbrot_factory'
require 'pry-byebug'
require 'fileutils'


RESOLUTION = 400

while Tile.where(render_status: :queued).any?
  remaining = Tile.where(render_status: :queued)
  puts "Tiles currently in queue: #{remaining.size}"
  tile = remaining.first
  tile.update render_status: :processing
  label = tile.coord.to_s.delete(' ').delete('[').delete(']').gsub(',','_').gsub('.','d')
  directory = 'public/map'
  mapfile_path = "./public/data/#{label}"
  options = {
      resolution: [RESOLUTION, RESOLUTION],
      directory: directory,
      mapfile: mapfile_path,
      center: tile.coord,
      max_iterations: 1000,
      step: tile.tile_width / RESOLUTION,
  }
  File.delete(mapfile_path) if File.exists?(mapfile_path)
  m = MandelbrotFactory.new(options)
  m.run prefix: '', label: label
  tile.update render_path: "map/#{label}.png", render_status: :complete
end

puts 'Rendering Complete.'

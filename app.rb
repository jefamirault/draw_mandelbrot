require 'sinatra'
require 'active_record'
require 'sinatra/reloader' if development?
require 'erb'
require 'pry-byebug'
require_relative 'lib/tile'

ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'db/development.sqlite3'
)

get '/' do
  focus = params[:focus] || [0,0]
  layer = params[:layer] || 1


  center = Tile.at *focus
  center.explore_neighbors 3
  tiles = center.connected_tiles(3).map do |coord|
    Tile.at *coord
  end


  erb :index, locals: { tiles: tiles }
end

get '*' do
  'This infinite set does not contain what you are looking for...'
end

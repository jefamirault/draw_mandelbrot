require 'sinatra'
require "sinatra/json"
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
  focus = params[:focus] ? JSON.parse(params[:focus]) : [0,0]
  layer = params[:layer] || 1

  center = Tile.at *focus

  radius = 4

  center.explore_neighbors radius
  tiles = center.connected_tiles(radius).map do |coord|
    Tile.at *coord
  end


  erb :index, locals: { tiles: tiles }
end

get '/tiles' do
  focus = params[:focus] ? JSON.parse(params[:focus]) : [0,0]
  layer = params[:layer] || 1

  center = Tile.at *focus

  radius = 4

  center.explore_neighbors radius
  tiles = center.connected_tiles(radius).map do |coord|
    Tile.at *coord
  end

  erb :tiles, locals: { tiles: tiles }
end

get '*' do
  status 404
  'This infinite set does not contain what you are looking for...'
end

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

  # params = { focus: [0,0], layer: 1, radius: 3 }

  # tiles = tileset.field_of_view

  # tile includes coord, layer, render_path if available

  focus = params[:focus] || [0,0]
  layer = params[:layer] || 1



  center = Tile.at *focus
  tiles = center.explore_neighbors 3


  # tiles = [
  #     {
  #         coord: [0,0],
  #         layer: 1,
  #         render_path: '1234'
  #     },
  #     {
  #         coord: [0,1],
  #         layer: 1,
  #         render_path: '1235'
  #     }
  # ]

  erb :index, locals: { tiles: params }
end

get '*' do
  'This infinite set does not contain what you are looking for...'
end

require "active_record"
require_relative '../lib/tile'
require 'pry-byebug'


ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.sqlite3')

t = Tile.origin



binding.pry

puts 'Exiting...'
require "active_record"
require_relative '../lib/tile'
require 'pry-byebug'


ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/test.db')

binding.pry

puts 'Exiting...'
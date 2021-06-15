require 'active_record'

require 'sqlite3'

database = 'db/development.sqlite3'
# database = 'db/test.sqlite3'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: database)
puts "Using database: #{database}"

# Run with: rake shell
task :shell do
  require './my_models.rb'
  require 'irb'
  require 'irb/completion'

  ARGV.clear
  IRB.start
end

# Assuming you have a migration named `CreateUserTable` like
# the example from the migrations section above
namespace :migrate do
  task :up do
    require_relative 'db/migrate/20210704141603_create_tiles'
    CreateTiles.migrate(:up)
  end

  task :down do
    require_relative 'db/migrate/20210704141603_create_tiles'
    CreateTiles.migrate(:down)
  end
end

# Or try to apply a directory of migrations with migrator
# migrator = ActiveRecord::Migrator.open(Dir["db/migrate"])
# puts "Unapplied migrations: #{migrator.pending_migrations}"
# migrator.migrate
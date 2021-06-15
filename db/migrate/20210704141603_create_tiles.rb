class CreateTiles < ActiveRecord::Migration[6.1]
  def change
    create_table :tiles do |t|
      t.float :coordA
      t.float :coordB
      t.integer :layer
      t.integer :parent_id
      t.string :render_path
      t.index [:coordA, :coordB], unique: true
    end
  end
end

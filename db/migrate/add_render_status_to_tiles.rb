class AddRenderStatusToTiles < ActiveRecord::Migration[6.1]
  def change
    add_column :tiles, :render_status, :enum
  end
end

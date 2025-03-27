class RenamePriceToPricePerNightInRooms < ActiveRecord::Migration[6.1]
  def change
    rename_column :rooms, :price, :price_per_night
  end
end

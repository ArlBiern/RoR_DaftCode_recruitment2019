class CreateDiscounts < ActiveRecord::Migration[5.2]
  def change
    create_table :discounts do |t|
      t.string :name, null: false, unique: true
      t.string :kind, null: false
      t.float :price, null: false, default: 0
      t.integer :count, null: false, default: 0
      t.integer :product_ids, array: true, null: false, default: []

      t.references :cart, foreign_key: true, index: true
      t.timestamps
    end
  end
end

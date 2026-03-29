class AddColumnToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :city, :string
    add_column :users, :country, :string
    add_column :users, :diploma, :string
    add_column :users, :employment_status, :string
  end
end

class AddNullConstraintsToCareersJsonbColumns < ActiveRecord::Migration[8.0]
  def up
    change_column_null :careers, :disc_types,           false, []
    change_column_null :careers, :required_competences, false, []
    change_column_null :careers, :affirmations,         false, []
  end

  def down
    change_column_null :careers, :disc_types,           true
    change_column_null :careers, :required_competences, true
    change_column_null :careers, :affirmations,         true
  end
end

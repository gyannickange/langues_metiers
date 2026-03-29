class FixQuestionPositionsStartAtOne < ActiveRecord::Migration[8.0]
  def up
    change_column_default :questions, :position, from: 0, to: 1
    Question.where(position: 0).update_all(position: 1)
  end

  def down
    change_column_default :questions, :position, from: 1, to: 0
  end
end

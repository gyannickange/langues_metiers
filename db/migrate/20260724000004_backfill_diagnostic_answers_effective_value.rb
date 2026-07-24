class BackfillDiagnosticAnswersEffectiveValue < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    DiagnosticAnswer.where(effective_value: nil).where.not(diagnostic_question_id: nil).find_each do |answer|
      answer.update_column(:effective_value, answer.points_awarded)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

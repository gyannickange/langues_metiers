class LinkExistingDataToQuestionnaire < ActiveRecord::Migration[8.0]
  def up
    questionnaire = Questionnaire.create!(
      title: "Diagnostic de Repositionnement",
      description: "Questionnaire stratégique par défaut",
      active: true
    )

    Question.update_all(questionnaire_id: questionnaire.id)
    Diagnostic.update_all(questionnaire_id: questionnaire.id)
  end

  def down
    Question.update_all(questionnaire_id: nil)
    Diagnostic.update_all(questionnaire_id: nil)
    Questionnaire.destroy_all
  end
end

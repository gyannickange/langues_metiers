class LinkExistingDataToAssessment < ActiveRecord::Migration[8.0]
  def up
    assessment = Assessment.create!(
      title: "Diagnostic de Repositionnement",
      description: "Évaluation stratégique par défaut",
      active: true
    )

    AssessmentQuestion.update_all(assessment_id: assessment.id)
    Diagnostic.update_all(assessment_id: assessment.id)
  end

  def down
    AssessmentQuestion.update_all(assessment_id: nil)
    Diagnostic.update_all(assessment_id: nil)
    Assessment.destroy_all
  end
end

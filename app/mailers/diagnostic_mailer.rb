class DiagnosticMailer < ApplicationMailer
  def incomplete_reminder(diagnostic_id, delay_type)
    @diagnostic = Diagnostic.find(diagnostic_id)
    @user = @diagnostic.user
    @delay_type = delay_type

    subjects = {
      "30m" => "Vous avez commencé un diagnostic... terminez-le !",
      "1h"  => "Votre diagnostic vous attend ! Découvrez votre profil.",
      "1d"  => "Dernier rappel : Ne passez pas à côté de votre diagnostic d'orientation."
    }

    mail(to: @user.email, subject: subjects[delay_type] || "N'oubliez pas votre diagnostic !")
  end
end

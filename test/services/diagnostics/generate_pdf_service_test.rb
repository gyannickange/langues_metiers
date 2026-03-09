# test/services/diagnostics/generate_pdf_service_test.rb
require "test_helper"

class Diagnostics::GeneratePdfServiceTest < ActiveSupport::TestCase
  def setup
    @user    = User.create!(email: "pdf#{SecureRandom.hex(4)}@test.com", password: "password123", first_name: "Test", last_name: "User", city: "Test City", country: "CI", diploma: "Master", employment_status: "En emploi")
    @profile = Career.create!(
      title: "Analyste & Veille", slug: "analyste-#{SecureRandom.hex(3)}",
      status: :published, kind: :behavioral,
      description: "Expert en analyse stratégique.",
      key_skills: [ "Analyse", "Rédaction" ],
      first_action: "Réalisez une analyse sectorielle.",
      premium_pitch: "Découvrez le Roadmap Premium."
    )
    @profile.trajectories.create!(
      axe_1: "ONG / Institution", axe_2: "Secteur privé", axe_3: "Expert long terme",
      active: true
    )
    @complementary = Career.create!(title: "Coordinateur", slug: "coordo-#{SecureRandom.hex(3)}", status: :published, kind: :behavioral)
    @diagnostic = Diagnostic.create!(
      user: @user, status: :completed,
      primary_career: @profile, complementary_career: @complementary,
      score_data: { @profile.slug => 8, @complementary.slug => 5 }
    )
  end

  test "attaches PDF to diagnostic" do
    Diagnostics::GeneratePdfService.call(@diagnostic)
    @diagnostic.reload
    assert @diagnostic.pdf_report.attached?
    assert @diagnostic.pdf_generated?
  end

  test "generated file is a valid PDF" do
    Diagnostics::GeneratePdfService.call(@diagnostic)
    data = @diagnostic.pdf_report.download
    assert data.start_with?("%PDF")
    assert data.length > 500
  end
end

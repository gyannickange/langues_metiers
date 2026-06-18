require "test_helper"

class CareersControllerTest < ActionDispatch::IntegrationTest
  setup do
    Career.delete_all
    @career_a = Career.create!(
      title: "Analyste des usages",
      description: "Transforme des observations qualitatives en recommandations concrètes.",
      sector: "Études et conseil",
      status: :published,
      kind: :profession
    )
    @career_b = Career.create!(
      title: "Chargé de communication",
      description: "Conçoit des messages clairs pour différents publics.",
      sector: "Communication",
      status: :published,
      kind: :profession
    )
  end

  test "GET index renders a home-style careers landing page" do
    get careers_path

    assert_response :success
    assert_select "header[data-controller='mobile-menu']", count: 1
    assert_select "button[data-mobile-menu-target='button'][aria-controls='mobile-menu'][aria-expanded='false']", count: 1
    assert_select "h1", text: /Explorez les métiers qui valorisent votre profil/
    assert_select "img[alt='Professionnels explorant leurs perspectives de carrière']", count: 1
    assert_select "a.lp-action-primary[href*='/users/sign_in'][href*='redirect_to']", text: /diagnostic/, minimum: 2
    assert_select "section#careers [data-home-motion-target='group'].is-visible", count: 1
    assert_select "section#careers .grid [data-motion-item]", count: 2
    assert_select "section#careers article[data-career-card]", count: 2
    assert_select "section#careers .rounded-2xl.border.border-gray-200.bg-white", count: 2
    assert_select "section#careers h2", text: @career_a.title
    assert_select "section#careers h2", text: @career_b.title
    assert_select ".backdrop-blur-xl", count: 0
    assert_select ".bg-gradient-to-br", count: 0
    assert_select ".rounded-\\[3rem\\]", count: 0
  end
end

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    Career.create!(
      title: "Traducteur",
      status: :published,
      sector: "Langues",
      kind: "profession",
      academic_field_slug: "langues"
    )
  end

  test "GET index renders the updated home page copy" do
    get root_path

    assert_response :success
    assert_includes response.body, "Trouve ta"
    assert_select "h2", text: "Pourquoi tant de diplômés peinent-ils à s'en sortir professionnellement ?"
    assert_select "p", text: /De récentes études menées par l'Organisation Internationale du Travail/
    assert_select "p", text: "Tu réponds à l'évaluation structurée en quelques minutes."
    assert_not_includes response.body, "Beaucoup de profils académiques possèdent ces bases"
    assert_not_includes response.body, "Diagnostic de Repositionnement Stratégique"
    assert_not_includes response.body, "Score de positionnement visible"
    assert_includes response.body, "Voir les 1 métiers"
  end

  test "GET index renders mobile-friendly navigation and layouts" do
    get root_path

    assert_response :success
    assert_select "button[data-mobile-menu-target='button'][aria-controls='mobile-menu'][aria-expanded='false']"
    assert_select "#mobile-menu[data-mobile-menu-target='menu']"
    assert_select "a.w-full.sm\\:w-auto", minimum: 2
    assert_select ".h-\\[360px\\].sm\\:h-\\[500px\\].lg\\:h-\\[868px\\]", count: 1
    assert_select ".py-16.md\\:py-24", minimum: 8
    assert_select ".flex-col.sm\\:flex-row", minimum: 2
  end

  test "GET index uses restrained home page styling" do
    get root_path

    assert_response :success
    assert_select ".lp-action-primary", minimum: 4
    assert_select ".lp-action-secondary", minimum: 1
    assert_select ".shadow-2xl", count: 0
    assert_select ".backdrop-blur-md", count: 0
    assert_select ".blur-3xl", count: 0
    assert_select ".animate-pulse", count: 0
    assert_select ".bg-gradient-to-br", count: 0
  end

  test "GET index renders polished navigation and content details" do
    get root_path

    assert_response :success
    assert_select "a[href='#']", count: 0
    assert_select "a[href='#public']", minimum: 2
    assert_select "a[href='#contact']", minimum: 2
    assert_select "section#public"
    assert_select "footer#contact"
    assert_select "img[alt]:not([alt=''])", minimum: 3
    assert_select "footer", text: /#{Date.current.year} Insertrice/
    assert_select "footer input[type='email']", count: 0
    assert_select "footer button", text: "S'abonner", count: 0
    assert_not_includes response.body, "75001 Paris"
  end

  test "GET index wires purposeful accessible motion" do
    get root_path

    assert_response :success
    assert_select "[data-controller~='home-motion']", minimum: 1
    assert_select "[data-home-motion-target='hero']", minimum: 2
    assert_select "[data-home-motion-target='group']", minimum: 3
    assert_select "[data-motion-item]", minimum: 12
    assert_select ".animate-pulse", count: 0
    assert_select ".animate-bounce", count: 0
  end

  test "GET index renders shared career cards with section-level headings" do
    get root_path

    assert_response :success
    assert_select "section#careers article[data-career-card]", minimum: 1
    assert_select "section#careers article[data-career-card] h3", minimum: 1
    assert_select "section#careers article[data-career-card] h2", count: 0
  end

  test "GET index renders logout buttons for signed in users" do
    user = User.create!(
      email: "signed-in@example.com",
      password: "password123",
      first_name: "Ada",
      last_name: "Lovelace",
      city: "Cotonou",
      country: "Bénin",
      diploma: "Licence",
      employment_status: "employed"
    )
    sign_in user

    get root_path

    assert_response :success
    assert_select "form[action='#{destroy_user_session_path}'][method='post']", minimum: 2 do
      assert_select "input[name='_method'][value='delete']", minimum: 1
      assert_select "button.lp-action-secondary", text: "Déconnexion"
    end
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end
end

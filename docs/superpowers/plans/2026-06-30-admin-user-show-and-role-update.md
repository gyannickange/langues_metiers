# Admin User Show Page & Role Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-overview show page for admin users with an inline role-update form.

**Architecture:** Expand `Admin::UsersController` with `show` and `update` actions. The show page uses existing `shared/show_card`, `shared/badge`, and `shared/version_history` partials across six sections. Role is updated via a standalone Turbo-compatible form on the show page — no separate edit page. PaperTrail already tracks `:role` on `User`.

**Tech Stack:** Rails 8, Turbo, Devise, PaperTrail, Minitest, existing admin partials.

**Spec:** `docs/superpowers/specs/2026-06-30-admin-user-show-and-role-update-design.md`

---

### Task 1: Routes + controller actions + controller test

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/admin/users_controller.rb`
- Create: `test/controllers/admin/users_controller_test.rb`

- [ ] **Step 1: Write the controller tests**

Create `test/controllers/admin/users_controller_test.rb`:

```ruby
require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "admin#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      role: :admin
    )
    @user = User.create!(
      email: "user#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      role: :user
    )
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "index renders successfully" do
    get admin_users_path
    assert_response :success
  end

  test "show renders the user page" do
    get admin_user_path(@user)
    assert_response :success
    assert_select "h1", text: @user.email
  end

  test "update changes the user role" do
    patch admin_user_path(@user), params: { user: { role: "admin" } }
    assert_redirected_to admin_user_path(@user)
    assert_equal "admin", @user.reload.role
  end

  test "update ignores unpermitted params" do
    original_email = @user.email
    patch admin_user_path(@user), params: { user: { role: "admin", email: "hacked@evil.com" } }
    assert_equal original_email, @user.reload.email
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bin/rails test test/controllers/admin/users_controller_test.rb`
Expected: 4 failures — routes don't exist yet.

- [ ] **Step 3: Expand the routes**

In `config/routes.rb`, change:

```ruby
resources :users, only: [ :index ]
```

to:

```ruby
resources :users, only: [ :index, :show, :update ]
```

- [ ] **Step 4: Expand the controller**

Replace `app/controllers/admin/users_controller.rb` with:

```ruby
module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show update]

    def index
      @pagy, @users = pagy(User.order(created_at: :desc))
    end

    def show
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Rôle mis à jour."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_user
      @user = User.includes(:skills, :diagnostics, :payments).find(params[:id])
    end

    def user_params
      params.require(:user).permit(:role)
    end
  end
end
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bin/rails test test/controllers/admin/users_controller_test.rb`
Expected: 3 pass, 1 failure on "show renders the user page" (view doesn't exist yet — that's fine, move on).

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/admin/users_controller.rb test/controllers/admin/users_controller_test.rb
git commit -m "feat: add show and update actions to Admin::UsersController"
```

---

### Task 2: Show page view

**Files:**
- Create: `app/views/admin/users/show.html.erb`

- [ ] **Step 1: Create the show view**

Create `app/views/admin/users/show.html.erb`:

```erb
<% content_for :page_title, "Utilisateur" %>

<%= render "shared/page_header",
    title: [@user.first_name, @user.last_name].select(&:present?).join(" ").presence || @user.email,
    subtitle: @user.email,
    action_text: nil,
    action_url: nil %>

<div class="space-y-6 max-w-4xl">

  <%# Role — inline edit form %>
  <div class="glass-card rounded-2xl p-6 shadow-premium animate-premium-in">
    <div class="flex items-center gap-3 mb-6 border-b border-slate-100 pb-4">
      <div class="p-2 bg-[var(--color-primary)]/10 text-[var(--color-primary)] rounded-lg">
        <%= lucide_icon "shield", class: "h-5 w-5" %>
      </div>
      <h3 class="text-lg font-display text-slate-800">Rôle</h3>
    </div>

    <%= form_with model: [:admin, @user], method: :patch, class: "flex items-end gap-4" do |f| %>
      <div class="flex-1">
        <%= render partial: "shared/form_field", locals: {
          form: f,
          field: :role,
          label: "Rôle",
          type: "select",
          options: User.roles.keys.map { |k| [k.humanize, k] }
        } %>
      </div>
      <%= f.submit "Enregistrer", class: "mb-1 px-5 py-2 bg-[var(--color-primary)] text-white rounded-xl text-xs font-bold hover:opacity-90 transition-all cursor-pointer" %>
    <% end %>
  </div>

  <%# Profile — read-only %>
  <%= render "shared/show_card",
      title: "Profil",
      icon: :user,
      items: [
        { label: "Prénom",              value: @user.first_name.presence || "—" },
        { label: "Nom",                 value: @user.last_name.presence  || "—" },
        { label: "Ville",               value: @user.city.presence       || "—" },
        { label: "Pays",                value: @user.country.presence    || "—" },
        { label: "Diplôme",             value: @user.diploma.presence    || "—" },
        { label: "Situation",           value: @user.employment_status.presence || "—" },
        { label: "Inscrit le",          value: l(@user.created_at, format: :short) },
        { label: "Onboarding",          value: render("shared/badge",
            label: @user.onboarded? ? "Complet" : "Incomplet",
            color: @user.onboarded? ? :green : :gray) }
      ] %>

  <%# Skills %>
  <div class="glass-card rounded-2xl p-6 shadow-premium animate-premium-in">
    <div class="flex items-center gap-3 mb-6 border-b border-slate-100 pb-4">
      <div class="p-2 bg-[var(--color-primary)]/10 text-[var(--color-primary)] rounded-lg">
        <%= lucide_icon "award", class: "h-5 w-5" %>
      </div>
      <h3 class="text-lg font-display text-slate-800">Compétences</h3>
    </div>
    <% if @user.skills.any? %>
      <div class="flex flex-wrap gap-2">
        <% @user.skills.each do |skill| %>
          <%= render "shared/badge", label: skill.name, color: :blue %>
        <% end %>
      </div>
    <% else %>
      <p class="text-sm text-slate-400">Aucune compétence enregistrée.</p>
    <% end %>
  </div>

  <%# Diagnostics %>
  <div class="glass-card rounded-2xl p-6 shadow-premium animate-premium-in">
    <div class="flex items-center gap-3 mb-6 border-b border-slate-100 pb-4">
      <div class="p-2 bg-[var(--color-primary)]/10 text-[var(--color-primary)] rounded-lg">
        <%= lucide_icon "activity", class: "h-5 w-5" %>
      </div>
      <h3 class="text-lg font-display text-slate-800">Diagnostics</h3>
    </div>
    <% if @user.diagnostics.any? %>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-[10px] font-black uppercase text-slate-400 border-b border-slate-100">
            <th class="pb-2">Date</th>
            <th class="pb-2">Statut</th>
            <th class="pb-2">Complété le</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-50">
          <% @user.diagnostics.order(created_at: :desc).each do |diagnostic| %>
            <tr class="text-slate-700">
              <td class="py-3"><%= l(diagnostic.created_at, format: :short) %></td>
              <td class="py-3"><%= diagnostic.status.humanize %></td>
              <td class="py-3"><%= diagnostic.completed_at ? l(diagnostic.completed_at, format: :short) : "—" %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    <% else %>
      <p class="text-sm text-slate-400">Aucun diagnostic.</p>
    <% end %>
  </div>

  <%# Payments %>
  <div class="glass-card rounded-2xl p-6 shadow-premium animate-premium-in">
    <div class="flex items-center gap-3 mb-6 border-b border-slate-100 pb-4">
      <div class="p-2 bg-[var(--color-primary)]/10 text-[var(--color-primary)] rounded-lg">
        <%= lucide_icon "credit-card", class: "h-5 w-5" %>
      </div>
      <h3 class="text-lg font-display text-slate-800">Paiements</h3>
    </div>
    <% if @user.payments.any? %>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left text-[10px] font-black uppercase text-slate-400 border-b border-slate-100">
            <th class="pb-2">Date</th>
            <th class="pb-2">Montant</th>
            <th class="pb-2">Statut</th>
            <th class="pb-2">Fournisseur</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-50">
          <% @user.payments.order(created_at: :desc).each do |payment| %>
            <tr class="text-slate-700">
              <td class="py-3"><%= l(payment.created_at, format: :short) %></td>
              <td class="py-3"><%= payment.amount_cents / 100 %> <%= payment.currency %></td>
              <td class="py-3"><%= payment.status.humanize %></td>
              <td class="py-3"><%= payment.provider.humanize %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    <% else %>
      <p class="text-sm text-slate-400">Aucun paiement.</p>
    <% end %>
  </div>

  <%# Role change history %>
  <%= render "shared/version_history", versions: @user.versions.reverse_chronological %>

  <div>
    <%= link_to admin_users_path, class: "inline-flex items-center px-4 py-2 bg-slate-100 text-slate-700 rounded-xl text-xs font-bold hover:bg-slate-200 transition-colors" do %>
      <%= lucide_icon "arrow-left", class: "w-4 h-4 mr-2" %>
      Retour à la liste
    <% end %>
  </div>

</div>
```

- [ ] **Step 2: Run the controller tests**

Run: `bin/rails test test/controllers/admin/users_controller_test.rb`
Expected: all 4 pass.

- [ ] **Step 3: Commit**

```bash
git add app/views/admin/users/show.html.erb
git commit -m "feat: add admin user show page with role form, profile, skills, diagnostics, payments"
```

---

### Task 3: Link index table rows to the show page

**Files:**
- Modify: `app/views/admin/users/index.html.erb`

- [ ] **Step 1: Add a link on the email cell**

In `app/views/admin/users/index.html.erb`, replace:

```erb
<%= render "shared/table",
  columns: [
    { header: "Email",  cell: ->(r){ r.email } },
    { header: "Rôle",   cell: ->(r){ render "shared/badge", label: r.role, color: (r.role == "admin" ? :gold : :gray) } },
    { header: "Créé le", cell: ->(r){ l(r.created_at, format: :short) } }
  ],
  rows: @users,
  pagy: @pagy %>
```

with:

```erb
<%= render "shared/table",
  columns: [
    { header: "Email",   cell: ->(r){ link_to r.email, admin_user_path(r), class: "underline hover:text-[var(--color-primary)] transition-colors" } },
    { header: "Nom",     cell: ->(r){ [r.first_name, r.last_name].select(&:present?).join(" ").presence || "—" } },
    { header: "Rôle",    cell: ->(r){ render "shared/badge", label: r.role, color: (r.role == "admin" ? :gold : :gray) } },
    { header: "Créé le", cell: ->(r){ l(r.created_at, format: :short) } }
  ],
  rows: @users,
  pagy: @pagy %>
```

- [ ] **Step 2: Run the full test suite**

Run: `bin/rails test`
Expected: 0 failures, 0 errors.

- [ ] **Step 3: Commit**

```bash
git add app/views/admin/users/index.html.erb
git commit -m "feat: link user index rows to show page, add name column"
```

# Admin User Show Page & Role Update — Design Spec

**Date:** 2026-06-30
**Status:** Approved

---

## Goal

Give admins a full-overview show page for any user, with the ability to update that user's role inline without leaving the page.

---

## Routes

Expand the existing `resources :users` from `only: [:index]` to `only: [:index, :show, :update]`.

```ruby
resources :users, only: [:index, :show, :update]
```

No new route helpers needed beyond `admin_user_path` and `admin_users_path`.

---

## Controller

**`show`** — loads the user with associations eager-loaded:

```ruby
@user = User.includes(:skills, :diagnostics, :payments).find(params[:id])
```

**`update`** — permits `:role` only, redirects to show on success, re-renders show on failure:

```ruby
def update
  @user = User.find(params[:id])
  if @user.update(user_params)
    redirect_to admin_user_path(@user), notice: "Rôle mis à jour."
  else
    render :show, status: :unprocessable_content
  end
end

private

def user_params
  params.require(:user).permit(:role)
end
```

PaperTrail already tracks `:role` changes on `User`, so the audit trail is automatic.

---

## Index Table

Add a link on each row so admins can navigate to the show page. The email cell becomes a link:

```ruby
{ header: "Email", cell: ->(r){ link_to r.email, admin_user_path(r), class: "underline" } }
```

---

## Show Page Layout

Single-column, `max-w-4xl`, matching the existing `glass-card` style used across the admin.

### 1. Page Header

Uses the existing `shared/page_header` partial:
- **Title:** Full name (`"#{first_name} #{last_name}".strip`, fallback to email if blank)
- **Subtitle:** Email address
- No action button (role is updated inline below)

### 2. Role Section (inline edit)

A standalone `form_with` targeting `admin_user_path(@user)` with `method: :patch`. Contains:
- A `shared/form_field` select for `:role` with options `[["Utilisateur", "user"], ["Admin", "admin"]]`
- A submit button ("Enregistrer")

Wrapping in its own `<form>` means Turbo handles the submit without affecting the rest of the page. On success, Turbo follows the redirect back to the show page with the flash notice.

### 3. Profile Section (read-only)

A `glass-card` with a 2-column grid of labelled values:
- City (`city`)
- Country (`country`)
- Diploma (`diploma`)
- Employment status (`employment_status`)

Each cell: label in `text-[10px] font-black text-slate-400` + value in `text-sm text-slate-900`. Show `"—"` for blank fields.

Also shows:
- **Joined:** `created_at` formatted with `l(..., format: :short)`
- **Onboarding:** badge — "Complet" (green) if `user.onboarded?`, "Incomplet" (gray) otherwise

### 4. Skills Section

A `glass-card` with a heading "Compétences". Renders each skill as a pill badge (`shared/badge`). If none: `"Aucune compétence enregistrée"` in muted text.

### 5. Diagnostics Section

A `glass-card` with a heading "Diagnostics". A small table with columns:
- **Date** — `created_at` formatted short
- **Statut** — `status` humanized (pending / in_progress / completed / etc.)
- **Complété le** — `completed_at` formatted short, or `"—"`

If none: `"Aucun diagnostic"` in muted text.

### 6. Payments Section

A `glass-card` with a heading "Paiements". A small table with columns:
- **Date** — `created_at` formatted short
- **Montant** — `amount_cents / 100` with currency (`XOF`)
- **Statut** — `status` humanized (pending / confirmed / failed)
- **Fournisseur** — `provider` humanized (stripe / pawapay)

If none: `"Aucun paiement"` in muted text.

---

## Error Handling

Role is an enum — invalid values are rejected at the model level. The `update` action re-renders `show` with `status: :unprocessable_content` if validation fails, which displays any errors via the existing error block pattern.

---

## Testing

- `test/controllers/admin/users_controller_test.rb`: add tests for `show` (renders 200) and `update` (role change → redirect, invalid role → 422).
- No model tests needed — role enum validation is already exercised by existing tests.

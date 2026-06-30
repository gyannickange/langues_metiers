# Admin Hardening — Design

Date: 2026-06-28

## Context

The admin area (`Admin::BaseController` and its subclasses) currently has only a coarse gate: `authenticate_user!` + `current_user&.admin?`. A scan of the current security posture found three concrete gaps, scoped here as a single spec:

1. No brute-force lockout or admin-specific session timeout.
2. No rate limiting on login or on the `/admin` namespace.
3. No audit trail of who changed what in admin-managed content.

Explicitly out of scope (flagged and deferred during brainstorming, each for its own reason):

- **Site-wide Content-Security-Policy** — currently fully disabled. Enabling one is valuable but risky (can break OAuth redirects, Turbo/Stimulus inline scripts, third-party embeds) and needs its own design + testing pass across the *whole* site, not just `/admin`.
- **Raising the global Devise `password_length` minimum** — affects all users, not just admins; a site-wide policy decision, not an admin-hardening one.
- **Pundit-based authorization granularity** (splitting `admin?` into roles like read-only vs full admin) — not requested for this pass; the existing single `admin?` boolean stays.
- **Custom security headers** — checked via `ActionDispatch::Response.default_headers` and confirmed Rails already sets sane defaults (`X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, etc.), unmodified. No work needed here.

## 1. Auth & session security

### Lockout (Devise `:lockable`)

Add `:lockable` to the `User` model's devise modules, alongside the existing `:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable`.

- Migration adds `failed_attempts` (integer, default 0), `unlock_token` (string), `locked_at` (datetime) to `users`.
- Config in `config/initializers/devise.rb`:
  - `config.lock_strategy = :failed_attempts`
  - `config.unlock_strategy = :time`
  - `config.maximum_attempts = 10`
  - `config.unlock_in = 1.hour`
  - `config.unlock_keys = [:email]` (kept default; unused under `:time` strategy but harmless)

This applies to all password-based logins (shared login form), which is correct: an attacker doesn't know in advance whether a given account is an admin, so brute-force protection has to sit on the login form itself. OmniAuth (Google/Facebook) sign-ins are unaffected — `failed_attempts` only increments on failed password attempts.

### Admin-only idle session timeout (30 min)

Devise's `:timeoutable` module is **not** used, because it applies to the `User` model globally — it would force-expire sessions for ordinary site visitors too, which is an unwanted UX change outside this spec's scope.

Instead, a custom timeout scoped to `Admin::BaseController`:

```ruby
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :enforce_admin_session_timeout

    private

    ADMIN_SESSION_TIMEOUT = 30.minutes

    def enforce_admin_session_timeout
      last_seen = session[:admin_last_seen_at]
      if last_seen && Time.zone.parse(last_seen) < ADMIN_SESSION_TIMEOUT.ago
        reset_session
        redirect_to new_user_session_path, alert: "Session expirée, merci de vous reconnecter."
        return
      end
      session[:admin_last_seen_at] = Time.zone.now.to_s
    end
  end
end
```

Placed after `require_admin!` so it only ever runs for already-authenticated admins, and only touches `/admin` requests.

## 2. Request-level protections (rack-attack)

Add `gem "rack-attack"` and `config/initializers/rack_attack.rb`:

```ruby
class Rack::Attack
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip.presence
    end
  end

  throttle("admin/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/admin")
  end

  self.throttled_responder = lambda do |request|
    [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please try again shortly.\n"]]
  end
end
```

`Rack::Attack` middleware is inserted in `config/application.rb` (`config.middleware.use Rack::Attack`), guarded so it's active in all environments except `test` (avoids flaky throttling in the test suite — tests that specifically exercise rack-attack behavior enable it per-test).

## 3. Audit logging (PaperTrail)

Add `gem "paper_trail"`, run `rails generate paper_trail:install` (creates the `versions` table migration).

### Versioned models

```ruby
class DiagnosticQuestion < ApplicationRecord
  has_paper_trail
end

class Assessment < ApplicationRecord
  has_paper_trail
end

class Career < ApplicationRecord
  has_paper_trail
end

class AcademicField < ApplicationRecord
  has_paper_trail
end

class Skill < ApplicationRecord
  has_paper_trail
end

class Trajectory < ApplicationRecord
  has_paper_trail
end

class User < ApplicationRecord
  has_paper_trail only: [:role]
end
```

`User` is scoped to the `role` column only — privilege-escalation-relevant, not every profile edit (name, city, diploma, etc.), which would be noise.

### Whodunnit

```ruby
module Admin
  class BaseController < ApplicationController
    before_action { PaperTrail.request.whodunnit = current_user&.id }
  end
end
```

Scoped to `Admin::BaseController`, not `ApplicationController` — only changes made through the admin area need attribution, and `role` changes happen exclusively through `Admin::UsersController`.

### UI: history display

A shared partial `admin/shared/_version_history` rendering `record.versions.reverse_chronological` (who via `User.find_by(id: version.whodunnit)`, what changed via `version.changeset`, when via `version.created_at`):

- `academic_fields/show.html.erb`, `skills/show.html.erb` — already have show pages, history added there.
- `careers/edit.html.erb`, `assessments/edit.html.erb`, `trajectories/edit.html.erb` — no show page exists for these, so history goes on the edit page.
- `diagnostic_questions` — pure inline-editing rows (no edit/show page at all, per the in-progress inline-CRUD branch). Each row in `_question_row.html.erb` gets a small "history" icon/link that lazy-loads a Turbo Frame containing the shared partial for that question, served by a new `Admin::DiagnosticQuestions#history` action — consistent with the existing Hotwire/Turbo-based inline editing pattern already used on this branch.

## Testing

Standard minitest, matching existing test layout (`test/controllers/admin/...`, `test/models/...`):

- `Admin::BaseController` (via a representative subclass test, e.g. `Admin::DiagnosticsControllerTest`): idle timeout redirects after 30 min of inactivity; does not redirect within the window.
- Devise lockable: a model/integration test confirming an account locks after 10 failed attempts and the lock auto-clears after 1 hour (or via Devise's own test helpers).
- Rack::Attack: a request-spec-style test (with rack-attack enabled for that test) confirming the 6th login attempt within 20s from the same IP/email gets a 429, and confirming `/admin` requests beyond the throttle limit get a 429.
- PaperTrail: model tests confirming `DiagnosticQuestion`/`Assessment`/etc. create a version on update; confirming `User` versions only on `role` changes (no version created when e.g. `first_name` changes); confirming `whodunnit` is set correctly when the change is made through an admin controller action.

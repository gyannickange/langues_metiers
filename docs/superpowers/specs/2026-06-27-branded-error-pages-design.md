# Branded error pages — design

## Problem

`public/400.html`, `404.html`, `406-unsupported-browser.html`, `422.html`, `500.html` are the
unmodified Rails-generated defaults: plain white background, generic Rails logo, English copy.
None of them match the Insertrice brand (gold `--primary` / deep green `--secondary`, Tailwind v4
design tokens in `app/assets/tailwind/application.css`, French-only UI).

## Scope

All 5 status pages: 400, 404, 406, 422, 500.

## Approach

Two tracks, because Rails has two different delivery mechanisms for these pages.

### Track A — dynamic pages for 400, 404, 422, 500

These are the statuses Rails routes through `config.exceptions_app` when an exception is
rescued. We turn them into real Rails-rendered pages so they can reuse the app's layout,
Tailwind build, and shared partials.

- `config/application.rb`: `config.exceptions_app = self.routes`. This only takes effect when
  `consider_all_requests_local` is false (staging/production), so the Rails debug screen still
  shows in development. The routes are also reachable directly (`/404`, `/500`, ...) for manual
  QA in any environment.
- `config/routes.rb`: add explicit `match "/400" | "/404" | "/422" | "/500", to: "errors#show"`
  routes, each constrained/defaulting to its status code.
- `ErrorsController < ActionController::Base` — deliberately not `ApplicationController`, to
  avoid inheriting `allow_browser` and the `ensure_onboarded!` filter, neither of which should
  run on an error page. Single `show` action resolves status from the route default, looks up
  icon/title/description from a small per-status map, and renders with the correct HTTP status.
- `app/views/errors/show.html.erb` — one shared template using `app/views/layouts/error.html.erb`.
- `app/views/layouts/error.html.erb` — minimal layout modeled on `layouts/auth.html.erb` (same
  `<head>`: stylesheet, importmap, csrf/csp tags). Body: centered card on a soft brand-tinted
  background. `shared/_logo` partial (linked to `root_path`) above the card; inside the card a
  large status code, a `lucide_icon` in a tinted circle, title, description, a primary CTA
  ("Retour à l'accueil", `lp-action-primary` class, links to `root_path`), and a small
  "Nous contacter" `mailto:contact@languesmetiers.com` link below.

Per-status content (French), defined once in the controller and mirrored as locale strings under
a new `errors:` namespace in `config/locales/fr.yml`:

| Status | Icon (lucide) | Title | Description |
|---|---|---|---|
| 400 | shield-alert | Requête invalide | La requête n'a pas pu être traitée. Vérifiez l'adresse et réessayez. |
| 404 | compass | Page introuvable | Cette page n'existe pas ou a été déplacée. |
| 422 | ban | Action refusée | Le changement demandé a été rejeté. Réessayez ou retournez à l'accueil. |
| 500 | server-crash | Erreur serveur | Une erreur inattendue est survenue. Nous avons été notifiés. |

### Track B — static self-contained pages for 406 and the last-resort fallbacks

Two cases can never go through `ErrorsController`:

1. **406 unsupported browser**: `allow_browser` (in `ApplicationController`) renders
   `public/406-unsupported-browser.html` directly via `render file:, layout: false` — it bypasses
   routing and layouts entirely.
2. **Total app failure**: if Rails can't boot or respond at all, `exceptions_app` never runs, and
   the web server falls back to serving `public/{400,404,422,500}.html` as plain static files.

Both cases must stay dependency-free (no Tailwind build, no asset pipeline, no ERB) so they work
even when the app is down. We restyle them in place: inline `<style>` blocks using the brand hex
values directly (`#e7c873` primary, `#1f4b43` secondary), the existing font stack, a text-based
wordmark ("Insertrice") instead of the generic Rails logo, French copy matching the table above
(400/404/422/500) or browser-upgrade copy (406), and a plain `<a href="/">Retour à l'accueil</a>`.

## Data flow (Track A)

```
request → unhandled exception → ActionDispatch::ShowExceptions
        → calls exceptions_app (our routes) with PATH_INFO rewritten to /<status>
        → matches /400|/404|/422|/500 route → ErrorsController#show
        → renders errors/show with layouts/error, correct HTTP status code
```

## Testing

- Request spec: `GET /404`, `/422`, `/400`, `/500` each return the expected status code and body
  contains the expected French title.
- Request spec: visiting a nonexistent path (e.g. `/this-does-not-exist`) in an environment with
  `consider_all_requests_local` disabled returns 404 with the branded body (verifies
  `exceptions_app` wiring, not just the direct route).
- No automated test for the static `public/*.html` files (no app context to test against) —
  manual visual check is sufficient.

## Out of scope

- No illustrations/animations beyond the existing brand button/card styles already used
  elsewhere in the app.
- No contact form — a `mailto:` link is sufficient, matching the footer's existing pattern.
- No changes to `406` delivery mechanism (stays a literal static file, per Rails' `allow_browser`
  implementation).

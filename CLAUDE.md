# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Ruby 3.2.2 / Rails 8.0.2**
- **Database**: PostgreSQL with UUID primary keys throughout
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, Import Maps
- **Auth**: Devise with customized routes (`/login`, `/logout`, `/register`)
- **Authorization**: Pundit (policy-based, default deny-all in `ApplicationPolicy`)
- **Background Jobs**: Sidekiq + Redis (or Solid Queue with `SOLID_QUEUE_IN_PUMA=1`)
- **Caching**: Solid Cache (DB-backed)
- **Assets**: Propshaft
- **Slugs**: FriendlyId
- **Pagination**: Pagy
- **I18n**: EN + FR, default FR, locale set from `Accept-Language` header

## Commands

```bash
# Development (starts Rails + Tailwind watcher + Sidekiq)
./bin/dev

# Database
rails db:create db:migrate db:seed

# Tests (Minitest)
rails test
rails test test/models/user_test.rb   # single file

# Linting
rubocop        # check
rubocop -A     # auto-fix

# Security scan
brakeman
```

## Architecture

### Domain Model

- `User` — Devise auth, role enum (`user` / `admin`)
- `Field` — Career fields, FriendlyId slugs, status enum (`inactive` / `active`), routed as `/filieres`
- `Skill` / `Category` — Skills with categories (many-to-many via `categories_skills`)
- `Career` — Career paths; `required_skills` stored as JSONB
- `Roadmap` / `RoadmapStep` / `RoadmapField` — Learning roadmaps linked to fields, steps are ordered
- `UserSkill` — Join table tracking user skill levels

### Controller Namespaces

| Namespace | Purpose |
|-----------|---------|
| (root) | Public pages: home, fields, profiles |
| `admin/` | Admin CRUD for users, fields, skills, careers, roadmaps |
| `api/v1/` | JSON API (profiles) |
| `users/` | Devise controller overrides |

### Key Conventions

- **UUIDs everywhere** — all primary keys are UUIDs; use `SecureRandom.uuid` or let Rails generate them
- **Pundit policies** — every controller action accessing records should go through a policy; `ApplicationPolicy` denies everything by default
- **I18n** — locale is set per-request in `ApplicationController` from the `Accept-Language` header; always use `t()` helpers for user-facing strings
- **Admin guard** — Sidekiq web UI at `/sidekiq` requires `user.admin?`; use the same pattern for any admin-only route

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Production DB connection |
| `REDIS_URL` | Redis for Sidekiq (default: `redis://localhost:6379/1`) |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |
| `SOLID_QUEUE_IN_PUMA` | Set to `1` to run Solid Queue inside Puma instead of Sidekiq |

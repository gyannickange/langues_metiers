---
target: auth page
total_score: 22
p0_count: 0
p1_count: 4
timestamp: 2026-07-13T07-11-08Z
slug: app-views-users-sessions-new-html-erb
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No explicit OTP sending state, delivery expectation, expiry countdown, or resend status. |
| 2 | Match System / Real World | 3 | Plain French and familiar actions work, but “connecte-toi” does not explain that a new email also creates an account. |
| 3 | User Control and Freedom | 2 | Home and change-email exits exist; the OTP step has no direct resend or cancel path. |
| 4 | Consistency and Standards | 2 | The primary flow is cohesive, but exposed Devise registration/password routes are not wired to the existing custom auth controllers/views. |
| 5 | Error Prevention | 2 | HTML constraints help, but the flow does not prevent confusion around expired or superseded OTPs. |
| 6 | Recognition Rather Than Recall | 3 | Google and email paths are explicit and the OTP step repeats the email; the OTP field itself has no visible label. |
| 7 | Flexibility and Efficiency | 2 | Google and email are useful alternatives, but the OTP field omits `autocomplete="one-time-code"` and recovery shortcuts. |
| 8 | Aesthetic and Minimalist Design | 3 | Focused and calm, though the blurred blobs, translucent card, pill controls, and soft shadow read as a familiar AI-auth template. |
| 9 | Error Recovery | 2 | “Code incorrect ou expiré” is plain language, but offers no resend action and is not announced as a live alert. |
| 10 | Help and Documentation | 1 | Legal information exists, but there is no contextual support for missing email, delivery delay, or locked-out users. |
| **Total** | | **22/40** | **Acceptable — significant improvements needed** |

## Anti-Patterns Verdict

**LLM assessment:** The page is polished, calm, and immediately understandable, but it does look template-generated. A centered translucent card, two blurred background circles, pill buttons, and a barely-there shadow are now a standard AI authentication composition. The interface lacks a specific Insertrix trust cue beyond the wordmark and green/gold palette.

**Deterministic scan:** The current detector returned zero findings across `app/views/users/sessions/new.html.erb`, `app/views/users/sessions/_verify_otp.html.erb`, and `app/views/layouts/auth.html.erb`. This is a clean structural result, but it does not measure color contrast, heading semantics, live-region behavior, or recovery completeness. Those manual/browser findings are not detector false positives.

**Visual evidence:** Desktop (1440×1100) and narrow (500×844) Chrome captures render cleanly with no clipping. Playwright launched Chrome but never registered a controllable session, so script injection could not be verified and no reliable user-visible overlay is available.

## Overall Impression

The first step is calm, focused, and easy to scan. The largest opportunity is to make the passwordless flow feel as trustworthy and recoverable as it looks: accessible contrast and a complete OTP state model matter more than additional decoration.

## What's Working

- The page presents only two clear entry paths—Google or email—so cognitive load is low and the primary task is obvious within seconds.
- The email field has a visible label, useful autocomplete, and a large touch target; the controls also hold up in the narrow browser capture.
- The current legal links now point to real Terms and Privacy pages, restoring an important trust signal that was missing in the initial source snapshot.

## Priority Issues

### [P1] The primary action and supporting text fail contrast requirements

**Why it matters:** White on Guidance Gold (`#e7c873`) measures about **1.63:1**; even large bold text requires 3:1. Gray-400 placeholder/legal text on the light surface measures about **2.43:1**, below the 4.5:1 requirement. Low-vision users can miss the primary action label, field example, and consent copy.

**Fix:** Use Confidence Green Strong for text on gold, move placeholder and legal copy to at least gray-600 or a brand-tinted equivalent, and verify focus-ring contrast independently.

**Suggested command:** `/impeccable audit auth contrast and focus states`

### [P1] The OTP step has no complete recovery or status model

**Why it matters:** Users are told only that a code was sent. There is no expected delivery time, ten-minute expiry cue, resend action/cooldown, sending indicator, or help when mail does not arrive. “Modifier l'adresse e-mail” is an indirect workaround, not an understandable recovery path.

**Fix:** Add a visible “Renvoyer le code” action with cooldown/status, explain the ten-minute lifetime, disable and relabel submitters during requests, and provide a concise missing-email hint.

**Suggested command:** `/impeccable harden auth OTP states`

### [P1] Screen-reader semantics are incomplete

**Why it matters:** The login view has no page-level heading, the OTP input relies on a placeholder instead of a label, and the Turbo-replaced error has no `role="alert"` or live-region behavior. Visual users understand the flow; assistive-technology users receive a weaker version of it.

**Fix:** Add an `h1` (visually styled or screen-reader-only as appropriate), a persistent OTP label/instructions linked with `aria-describedby`, `autocomplete="one-time-code"`, and an announced error/status region.

**Suggested command:** `/impeccable audit auth semantics and keyboard flow`

### [P1] Legacy Devise entry points can expose a different auth experience

**Why it matters:** `:registerable` and `:recoverable` expose `/users/sign_up` and password-reset routes, but `devise_for` wires only sessions and OAuth callbacks. The project has custom registration/password controllers, yet they are not routed, and project-specific registration/password views are absent. OAuth failure can redirect directly to `new_user_registration_url`, making this inconsistency reachable.

**Fix:** Decide whether password and standalone registration flows still belong in a passwordless product. Either remove/redirect unused routes and modules, or wire the custom controllers and build matching states in the same auth system.

**Suggested command:** `/impeccable harden auth route consistency`

### [P2] The visual language is polished but generic

**Why it matters:** The blurred blobs + glass card + pill controls pattern feels interchangeable with many SaaS login screens. It communicates “modern app,” but not “credible francophone career guidance.”

**Fix:** Replace decorative blur with one purposeful Insertrix trust cue—what the user gains after signing in, privacy reassurance, or a restrained orientation motif—and use solid surfaces where translucency carries no meaning.

**Suggested command:** `/impeccable quieter auth visual treatment`

## Cognitive Load

The flow passes all eight checklist items: single focus, clear grouping, strong hierarchy, one decision at a time, only two visible options, no memory bridge, and progressive disclosure into OTP. Cognitive load is low. The problem is not complexity; it is missing recovery information at the moment users need it.

## Emotional Journey

The first screen feels calm and credible. The emotional valley begins after email submission: users wait without knowing how long delivery should take, then face a code that can expire without a countdown or resend action. The flow needs reassurance and recovery at that exact point, not more decoration on the first screen.

## Persona Red Flags

**Jordan (First-Timer):** The initial action is obvious, but “Connecte-toi” does not tell a first-time user that entering a new email creates an account. On the OTP step, Jordan has no answer to “How long should this take?” or “What if nothing arrives?”

**Sam (Accessibility-Dependent):** The white/gold CTA and gray-400 helper text fail contrast. The login step has no semantic `h1`, the OTP control lacks a persistent label, and Turbo error feedback is not exposed as an alert/live region.

**Casey (Distracted Mobile User):** Large controls and the Google shortcut work well. Returning after an interruption is fragile because the code expiry is invisible, there is no direct resend, and `autocomplete="one-time-code"` is missing.

## Minor Observations

- The 0.8-second entrance animation is long for task UI, although the global reduced-motion rule correctly collapses it.
- The Google button has no explicit project-level focus treatment; relying on browser defaults makes focus styling inconsistent with the email path.
- French legal labels would read more naturally as “Conditions générales” and “Politique de confidentialité” in sentence case.
- The desktop composition has substantial unused space; this is not harmful, but it increases the sense of a generic centered-card template.

## Questions to Consider

- Should the email action explicitly say that it connects existing users **and creates an account for new users**?
- Is the passwordless OTP flow now canonical enough to remove password recovery and standalone registration routes entirely?
- Should Insertrix earn trust here through a clearer privacy/reassurance message instead of decorative background blur?

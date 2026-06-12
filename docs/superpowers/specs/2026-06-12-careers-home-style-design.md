# Careers Home-Style Redesign

## Goal

Update the public careers index so it feels like a direct continuation of the
home page while preserving the careers content, ordering, and diagnostic links.

## Approved Direction

The careers page will adopt the current home page's calm, flat visual system:
white and light-gray surfaces, confidence green structure, restrained gold
actions, rounded bordered panels, and the shared `lp-*` typography and action
styles.

The existing careers-page glassmorphism, oversized radii, decorative glows,
uppercase headings, and premium pill buttons will be removed.

## Page Structure

### Navigation

Extract the navigation portion of the home landing-page header into a shared
partial so the home and careers pages use the same desktop and mobile
navigation. Keep the current navigation destinations and mobile-menu behavior.

The home page will continue to render its existing home-specific hero beneath
that navigation. The careers page will render its own careers-specific hero.

### Careers Hero

Use the home hero's two-column structure, spacing, typography, gold-highlight
treatment, and primary action style.

- Heading: "Explorez les métiers qui valorisent votre profil"
- Supporting copy: preserve the current explanation about the 20 careers.
- Primary action: preserve the current signed-in-aware diagnostic destination.
- Image: keep `cinematic_career_hero.png`, with an accessible French alt text.
- Responsive behavior: stack copy above the image on small screens.

### Careers Collection

Place all published careers in a light-gray section using the same container,
section spacing, heading hierarchy, and three-column responsive grid as the
home page's careers preview.

Each career card will match the home page card anatomy:

- White background, neutral border, `rounded-2xl`, no glass or glow.
- Green-tinted icon container.
- Sentence-case career title.
- Three-line description preview.
- Divider and sector metadata.

All careers from `@careers` remain visible and ordered by the existing
controller behavior.

### Final Call To Action

Replace the current decorated gradient block with a restrained confidence-green
panel matching the home page's solution and final-action sections.

- Preserve the current diagnostic destination.
- Use the shared `lp-action-primary` button.
- Keep the existing call-to-action meaning while removing uppercase tracking
  and decorative star artwork.

## Shared Components

Create a shared landing navigation partial and render it from both the existing
home landing header and the careers page. Do not duplicate the navigation
markup.

Reuse the existing `lp-action-primary`, `lp-section-title`, and
`lp-section-copy` classes. Add new shared CSS only if the view cannot express a
required home-style behavior with existing utilities.

## Accessibility And Responsive Requirements

- Preserve semantic heading order with one page-level `h1`.
- Provide descriptive image alt text.
- Preserve visible keyboard focus states and the accessible mobile-menu button.
- Keep action targets at least 44 pixels high.
- Avoid horizontal overflow at mobile widths.
- Respect the existing reduced-motion behavior.

## Testing

- Add or update a careers controller test to assert the page renders the shared
  navigation, careers hero copy, all published careers, and diagnostic action.
- Run the relevant controller tests and asset build.
- Verify the careers page visually at desktop and mobile widths, including the
  mobile navigation and diagnostic link.
- Compare the rendered careers page with the rendered home page for navigation,
  typography, card anatomy, spacing, palette, and action styling.

## Out Of Scope

- Career detail pages or new career interactions.
- Changes to career data, publication rules, or ordering.
- Changes to diagnostic routing or authentication behavior.
- A broader redesign of other public pages.

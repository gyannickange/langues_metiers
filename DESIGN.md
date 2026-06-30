---
name: Insertrix
description: An encouraging and credible career-guidance product for students and young graduates.
colors:
  guidance-gold: "#e7c873"
  guidance-gold-strong: "#d4a52a"
  confidence-green: "#1f4b43"
  confidence-green-strong: "#14302b"
  mint-support: "#b9e3d0"
  surface: "#ffffff"
  surface-subtle: "#fafafa"
  ink: "#0a0a0a"
  border: "#e5e5e5"
  destructive: "#e7000b"
typography:
  headline:
    fontFamily: "Ubuntu Condensed, ui-sans-serif, sans-serif, system-ui"
    fontSize: "2.25rem"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  title:
    fontFamily: "Ubuntu Condensed, ui-sans-serif, sans-serif, system-ui"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: 1.2
  body:
    fontFamily: "Ubuntu Condensed, ui-sans-serif, sans-serif, system-ui"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Ubuntu Condensed, ui-sans-serif, sans-serif, system-ui"
    fontSize: "0.75rem"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "0.05em"
rounded:
  sm: "0.375rem"
  md: "0.625rem"
  lg: "1rem"
  xl: "1.5rem"
  panel: "2rem"
spacing:
  xs: "0.25rem"
  sm: "0.5rem"
  md: "1rem"
  lg: "1.5rem"
  xl: "2rem"
  section: "4rem"
components:
  button-primary:
    backgroundColor: "{colors.guidance-gold}"
    textColor: "{colors.confidence-green-strong}"
    rounded: "{rounded.lg}"
    padding: "0.875rem 1.5rem"
    typography: "{typography.label}"
  button-secondary:
    backgroundColor: "{colors.confidence-green}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "0.875rem 1.5rem"
    typography: "{typography.label}"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "0.625rem 0.75rem"
    typography: "{typography.body}"
  panel:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "2rem"
---

# Design System: Insertrix

## 1. Overview

**Creative North Star: "The Career Compass"**

Insertrix should feel like a calm, capable guide beside the user during an important decision. The product uses confident green for structure and trust, restrained gold for progress and primary actions, and clear white surfaces that keep attention on the current task.

The system is product-first: familiar controls, visible progress, and consistent states matter more than spectacle. Warmth comes from supportive language and considered feedback, not childish gamification or excessive decoration.

**Key Characteristics:**
- Clear sequential guidance with one obvious next action.
- Restrained green-and-gold identity with high-contrast neutral surfaces.
- Familiar, rounded product controls with concise labels.
- Professional credibility without corporate stiffness.
- Responsive layouts and visible, accessible interaction states.

## 2. Colors

The palette pairs grounded professional green with optimistic gold, using mint only for supporting data and soft state communication.

### Primary
- **Guidance Gold** (`#e7c873`): Primary actions, progress, selected questionnaire states, and rare emphasis.
- **Guidance Gold Strong** (`#d4a52a`): Hover and stronger emphasis when the base gold lacks contrast.

### Secondary
- **Confidence Green** (`#1f4b43`): Navigation, strong headings, structural surfaces, and trusted actions.
- **Confidence Green Strong** (`#14302b`): High-contrast dark surfaces and prominent text.
- **Mint Support** (`#b9e3d0`): Charts, positive supporting states, and low-emphasis data.

### Neutral
- **Surface** (`#ffffff`): Main content and control backgrounds.
- **Surface Subtle** (`#fafafa`): Secondary panels, sidebars, and grouped content.
- **Ink** (`#0a0a0a`): Primary text.
- **Border** (`#e5e5e5`): Dividers and resting control borders.
- **Destructive** (`#e7000b`): Errors and destructive actions only.

### Named Rules

**The Compass Rule.** Gold marks progress and the preferred next action; it is not a general decoration color.

**The Contrast Rule.** Never rely on color alone for status, selection, or validation.

## 3. Typography

**Display Font:** Ubuntu Condensed (with `ui-sans-serif`, `sans-serif`, and `system-ui` fallbacks)  
**Body Font:** Ubuntu Condensed (with `ui-sans-serif`, `sans-serif`, and `system-ui` fallbacks)  
**Label/Mono Font:** System monospace only for technical values and JSON editing.

**Character:** A single condensed sans keeps the product direct and recognizable. Strong weights communicate confidence; body copy remains readable and concise.

### Hierarchy
- **Headline** (800, `2.25rem`, 1.1): Page-level titles and major results.
- **Title** (700, `1.5rem`, 1.2): Section and panel titles.
- **Body** (400, `1rem`, 1.5): Instructions and explanations, capped around 70 characters per line.
- **Label** (700, `0.75rem`, 0.05em): Buttons, compact metadata, and field labels. Use uppercase sparingly.

### Named Rules

**The Plain-French Rule.** Prefer understandable labels and explanations over professional jargon or unexplained scores.

## 4. Elevation

Insertrix uses a hybrid of borders, tonal surfaces, and restrained ambient shadows. Product controls remain mostly flat at rest; stronger shadows are reserved for floating navigation, important result panels, and hover feedback.

### Shadow Vocabulary
- **Resting Surface** (`0 1px 3px 0 rgba(0,0,0,0.10)`): Standard cards and controls.
- **Raised Surface** (`0 8px 10px -1px rgba(0,0,0,0.10)`): Menus, active panels, and elevated actions.
- **Result Emphasis** (`0 20px 50px rgba(20,48,43,0.20)`): Rarely used for primary result or payment moments.

### Named Rules

**The Flat-by-Default Rule.** A shadow must communicate hierarchy or interaction state, not decorate every container.

## 5. Components

### Buttons
- **Shape:** Rounded rectangle using `1rem` corners for product actions.
- **Primary:** Guidance Gold with Confidence Green Strong text and `0.875rem 1.5rem` padding.
- **Hover / Focus:** Darken or increase contrast without shifting hue; always show a visible focus ring.
- **Secondary / Ghost:** Confidence Green for strong secondary actions; neutral ghost buttons for low-emphasis actions.

### Chips
- **Style:** Compact rounded labels with a tinted background, readable text, and optional icon.
- **State:** Selected chips require a visible check, border, or text change in addition to color.

### Cards / Containers
- **Corner Style:** `1.5rem` to `2rem` for major product panels; smaller radii for controls.
- **Background:** White or Surface Subtle.
- **Shadow Strategy:** Flat at rest with borders; raise only for interaction or true hierarchy.
- **Border:** `1px` neutral border.
- **Internal Padding:** `1.5rem` to `2rem` on major panels.

### Inputs / Fields
- **Style:** White surface, neutral border, `0.625rem` radius, and clear persistent label.
- **Focus:** Strong visible ring and border shift using the product palette.
- **Error / Disabled:** Error text and border for invalid fields; disabled controls retain readable labels and explain why when needed.

### Navigation
- Use familiar top navigation and responsive side navigation patterns. Active items require both color and a structural cue. Mobile navigation must preserve access to the current task and primary action.

### Diagnostic Step

Each diagnostic screen shows the current step, concise instructions, all required questions, and one dominant continuation action. Selected answers must remain clearly visible without relying on animation.

## 6. Do's and Don'ts

### Do:
- **Do** guide one decision at a time and keep the next action obvious.
- **Do** use Guidance Gold (`#e7c873`) for progress and primary actions.
- **Do** explain why a career recommendation fits the user's answers.
- **Do** provide visible focus states, sufficient contrast, semantic markup, and reduced-motion alternatives.
- **Do** use consistent component states across diagnostic, results, payment, and admin workflows.

### Don't:
- **Don't** use corporate stiffness that makes orientation feel bureaucratic or inaccessible.
- **Don't** use childish gamification that trivializes career decisions.
- **Don't** use excessive decoration that competes with the user's task.
- **Don't** use generic AI or SaaS styling with interchangeable cards, gradients, and empty claims.
- **Don't** use dense professional jargon or unexplained scoring.
- **Don't** use glassmorphism, oversized radii, glow effects, or uppercase tracked labels as defaults.
- **Don't** use colored side-stripe borders as card or callout accents.

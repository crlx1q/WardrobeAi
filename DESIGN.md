---
name: ClotheAI
colors:
  surface: '#fdf8f8'
  surface-dim: '#ddd9d8'
  surface-bright: '#fdf8f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3f2'
  surface-container: '#f1edec'
  surface-container-high: '#ebe7e6'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#444748'
  inverse-surface: '#313030'
  inverse-on-surface: '#f4f0ef'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1b'
  on-primary-container: '#858383'
  inverse-primary: '#c8c6c5'
  secondary: '#5d5f5f'
  on-secondary: '#ffffff'
  secondary-container: '#dddddd'
  on-secondary-container: '#606161'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#2c1600'
  on-tertiary-container: '#a77b4e'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474746'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c6'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#ffdcbd'
  tertiary-fixed-dim: '#f0bd8b'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#623f18'
  background: '#fdf8f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
  display-lg:
    fontFamily: Playfair Display
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Playfair Display
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-sm:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.08em
  button:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  unit: 8px
  container-max: 1200px
  gutter: 24px
  margin-desktop: 64px
  margin-mobile: 20px
---

## Brand & Style
The design system embodies an "Editorial Tech" persona—merging the high-end sophistication of a fashion magazine with the precision of artificial intelligence. It targets style-conscious individuals who value curation over clutter. The emotional response should be one of calm, effortless organization and aspirational beauty.

The visual style is a blend of **Minimalism** and **Glassmorphism**. It utilizes expansive "Ivory Silk" whitespace to create an airy, breathable environment. High-contrast "Onyx" typography provides a luxury editorial feel, while soft glassmorphic overlays add a sense of digital lightness and modern intelligence. The interface should feel like a high-end boutique: curated, quiet, and premium.

## Colors
The palette is rooted in timeless neutrals to allow clothing photography to remain the focal point.

*   **Primary (Onyx):** Used for primary actions, high-level headers, and core brand elements. It conveys authority and timelessness.
*   **Background (Ivory Silk):** A warm, off-white that prevents screen fatigue and feels more expensive than pure white.
*   **Secondary (Cloud Grey):** Used for subtle borders, inactive states, and structural dividers.
*   **Accent (Dusty Rose):** A muted, sophisticated tone used sparingly for highlights, "AI-powered" suggestions, and active selection states.

## Typography
The typographic hierarchy relies on the tension between the classical **Playfair Display** and the utilitarian **Inter**. 

Headlines should be expressive and use tighter letter-spacing to mimic fashion mastheads. For mobile, display sizes are scaled down to ensure legibility without excessive wrapping. UI labels and metadata utilize "label-caps" to provide clear organization without competing with the elegance of the headers.

## Layout & Spacing
The layout follows a **Fluid Grid** model with generous margins to preserve the minimalist aesthetic. 

*   **Desktop:** 12-column grid with 64px outer margins. Content is centered with a max-width of 1200px to maintain readability.
*   **Mobile:** 4-column grid with 20px outer margins. 
*   **Spacing Rhythm:** All spacing must be multiples of 8px. Use 48px or 64px of vertical space between major sections to emphasize the "Airy" quality. Components within cards should use 16px or 24px padding.

## Elevation & Depth
This design system avoids heavy shadows in favor of **Tonal Layers** and **Glassmorphism**.

1.  **Base Layer:** The "Ivory Silk" canvas.
2.  **Mid Layer (Cards/Containers):** Flat white surfaces with a very soft, 15% opacity Onyx shadow (Blur: 30px, Y: 10px) to create a "floating" effect.
3.  **Overlay Layer (Modals/AI Suggestions):** A glassmorphic effect using a white fill at 70% opacity with a 20px backdrop blur. This signifies "AI Intelligence" and temporary context.
4.  **Interaction:** On hover, cards should subtly lift (shadow deepens slightly) or scale (1.02x) to provide tactile feedback.

## Shapes
The shape language is defined by ultra-smooth, organic curves. A standard border radius of **24px** (rounded-xl/pill-shaped) is applied to all primary containers, buttons, and input fields. This softness contrasts with the sharp, high-contrast serif typography, making the technology feel approachable and "couture." Small elements like chips use a full pill radius.

## Components
*   **Buttons:** Primary buttons are solid Onyx with white Inter medium text. Secondary buttons use a Cloud Grey border (1px) with Onyx text.
*   **Cards:** Outfit cards feature a 24px corner radius, no border, and a soft ambient shadow. Images should fill the container with a subtle `multiply` blend mode against the Ivory Silk background.
*   **Chips:** Used for "Style Tags" (e.g., #Minimalist, #Summer). These are pill-shaped, using Cloud Grey backgrounds and Onyx text.
*   **Input Fields:** Ghost-style inputs with a 1px Onyx bottom border or a fully rounded 24px field with a very light Cloud Grey fill.
*   **AI Indicators:** Use the Dusty Rose accent color for sparks, AI-generated icons, or loading states to differentiate automated suggestions from user-curated content.
*   **Icons:** Use 1px stroke-width linear icons. Avoid solid fills unless the icon is in an active state.
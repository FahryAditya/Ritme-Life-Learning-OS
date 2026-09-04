---
name: Ritme
colors:
  surface: '#fbf8ff'
  surface-dim: '#dad9e3'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f2fc'
  surface-container: '#eeedf7'
  surface-container-high: '#e9e7f1'
  surface-container-highest: '#e3e1eb'
  on-surface: '#1a1b22'
  on-surface-variant: '#484554'
  inverse-surface: '#2f3037'
  inverse-on-surface: '#f1eff9'
  outline: '#797586'
  outline-variant: '#cac4d7'
  surface-tint: '#6241d6'
  primary: '#532ec7'
  on-primary: '#ffffff'
  primary-container: '#6c4ce0'
  on-primary-container: '#ebe4ff'
  inverse-primary: '#cbbeff'
  secondary: '#6446c6'
  on-secondary: '#ffffff'
  secondary-container: '#987cfe'
  on-secondary-container: '#2e0085'
  tertiary: '#534978'
  on-tertiary: '#ffffff'
  tertiary-container: '#6b6192'
  on-tertiary-container: '#ece4ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e6deff'
  primary-fixed-dim: '#cbbeff'
  on-primary-fixed: '#1d0061'
  on-primary-fixed-variant: '#4a21be'
  secondary-fixed: '#e7deff'
  secondary-fixed-dim: '#ccbeff'
  on-secondary-fixed: '#1f0060'
  on-secondary-fixed-variant: '#4c2aad'
  tertiary-fixed: '#e7deff'
  tertiary-fixed-dim: '#ccbff6'
  on-tertiary-fixed: '#1e1340'
  on-tertiary-fixed-variant: '#4a406f'
  background: '#fbf8ff'
  on-background: '#1a1b22'
  surface-variant: '#e3e1eb'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  screen-margin: 20px
  card-padding: 20px
  gutter-sm: 8px
  gutter-md: 16px
  gutter-lg: 24px
  radius-pill: 9999px
---

## Brand & Style

Ritme is a Personal Life & Learning OS designed for modern knowledge workers, lifelong learners, and high-achievers who want to harmonize their daily tasks, finances, music, and learning notes into a single ambient flow powered by Gemini AI. The visual style marries **Glassmorphism** with a 2026 trend-forward edge: frosted glass cards, vibrant purple gradients, and soft lavender-white atmospheres. 

The emotional response should be one of focused serenity, cognitive clarity, and inspiring momentum. The interface feels weightless yet grounded, encouraging deep work and mindful exploration through a futuristic, premium lens.

## Colors

The color palette is built around an expansive lavender-white canvas that breathes life into rich purple gradients. 

- **Primary (`#6C4CE0`):** The signature deep violet used for primary actions, active states, and anchor points.
- **Secondary (`#8B6FF0`):** A luminous mid-purple used for glowing gradients, secondary accents, and interactive highlights.
- **Tertiary (`#D4C7FF`):** A soft pastel lilac utilized for subtle borders, tag backgrounds, and secondary container fills.
- **Neutral (`#F7F5FF`):** The ethereal base background, replacing harsh white with a warm, tinted lavender ambiance.

## Typography

Typography relies on a single, welcoming geometric grotesque family to maintain structural harmony across the OS. Letter spacing is slightly tightened on display headers for a modern, punchy silhouette, while body text remains wide and legible for long-form learning notes.

## Layout & Spacing

The layout follows a fluid mobile grid system optimized for thumb-driven ergonomics. 
- **Margins & Gutters:** Consistent 20px horizontal screen margins with 16px card gutters ensure breathing room without sacrificing density.
- **Scroll Behavior:** Vertical stacking with floating sticky elements—specifically a bottom pill navigation bar and a contextual Gemini AI floating action hub.

## Elevation & Depth

Depth is achieved through **Glassmorphism** and ambient tinted layers rather than heavy drop shadows.
- **Frosted Surfaces:** Cards use semi-transparent white fills (`rgba(255, 255, 255, 0.65)`) paired with a high-intensity backdrop blur (`blur(20px)`).
- **Ghost Borders:** Delicate 1px borders using linear gradients fading from white to transparent define the edges of floating cards.
- **Ambient Glows:** Low-opacity purple light sources (`#6C4CE0` at 15% opacity) cast soft color bleeds behind primary interactive nodes to simulate depth.

## Shapes

The shape language is heavily pill-driven and friendly, utilizing high-radius corners to communicate softness, agility, and modern fluidity.
- **Containers:** Default cards use generous outer radii (`24px`).
- **Interactive Elements:** Buttons, chips, and navigation bars use fully rounded pill shapes (`9999px`) to invite touch and playful interaction.

## Components

- **Buttons:** Primary action buttons feature the signature `#6C4CE0` to `#8B6FF0` gradient, subtle inner highlights, and a pill shape. Secondary buttons use frosted translucent fills with a crisp purple outline.
- **Chips & Tags:** Capsule-shaped metadata tags with soft pastel purple backgrounds (`#D4C7FF` at 30% opacity) and deep purple typography for categorizing tasks, finances, and learning notes.
- **Input Fields:** Search and note inputs use translucent glass containers with subtle inner shadows, featuring floating placeholder labels that transition smoothly on focus.
- **Cards:** The core structural unit. Frosted glass rectangles with glowing borders, designed to house modular widgets for tasks, finance trackers, and mini music players.
- **Gemini AI Core Orb:** A floating, pulsating gradient sphere anchored near the bottom right, serving as the universal gateway to AI-assisted summaries, task generation, and conversational querying.
- **Navigation:** A floating bottom pill navigation bar that houses core destinations (Home, Finance, Notes, Music, OS Settings) with active state glow indicators.
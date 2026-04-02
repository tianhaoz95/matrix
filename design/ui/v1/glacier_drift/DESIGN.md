# Design System Strategy: The Alpine Playground

## 1. Overview & Creative North Star
This design system moves away from the rigid, sterile "Office Kanban" and adopts the **Creative North Star: The Digital Snowscape.**

Unlike traditional productivity tools that rely on tight grids and sharp corners, this system embraces an "Energetic Snowball" philosophy—it is soft, buoyant, and intentionally asymmetrical. We leverage high-end editorial techniques—such as extreme roundedness, oversized display type, and layered translucency—to make task management feel less like "work" and more like an organized play session. By utilizing a "Soft Minimalism" approach, we ensure that while the interface is playful, the AI-driven data remains the hero.

---

## 2. Colors & Surface Philosophy
The palette is built on a foundation of high-latitude neutrals and crystalline accents.

*   **The "No-Line" Rule:** To achieve a premium, custom feel, **1px solid borders are strictly prohibited for sectioning.** Structural boundaries must be defined through background color shifts. For example, a Kanban column (`surface-container-low`) sits directly on the `background` without an outline.
*   **Surface Hierarchy & Nesting:** We use "Tonal Layering" to define depth.
    *   **Level 0:** `surface` (#f5f7f9) - The base snowfield.
    *   **Level 1:** `surface-container-low` (#eef1f3) - For secondary sidebar areas.
    *   **Level 2:** `surface-container-lowest` (#ffffff) - For primary task cards to make them "pop" against the snow.
*   **The "Glass & Gradient" Rule:** Floating action buttons and high-priority AI insights should utilize glassmorphism. Use `surface_container_lowest` at 70% opacity with a `20px` backdrop blur. 
*   **Signature Textures:** Main CTAs should not be flat. Use a linear gradient from `primary` (#005da6) to `primary_container` (#54a3ff) at a 135-degree angle to mimic the glint of sunlight on ice.

---

## 3. Typography: Editorial Play
We pair **Plus Jakarta Sans** (Headlines) with **Be Vietnam Pro** (Body) to balance character with extreme legibility.

*   **Display & Headline:** Used for board titles and AI summaries. The high x-height of Plus Jakarta Sans provides an authoritative yet friendly voice.
*   **Body & Title:** Be Vietnam Pro handles the "work." It is optimized for the quick scanning required in Kanban workflows.
*   **Intentional Scale:** We use a high-contrast scale. A `display-lg` (3.5rem) title might sit next to a `body-md` (0.875rem) description to create a sophisticated, editorial rhythm that feels custom-built, not templated.

---

## 4. Elevation & Depth
In this system, light is your primary architect.

*   **The Layering Principle:** Avoid shadows for static layout elements. Place a `surface-container-highest` element inside a `surface-container-low` parent to create a "recessed" look. 
*   **Ambient Shadows:** For interactive elements like "Dragged Cards," use extra-diffused shadows. 
    *   *Spec:* `0px 20px 40px rgba(44, 47, 49, 0.06)` (using a tinted `on-surface` color). This mimics natural light passing through snow.
*   **The "Ghost Border" Fallback:** If accessibility requires a border (e.g., input focus), use `outline_variant` at **15% opacity**. Never use 100% opacity for lines.
*   **Soft Shapes:** Follow the `ROUND_SIXTEEN` rule. Small components (chips) use `full` (9999px), while large containers (cards) use `xl` (3rem) or `lg` (2rem).

---

## 5. Components

### Cards & Task Items
*   **Style:** No borders. Background: `surface-container-lowest`. 
*   **Spacing:** Use `spacing-4` (1.4rem) internal padding. 
*   **Interaction:** On hover, transition the background to `surface-bright` and apply an Ambient Shadow.

### Buttons
*   **Primary:** Gradient (`primary` to `primary_container`), `full` roundedness, white text (`on_primary`).
*   **Secondary:** `surface-container-high` background with `primary` text. No border.
*   **Tertiary:** Transparent background, `primary` text, soft `surface-variant` hover state.

### AI Kanban Columns
*   **Layout:** Forbid divider lines. Separate columns using `spacing-6` (2rem) and a background of `surface-container-low`.
*   **Headers:** Use `title-lg` with a playful `secondary` (#4555a8) accent icon.

### Chips (Tags)
*   **Style:** `surface-tertiary-container` background with `on-tertiary-container` text. High roundness (`full`). These should look like smooth river stones.

### Input Fields
*   **Style:** `surface-container-highest` background. No border. On focus, use a "Ghost Border" of `primary` at 20% and a subtle `surface-container-lowest` glow.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical padding in hero sections to create a "drifting snow" energy.
*   **Do** use the `secondary` indigo (#4555a8) for deep-focus moments or "Night Mode" accents.
*   **Do** leverage the `spacing-10` and `spacing-12` tokens to give elements massive breathing room. Premium design is defined by what you leave out.

### Don't
*   **Don't** use pure black (#000000) for text. Always use `on_surface` (#2c2f31) to keep the vibe "soft."
*   **Don't** use 90-degree corners. Even "sharp" elements should have at least `sm` (0.5rem) rounding.
*   **Don't** stack more than three levels of surface containers. It leads to visual "clutter" and breaks the snow-like simplicity.
*   **Don't** use standard "drop shadows" that are small and dark. If it doesn't feel like a soft glow, it's too heavy.
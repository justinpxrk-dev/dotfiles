# theme-system.md

_An explanation of the generation method and implementation details used in `dot_scripts/themes/executable_generate_base24_palette.py`._

---

## Description

A theming system designed for long coding sessions, grounded in how the eye perceives light. The human eye responds _logarithmically_ to relative changes in perceptual brightness — minimizing local brightness variance, _especially_ in low ambient light, matters more than controlling global averages. Hue and chroma carry the primary load for readability and syntax differentiation. I personally find the generated themes reduce eye strain and increase text reading speed.

---

## Human Perceptual Model

- Visual perception is adaptive and relative rather than absolute. Perceived brightness depends more on local contrast and ocular adaptation state than average screen luminance.

- Low ambient light increases pupil dilation, retinal scatter, halation, chromatic aberration, and sensitivity to local luminance discontinuities; high ambient light constricts pupils, improves optical acuity, and raises tolerable luminance and contrast ranges.

---

## CAM16 HCT Color Space

The CAM16 HCT color space (used by Material Design 3) is well-suited to modeling constraints because it separates hue, perceptual chroma, and perceived tone into dimensions that more closely track human visual response than device-oriented spaces such as RGB or HSL.

---

## Principles

1. **Adaptation stability.** Minimize local tone discontinuities. Peak local contrast matters more than global averages. Maintain smooth tone across adjacent syntax regions.

2. **Syntax Readability.** Use well-spaced hues and chroma ranges (dark: 30–50 for accents, 40–60 for bright accents; light: 60–70 for accents, 70–80 for bright accents) for differentiating colors. Chroma must be ≥ 6; below this point, color differentiation is impossible.

3. **Accessibility.** Contrast ratios range from a minimum of 4.5 (dim foreground) to a maximum of 6.5 (lightest foreground), respecting WCAG 2.2 AA.

---

## Accents

How the 8 accent and 6 bright accent colors in the base24 palette are created.

### Hue Selection

Accent colors are specified directly as HCT hues. `wavelength_to_hue(lam)` is provided as a design utility — given a wavelength in nm, it finds the HCT hue whose chromaticity direction (at chroma=50, tone=50) most closely aligns with the spectral locus at that wavelength (D65 reference). The tables below list the handpicked hues used in generation.

Dark mode hues sidestep the melanopic peak (~485 nm) and the foreground hue (~555 nm) as much as possible. Light mode hues are spaced for even distribution across the hue range.

#### Dark Mode

| Color   | Hue | Bright Hue |
| ------- | --- | ---------- |
| Red     | 15  | 10         |
| Orange  | 30  | —          |
| Yellow  | 99  | 94         |
| Green   | 172 | 167        |
| Cyan    | 201 | 196        |
| Blue    | 302 | 297        |
| Magenta | 339 | 344        |
| Brown   | 35  | —          |

#### Light Mode

| Color   | Hue | Bright Hue |
| ------- | --- | ---------- |
| Red     | 15  | 10         |
| Orange  | 30  | —          |
| Yellow  | 123 | 118        |
| Green   | 162 | 157        |
| Cyan    | 201 | 196        |
| Blue    | 285 | 280        |
| Magenta | 345 | 349        |
| Brown   | 35  | —          |

### Chroma Calculation

`make_chroma(chroma_min, chroma_max)` produces a wavelength → chroma mapping. The raw expression:

```text
C(λ) = 0.5 − 0.5/(1 + e^((λ−440)/20)) + 0.5/(1 + e^(−(λ−670)/(160/6)))
```

`C(λ)` is normalized over λ ∈ [380, 700] nm by locating its critical points and endpoints, then mapped linearly to [chroma_min, chroma_max].

**Conceptual intent of each term:**

- **Violet sigmoid** (centered 440 nm): suppresses chroma at short wavelengths. The Helmholtz-Kohlrausch (HK) effect causes blues and violets to appear more saturated than their measured chroma warrants, so less chroma headroom is needed there.
- **Red sigmoid** (centered 670 nm): allows more chroma at long wavelengths. HK works in reverse for reds — they need more chroma to reach equivalent perceptual saturation.
- For a given HCT hue, chroma is computed via `_resolve_chroma` — the hue is mapped to its dominant wavelength(s) by `hue_to_wavelengths`, and the chroma curve is evaluated there (weighted sum for multi-wavelength results).

### Tone Calculation

`find_luminance` converts a target contrast ratio against the base surface into a required WCAG relative luminance. `find_tone` then scans all 101 integer tones to find the closest match. Linear scan is used instead of binary search because int-quantized HCT rendering is not strictly monotonic — binary search can return a close but incorrect tone.

### Magenta

Magenta is non-spectral and has no single dominant wavelength. `hue_to_wavelengths` handles this automatically: when the ray from D65 through the color's CIE 1931 xy chromaticity doesn't intersect the spectral locus, it intersects the line of purples — the chord between the 380 nm and 700 nm endpoints. The result is a weighted pair `[(380, 1−s), (700, s)]`, and the chroma curve is evaluated as a weighted sum at those two wavelengths.

### Brown

Brown is a dim orange, cool-shifted by +5° (orange = 30°, brown = 35°), computed with its own chroma curve and `[chroma_min, chroma_max]` parameters.

### Bright Variants

Bright accents are warm-shifted by −5° from their base accent hue (toward red/orange). Magenta is an exception: its bright hue is +5° instead, because in that hue range a positive shift wraps toward red. Bright accents use a dedicated bright chroma curve and target the same contrast ratio.

---

## Surfaces & Text

How the 10 foreground/background shades across `base00`–`07` and `base10`–`11` are created. All backgrounds are achromatic (chroma = 0). The fixed slot differs by mode: `base00` in dark, `base11` in light.

### Dark Mode

- `base00` fixed at `#1e1e1e`. Pure black (`#000000`) is avoided on OLED displays due to halation around bright glyphs.
- **Foregrounds** (`base03`–`07`): hue = 139 (near the photopic peak, ~555 nm, for legibility per unit luminance). Chroma is resolved from the accent chroma curve. Tone is found to achieve contrast ratios of 4.5 / 5.0 / 5.5 / 6.0 / 6.5 against `base00` (dim to lightest).
- **Backgrounds** (`base01`, `base02`, `base10`, `base11`): derived from `base05` as the reference. Contrast ratios of 5.0 / 4.5 / 6.0 / 6.5 between `base05` and each background (`base05` treated as the lighter color, yielding darker surfaces).

### Light Mode

- `base11` fixed at `#ffffff`. `base00` derives as a near-white, reducing glare at the high luminance levels typical during daylight use.
- **Foregrounds** (`base03`–`07`): achromatic (chroma = 0) — colored text on a bright white background causes perceptible afterimages and color bleed. Tone is found to achieve contrast ratios of 4.5 / 5.0 / 5.5 / 6.0 / 6.5 against `base00` (lightest to darkest).
- **Backgrounds** (`base00`, `base01`, `base02`, `base10`): derived from `base05` as the reference. Contrast ratios of 5.5 / 5.0 / 4.5 / 6.0 between `base05` and each background (`base05` treated as the darker color, yielding lighter surfaces closer to white).

### Palette Slot Reference

| Slot          | Dark                  | Light                 |
| ------------- | --------------------- | --------------------- |
| `base00`      | Background            | Background            |
| `base01`      | Lighter Background    | Darker Background     |
| `base02`      | Selection Background  | Darkest Background    |
| `base03`      | Dim Foreground        | Lightest Foreground   |
| `base04`      | Dark Foreground       | Light Foreground      |
| `base05`      | Foreground            | Foreground            |
| `base06`      | Light Foreground      | Dark Foreground       |
| `base07`      | Lightest Foreground   | Dim Foreground        |
| `base08`–`0E` | Accents (Red–Magenta) | Accents (Red–Magenta) |
| `base0F`      | Brown                 | Brown                 |
| `base10`      | Darker Background     | Lighter Background    |
| `base11`      | Darkest Background    | Selection Background  |
| `base12`–`17` | Bright accents        | Bright accents        |

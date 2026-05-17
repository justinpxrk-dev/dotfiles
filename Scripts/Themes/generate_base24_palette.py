from collections.abc import Callable
from typing import cast
import math
from pathlib import Path

from materialyoucolor.hct import Hct  # pyright: ignore[reportMissingTypeStubs]
import sympy  # pyright: ignore[reportMissingTypeStubs]


# -------- Theme System functions ----------


def make_chroma(chroma_min: int, chroma_max: int) -> Callable[[int], int]:
    lam = sympy.Symbol("lam", real=True)
    expr = (
        0.5
        - 0.5 / (1 + sympy.exp((lam - 440) / 20))
        + 0.5 / (1 + sympy.exp(-(lam - 670) / (160 / 6)))
    )
    curve = cast(Callable[[float], float], sympy.lambdify(lam, expr, "math"))  # pyright: ignore[reportUnknownMemberType]
    deriv = cast(
        Callable[[float], float],
        sympy.lambdify(lam, sympy.diff(expr, lam), "math"),  # pyright: ignore[reportUnknownMemberType]
    )

    # Find critical points in [380, 700] via derivative sign changes.
    candidates = [380.0, 700.0]
    prev = deriv(380)
    for _lam in range(381, 701):
        curr = deriv(_lam)
        if prev * curr < 0:
            candidates.append(_lam - 0.5)
        elif prev != 0 and curr == 0:
            candidates.append(float(_lam))
        prev = curr
    values = [curve(p) for p in candidates]
    curve_min, curve_max = min(values), max(values)

    def chroma_curve_norm(lam: int) -> int:
        t = max(0.0, min(1.0, (curve(lam) - curve_min) / (curve_max - curve_min)))
        return round(chroma_min + (chroma_max - chroma_min) * t)

    return chroma_curve_norm


# -------- sRGB / WCAG helpers ----------


def argb_to_rgb(argb: int) -> tuple[float, float, float]:
    r = ((argb >> 16) & 0xFF) / 255.0
    g = ((argb >> 8) & 0xFF) / 255.0
    b = (argb & 0xFF) / 255.0
    return r, g, b


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(argb: int) -> float:
    r, g, b = argb_to_rgb(argb)
    R = srgb_to_linear(r)
    G = srgb_to_linear(g)
    B = srgb_to_linear(b)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B


def hct_to_argb(h: int, c: int, t: int) -> int:
    return Hct.from_hct(h, c, t).argb


def argb_to_hex(argb: int) -> str:
    return "#{:06x}".format(argb & 0xFFFFFF)


# -------- Luminance solver ----------


def find_luminance(argb: int, ratio: float) -> float:
    """Return the luminance of a color at `ratio` contrast against `argb`,
    treating `argb` as the darker color. Pass ratio < 1 to get a darker result."""
    L = relative_luminance(argb)
    return ratio * (L + 0.05) - 0.05


def find_tone(hue: int, chroma: int, target_luminance: float) -> int:
    """Scan tone 0-100 and return the value whose rendered luminance is
    closest to target_luminance."""
    best_err = float("inf")
    best_tone = 0
    for t in range(101):
        err = abs(relative_luminance(hct_to_argb(hue, chroma, t)) - target_luminance)
        if err < best_err:
            best_err = err
            best_tone = t
    return best_tone


# -------- Dominant wavelength ----------

# CIE 1931 2° CMF (380-700 nm, 5 nm steps): (λ, x̄, ȳ, z̄)
_CMF: tuple[tuple[int, float, float, float], ...] = (
    (380, 0.001368, 0.000039, 0.006450),
    (385, 0.002236, 0.000064, 0.010550),
    (390, 0.004243, 0.000120, 0.020050),
    (395, 0.007650, 0.000217, 0.036210),
    (400, 0.014310, 0.000396, 0.067850),
    (405, 0.023190, 0.000640, 0.110200),
    (410, 0.043510, 0.001210, 0.207400),
    (415, 0.077630, 0.002180, 0.371300),
    (420, 0.134380, 0.004000, 0.645600),
    (425, 0.214770, 0.007300, 1.039050),
    (430, 0.283900, 0.011600, 1.385600),
    (435, 0.328500, 0.016840, 1.622960),
    (440, 0.348280, 0.023000, 1.747060),
    (445, 0.348060, 0.029800, 1.782600),
    (450, 0.336200, 0.038000, 1.772110),
    (455, 0.318700, 0.048000, 1.744100),
    (460, 0.290800, 0.060000, 1.669200),
    (465, 0.251100, 0.073900, 1.528100),
    (470, 0.195360, 0.090980, 1.287640),
    (475, 0.142100, 0.112600, 1.041900),
    (480, 0.095640, 0.139020, 0.812950),
    (485, 0.057950, 0.169300, 0.616200),
    (490, 0.032010, 0.208020, 0.465180),
    (495, 0.014700, 0.258600, 0.353300),
    (500, 0.004900, 0.323000, 0.272000),
    (505, 0.002400, 0.407300, 0.212300),
    (510, 0.009300, 0.503000, 0.158200),
    (515, 0.029100, 0.608200, 0.111700),
    (520, 0.063270, 0.710000, 0.078250),
    (525, 0.109600, 0.793200, 0.057250),
    (530, 0.165500, 0.862000, 0.042160),
    (535, 0.225750, 0.914850, 0.029840),
    (540, 0.290400, 0.954000, 0.020300),
    (545, 0.359700, 0.980300, 0.013400),
    (550, 0.433450, 0.994950, 0.008750),
    (555, 0.512050, 1.000000, 0.005750),
    (560, 0.594500, 0.995000, 0.003900),
    (565, 0.678400, 0.978600, 0.002750),
    (570, 0.762100, 0.952000, 0.002100),
    (575, 0.842500, 0.915400, 0.001800),
    (580, 0.916300, 0.870000, 0.001650),
    (585, 0.978600, 0.816300, 0.001400),
    (590, 1.026300, 0.757000, 0.001100),
    (595, 1.056700, 0.694900, 0.001000),
    (600, 1.062200, 0.631000, 0.000800),
    (605, 1.045600, 0.566800, 0.000600),
    (610, 1.002600, 0.503000, 0.000340),
    (615, 0.938400, 0.441200, 0.000240),
    (620, 0.854450, 0.381000, 0.000190),
    (625, 0.751400, 0.321000, 0.000100),
    (630, 0.642400, 0.265000, 0.000050),
    (635, 0.541900, 0.217000, 0.000030),
    (640, 0.447900, 0.175000, 0.000020),
    (645, 0.360800, 0.138200, 0.000010),
    (650, 0.283500, 0.107000, 0.000000),
    (655, 0.218700, 0.081600, 0.000000),
    (660, 0.164900, 0.061000, 0.000000),
    (665, 0.121200, 0.044580, 0.000000),
    (670, 0.087400, 0.032000, 0.000000),
    (675, 0.063600, 0.023200, 0.000000),
    (680, 0.046770, 0.017000, 0.000000),
    (685, 0.032900, 0.011920, 0.000000),
    (690, 0.022700, 0.008210, 0.000000),
    (695, 0.015840, 0.005723, 0.000000),
    (700, 0.011359, 0.004102, 0.000000),
)

# Spectral locus in CIE 1931 xy chromaticity: (λ, x, y)
_LOCUS: tuple[tuple[int, float, float], ...] = tuple(
    (lam, X / (X + Y + Z), Y / (X + Y + Z)) for lam, X, Y, Z in _CMF if X + Y + Z > 0
)

_D65 = (0.3127, 0.3290)


def _argb_to_xy(argb: int) -> tuple[float, float]:
    r, g, b = argb_to_rgb(argb)
    R = srgb_to_linear(r)
    G = srgb_to_linear(g)
    B = srgb_to_linear(b)
    X = 0.4124564 * R + 0.3575761 * G + 0.1804375 * B
    Y = 0.2126729 * R + 0.7151522 * G + 0.0721750 * B
    Z = 0.0193339 * R + 0.1191920 * G + 0.9503041 * B
    s = X + Y + Z
    return (X / s, Y / s)


def _ray_segment_intersect(
    ox: float,
    oy: float,
    dx: float,
    dy: float,
    ax: float,
    ay: float,
    bx: float,
    by: float,
) -> tuple[float, float] | None:
    """Return (t, s) where the ray O+t*D intersects segment A+s*(B-A), or None."""
    ex, ey = bx - ax, by - ay
    det = dx * (-ey) - dy * (-ex)
    if abs(det) < 1e-12:
        return None
    t = ((ax - ox) * (-ey) - (ay - oy) * (-ex)) / det
    s = (dx * (ay - oy) - dy * (ax - ox)) / det
    if 0.0 <= s <= 1.0:
        return t, s
    return None


def wavelength_to_hue(lam: int) -> float:
    """Return the HCT hue whose dominant wavelength is lam (nm).
    Scans HCT hues 0-359 and returns the one whose reference color lies closest
    to the ray from D65 through the spectral locus point at lam."""
    if not (380 <= lam <= 700):
        raise ValueError(f"wavelength {lam} out of range [380, 700]")

    x, y = 0.0, 0.0
    for i in range(len(_LOCUS) - 1):
        lam_a, xa, ya = _LOCUS[i]
        lam_b, xb, yb = _LOCUS[i + 1]
        if lam_a <= lam <= lam_b:
            t = (lam - lam_a) / (lam_b - lam_a) if lam_b != lam_a else 0.0
            x = xa + t * (xb - xa)
            y = ya + t * (yb - ya)
            break

    wx, wy = _D65
    dx, dy = x - wx, y - wy
    mag = math.sqrt(dx * dx + dy * dy)
    dx, dy = dx / mag, dy / mag

    # Scan HCT hues and find the one whose xy direction best aligns with the target.
    best_dot = -float("inf")
    best_hue = 0
    for h in range(360):
        cx, cy = _argb_to_xy(hct_to_argb(h, 50, 50))
        ex, ey = cx - wx, cy - wy
        emag = math.sqrt(ex * ex + ey * ey)
        if emag == 0:
            continue
        dot = (ex * dx + ey * dy) / emag
        if dot > best_dot:
            best_dot = dot
            best_hue = h

    return float(best_hue)


def hue_to_wavelengths(hue: int) -> list[tuple[int, float]]:
    """Map an HCT hue to wavelength(s) via dominant wavelength.
    Returns [(λ, 1.0)] for spectral hues, [(380, w), (700, 1-w)] for purples."""
    ref = hct_to_argb(hue, 50, 50)
    cx, cy = _argb_to_xy(ref)
    wx, wy = _D65
    dx, dy = cx - wx, cy - wy

    best: tuple[float, float, int] | None = None
    for i in range(len(_LOCUS) - 1):
        lam_a, ax, ay = _LOCUS[i]
        lam_b, bx, by = _LOCUS[i + 1]
        result = _ray_segment_intersect(wx, wy, dx, dy, ax, ay, bx, by)
        if result is None:
            continue
        t, s = result
        if t > 0 and (best is None or t < best[0]):
            best = (t, s, i)

    if best is not None:
        _, s, i = best
        lam_a, _, _ = _LOCUS[i]
        lam_b, _, _ = _LOCUS[i + 1]
        return [(round(lam_a + s * (lam_b - lam_a)), 1.0)]

    # Purple: ray hits the line of purples - interpolate between the spectral endpoints.
    _, p380x, p380y = _LOCUS[0]
    _, p700x, p700y = _LOCUS[-1]
    result = _ray_segment_intersect(wx, wy, dx, dy, p380x, p380y, p700x, p700y)
    if result is not None:
        _, s = result
        return [(380, 1.0 - s), (700, s)]

    raise ValueError(f"hue {hue} did not intersect spectral locus or line of purples")


def _resolve_chroma(hue: int, curve: Callable[[int], int]) -> int:
    return round(sum(w * curve(lam) for lam, w in hue_to_wavelengths(hue)))


# -------- Main --------


def _generate_palette(
    background_hex: str,
    background_base_decimal: int,
    foregrounds: list[tuple[int, int, float, int | None]],
    backgrounds: list[tuple[int, int, float]],
    accent_contrast_ratio: float,
    accents: list[tuple[int, int]],
    brown: tuple[int, int],
    bright_accent_contrast_ratio: float,
    bright_accents: list[tuple[int, int]],
    chroma_curve: Callable[[int], int],
    bright_chroma_curve: Callable[[int], int],
    brown_chroma_curve: Callable[[int], int],
) -> list[str]:
    palette: list[str] = [""] * 24
    palette[background_base_decimal] = background_hex
    background_argb = int(background_hex.lstrip("#"), 16)

    # 1. Foregrounds - derived from background
    for idx, hue, ratio, chroma in foregrounds:
        target_L = find_luminance(background_argb, ratio)
        chroma = _resolve_chroma(hue, chroma_curve) if chroma is None else chroma
        tone = find_tone(hue, chroma, target_L)
        palette[idx] = argb_to_hex(hct_to_argb(hue, chroma, tone))

    # 2. Backgrounds - derived from base05
    base05_argb = int(palette[5].lstrip("#"), 16)  # type: ignore[union-attr]
    for idx, hue, ratio in backgrounds:
        if idx == background_base_decimal:
            continue
        target_L = find_luminance(base05_argb, ratio)
        tone = find_tone(hue, 0, target_L)
        palette[idx] = argb_to_hex(hct_to_argb(hue, 0, tone))

    # 3. Accents
    accent_target_L = find_luminance(background_argb, accent_contrast_ratio)
    for idx, hue in accents:
        chroma = _resolve_chroma(hue, chroma_curve)
        tone = find_tone(hue, chroma, accent_target_L)
        palette[idx] = argb_to_hex(hct_to_argb(hue, chroma, tone))

    # 4. Brown
    idx, hue = brown
    chroma = _resolve_chroma(hue, brown_chroma_curve)
    tone = find_tone(hue, chroma, accent_target_L)
    palette[idx] = argb_to_hex(hct_to_argb(hue, chroma, tone))

    # 5. Bright accents
    bright_target_L = find_luminance(background_argb, bright_accent_contrast_ratio)
    for idx, hue in bright_accents:
        chroma = _resolve_chroma(hue, bright_chroma_curve)
        tone = find_tone(hue, chroma, bright_target_L)
        palette[idx] = argb_to_hex(hct_to_argb(hue, chroma, tone))

    return palette


def generate_dark() -> list[str]:
    chroma_curve = make_chroma(30, 50)
    bright_chroma_curve = make_chroma(40, 60)
    brown_chroma_curve = make_chroma(20, 40)

    # (palette index, hue, contrast ratio, chroma)
    foregrounds: list[tuple[int, int, float, int | None]] = [
        (3, 139, 4.5, None),  # Dim Foreground
        (4, 139, 5.0, None),  # Dark Foreground
        (5, 139, 5.5, None),  # Foreground
        (6, 139, 6.0, None),  # Light Foreground
        (7, 139, 6.5, None),  # Lightest Foreground
    ]
    backgrounds = [
        (0, 0, 1 / 5.5),  # Background (fixed)
        (1, 0, 1 / 5.0),  # Lighter Background
        (2, 0, 1 / 4.5),  # Selection Background
        (16, 0, 1 / 6.0),  # Darker Background
        (17, 0, 1 / 6.5),  # Darkest Background
    ]
    accents = [
        (8, 15),  # Red
        (9, 30),  # Orange
        (10, 99),  # Yellow
        (11, 172),  # Green
        (12, 201),  # Cyan
        (13, 302),  # Blue
        (14, 339),  # Magenta
    ]
    brown = (15, 35)
    bright_accents = [
        (18, 10),  # Bright Red
        (19, 94),  # Bright Yellow
        (20, 167),  # Bright Green
        (21, 196),  # Bright Cyan
        (22, 297),  # Bright Blue
        (23, 344),  # Bright Magenta
    ]

    return _generate_palette(
        "#1e1e1e",
        0,
        foregrounds,
        backgrounds,
        4.5,
        accents,
        brown,
        4.5,
        bright_accents,
        chroma_curve,
        bright_chroma_curve,
        brown_chroma_curve,
    )


def generate_light() -> list[str]:
    chroma_curve = make_chroma(60, 70)
    bright_chroma_curve = make_chroma(70, 80)
    brown_chroma_curve = make_chroma(50, 60)

    # (palette index, hue, contrast ratio, chroma)
    # For light mode, base11 is the fixed background foregrounds are generated against. base11 and base00 have a
    # contrast ratio difference of 1. Increase foreground contrast ratio input by 1 to achieve contrast ratio of 5.5
    # between base00 and base05.
    foregrounds: list[tuple[int, int, float, int | None]] = [
        (3, 0, 1 / 5.5, 0),  # Lightest Foreground
        (4, 0, 1 / 6.0, 0),  # Light Foreground
        (5, 0, 1 / 6.5, 0),  # Foreground
        (6, 0, 1 / 7.0, 0),  # Dark Foreground
        (7, 0, 1 / 7.5, 0),  # Dim Foreground
    ]
    backgrounds = [
        (0, 0, 5.5),  # Background
        (1, 0, 5.0),  # Darker Background
        (2, 0, 4.5),  # Darkest Background
        (16, 0, 6.0),  # Lighter Background
        (17, 0, 6.5),  # Selection Background
    ]
    accents = [
        (8, 15),  # Red
        (9, 30),  # Orange
        (10, 123),  # Yellow
        (11, 162),  # Green
        (12, 201),  # Cyan
        (13, 285),  # Blue
        (14, 345),  # Magenta
    ]
    brown = (15, 35)
    bright_accents = [
        (18, 10),  # Bright Red
        (19, 118),  # Bright Yellow
        (20, 157),  # Bright Green
        (21, 196),  # Bright Cyan
        (22, 280),  # Bright Blue
        (23, 349),  # Bright Magenta
    ]

    return _generate_palette(
        "#ffffff",
        17,
        foregrounds,
        backgrounds,
        1 / 5.5,
        accents,
        brown,
        1 / 5.5,
        bright_accents,
        chroma_curve,
        bright_chroma_curve,
        brown_chroma_curve,
    )


def write_palette_yml(
    palette: list[str],
    variant: str,
) -> None:
    theme_dir = Path("Themes/Petrichor")
    theme_dir.mkdir(parents=True, exist_ok=True)
    path = theme_dir / f"petrichor-{variant}.yml"
    lines = [
        'system: "base24"',
        f'name: "Petrichor {variant.capitalize()}"',
        'author: "Justin Park"',
        f'variant: "{variant}"',
        "palette:",
    ]
    for i, color in enumerate(palette):
        lines.append(f'  base{i:02X}: "{color}"')
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def main() -> None:
    write_palette_yml(generate_dark(), "dark")
    write_palette_yml(generate_light(), "light")


if __name__ == "__main__":
    main()

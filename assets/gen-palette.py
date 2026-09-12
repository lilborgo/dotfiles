#!/usr/bin/env python3
"""Derive palette.nix from the current wallpaper.

Pulls the wallpaper's own hues into the theme instead of picking colours by
hand. Surfaces come from its darkest tones; each accent is taken from the
real pixels nearest a target hue, then pushed to a lightness/saturation the
UI can actually use. Hues the wallpaper does not contain fall back to the
canonical Frutiger Aero value, tinted toward the image's overall cast.

    python3 assets/gen-palette.py [-i .config/hypr/bg.png] [-o palette.nix]
"""

import argparse
import colorsys
import numpy as np
from PIL import Image

# role -> (target hue in degrees, fallback hex, target saturation, target value)
# Targets are spread deliberately wide. A wallpaper dominated by one hue (a
# night sky, say) will otherwise drag several accents onto the same colour and
# the theme collapses back to monochrome.
ACCENTS = [
    ("coral",  358, "ff5f7a", 0.62, 1.00),
    ("sun",     45, "ffd166", 0.62, 1.00),
    ("grass",  100, "7ac943", 0.66, 0.79),
    ("mint",   163, "3ddc97", 0.72, 0.86),
    ("aqua",   190, "00d9d5", 1.00, 0.85),
    ("sky",    218, "00a8e8", 1.00, 0.91),
    ("violet", 280, "b47cff", 0.51, 1.00),
]

# how far an accent may drift from its target toward the wallpaper's own hue
MAX_DRIFT = 10.0
# and the minimum gap any two accents must keep from each other
MIN_GAP = 14.0

# surfaces: (role, target value/brightness, saturation ceiling)
SURFACES = [("abyss", 0.020), ("deep", 0.050), ("mid", 0.105)]


def hex_of(r, g, b):
    return "".join(f"{max(0, min(255, int(round(c * 255)))):02x}" for c in (r, g, b))


def hue_dist(a, b):
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-i", "--image", default=".config/hypr/bg.png")
    ap.add_argument("-o", "--out", default="frutiger.nix")
    args = ap.parse_args()

    im = Image.open(args.image).convert("RGB")
    im.thumbnail((480, 480))
    px = (np.asarray(im, dtype=np.float32) / 255.0).reshape(-1, 3)

    mx = px.max(axis=1)
    mn = px.min(axis=1)
    val = mx
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)

    # hue per pixel, in degrees
    hsv = np.array([colorsys.rgb_to_hsv(*p) for p in px[:: max(1, len(px) // 40000)]])
    sample_h = hsv[:, 0] * 360.0
    sample_s = hsv[:, 1]
    sample_v = hsv[:, 2]

    # --- surfaces: hue of the darkest region, held at very low saturation ---
    dark = px[val <= np.quantile(val, 0.25)]
    dh, ds, _ = colorsys.rgb_to_hsv(*dark.mean(axis=0))
    lines = []
    for role, target_v in SURFACES:
        # keep a whisper of the wallpaper's cast, never enough to read as a hue
        r, g, b = colorsys.hsv_to_rgb(dh, min(ds, 0.30), target_v)
        lines.append((role, hex_of(r, g, b)))

    # --- accents: nearest real pixels to each target hue -------------------
    accent_lines = []
    picked = []
    for role, hue, fallback, want_s, want_v in ACCENTS:
        m = (np.abs(((sample_h - hue + 180) % 360) - 180) <= 26) & (sample_s > 0.18) & (sample_v > 0.10)
        n = int(m.sum())
        if n >= 40:
            h = float(np.median(sample_h[m]))
            # pull the drift back so a dominant hue cannot swallow its neighbours
            delta = ((h - hue + 180) % 360) - 180
            h = (hue + max(-MAX_DRIFT, min(MAX_DRIFT, delta))) % 360
            src = f"wallpaper ({n} px, drift {delta:+.0f}deg -> {h:.0f}deg)"
        else:
            h = float(hue)
            src = "fallback (hue absent from wallpaper)"
        picked.append([role, h, want_s, want_v, src])

    # enforce separation: nudge any pair that ended up too close back apart
    for i in range(1, len(picked)):
        prev_h = picked[i - 1][1]
        if hue_dist(picked[i][1], prev_h) < MIN_GAP:
            target = float(ACCENTS[i][1])
            picked[i][1] = target
            picked[i][4] = (f"wallpaper, but pushed back to target {target:.0f}deg "
                            f"(was within {MIN_GAP:.0f}deg of the previous accent)")

    for role, h, want_s, want_v, src in picked:
        r, g, b = colorsys.hsv_to_rgb(h / 360.0, want_s, want_v)
        accent_lines.append((role, hex_of(r, g, b), src))

    # --- foreground: the brightest tones, lifted to near-white -------------
    bright = px[val >= np.quantile(val, 0.995)]
    bh, bs, _ = colorsys.rgb_to_hsv(*bright.mean(axis=0))
    foam = hex_of(*colorsys.hsv_to_rgb(bh, min(bs, 0.10), 0.90))
    gloss = hex_of(*colorsys.hsv_to_rgb(bh, min(bs, 0.06), 1.00))
    rim = hex_of(*colorsys.hsv_to_rgb(bh, min(bs, 0.28), 1.00))
    inactive = hex_of(*colorsys.hsv_to_rgb(dh, min(ds, 0.22), 0.42))

    # Rewrite only the delimited palette block inside frutiger.nix, so the
    # hand-written theme code in the same file is never touched.
    body = [f'\t\tabyss\t= "{lines[0][1]}";\t# surface',
            f'\t\tdeep\t= "{lines[1][1]}";\t# surface',
            f'\t\tmid\t= "{lines[2][1]}";\t# surface',
            "",
            "\t\t# --- accents ---"]
    for role, h, src in accent_lines:
        body.append(f'\t\t{role}\t= "{h}";\t# {src}')
    body += ["",
             f'\t\tfoam\t= "{foam}";\t# foreground',
             f'\t\tgloss\t= "{gloss}";\t# bright text / highlight',
             f'\t\trim\t= "{rim}";\t# gloss rim highlight',
             f'\t\tinactive\t= "{inactive}";\t# dimmed foreground']

    BEGIN = "\t#\t=== BEGIN GENERATED PALETTE - assets/gen-palette.py ==="
    END = "\t#\t=== END GENERATED PALETTE ==="
    src_text = open(args.out).read()
    if BEGIN not in src_text or END not in src_text:
        raise SystemExit(f"{args.out}: generated-palette markers not found")
    head = src_text[: src_text.index(BEGIN) + len(BEGIN)]
    tail = src_text[src_text.index(END):]
    block = "\n\tpalette\t= {\n" + "\n".join(body) + "\n\t};\n"
    open(args.out, "w").write(head + block + tail)

    print(f"updated the palette block in {args.out} from {args.image}")
    for role, h in lines:
        print(f"  {role:9} #{h}  (surface)")
    for role, h, src in accent_lines:
        print(f"  {role:9} #{h}  {src}")
    for role, h in [("foam", foam), ("gloss", gloss), ("rim", rim), ("inactive", inactive)]:
        print(f"  {role:9} #{h}")


if __name__ == "__main__":
    main()

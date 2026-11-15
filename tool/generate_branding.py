"""Regenerates every branding PNG/SVG from one geometry definition.
Requires Playwright (python). Run from the project root:  python3 tool/generate_branding.py
The same geometry is drawn in Flutter by lib/shared/widgets/aether_logo.dart.
"""
from playwright.sync_api import sync_playwright
import pathlib

OUT = pathlib.Path('assets/branding')
BG = '#0D131E'
G1, G2 = '#BAC3FF', '#6F82FF'   # glyph gradient (palette primaryLight -> deeper primary)

# Glyph in a 100x100 box: an "A" whose crossbar is a rising price line that
# breaks out through the right leg and ends in a dot. A cut-out gap separates
# the line from the legs. Flutter twin: lib/shared/widgets/aether_logo.dart
LEGS = "26,76 50,24 74,76"
LINE = "46,67 51,62 56,65 68,50 81,34"
DOT = (81, 34, 5.5)

def glyph(stroke=8, line=5, gap=14):
    return f'''
<defs>
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="{G1}"/><stop offset="1" stop-color="{G2}"/></linearGradient>
<mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="100" height="100">
<rect width="100" height="100" fill="#fff"/>
<polyline points="{LINE}" fill="none" stroke="#000" stroke-width="{gap}" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="{DOT[0]}" cy="{DOT[1]}" r="{DOT[2]+4}" fill="#000"/></mask></defs>
<polyline points="{LEGS}" fill="none" stroke="url(#g)" stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round" mask="url(#m)"/>
<polyline points="{LINE}" fill="none" stroke="{G1}" stroke-width="{line}" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="{DOT[0]}" cy="{DOT[1]}" r="{DOT[2]}" fill="{G1}"/>'''

def svg(size, body, bg=True, radius=0):
    rect = f'<rect width="100" height="100" rx="{radius}" fill="{BG}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="{size}" height="{size}">{rect}{body}</svg>'

def scaled(scale):
    t = (100 - 100 * scale) / 2
    return f'<g transform="translate({t},{t}) scale({scale})">{glyph()}</g>'

files = {
    'logo_mark.svg': svg(512, glyph(), bg=False),
    'logo_rounded.svg': svg(512, glyph(), bg=True, radius=22),
    'icon.svg': svg(1024, scaled(0.92), bg=True, radius=0),
}
pngs = {
    'icon.png': (1024, svg(1024, scaled(0.92), bg=True)),                 # iOS / legacy, opaque
    'icon_foreground.png': (1024, svg(1024, scaled(0.62), bg=False)),     # Android adaptive (safe zone)
    'splash.png': (768, svg(768, scaled(0.9), bg=False)),                 # native splash, transparent
    'logo_mark.png': (512, svg(512, glyph(), bg=False)),
    'logo_rounded.png': (512, svg(512, glyph(), bg=True, radius=22)),
}
for n, s in files.items():
    (OUT / n).write_text(s)
with sync_playwright() as p:
    b = p.chromium.launch()
    for n, (size, s) in pngs.items():
        pg = b.new_page(viewport={'width': size, 'height': size})
        pg.set_content(f'<body style="margin:0;background:transparent">{s}</body>')
        pg.screenshot(path=str(OUT / n), omit_background=True)
    b.close()
print('done')

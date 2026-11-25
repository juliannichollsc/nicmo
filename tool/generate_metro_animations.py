#!/usr/bin/env python3
"""Generates the Metro de Medellín themed animations used by the app.

Outputs (relative to the project root):
  assets/animations/metro_train.json   Lottie - train arriving on the viaduct
  assets/animations/metrocable.json    Lottie - Metrocable gondola over the comunas
  assets/animations/arrival.json       Lottie - destination pin + check
  assets/animations/metro_train.gif    GIF    - loading loop (route search)
  assets/animations/metrocable.gif     GIF    - idle loop
  assets/resources/imgs/background_metro.png        dark green app background
  assets/resources/imgs/background_metro_light.png  light app background
  assets/resources/imgs/nicmo_login.png             login hero illustration

Run:  python3 tool/generate_metro_animations.py   (requires Pillow)
"""
import json
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ANIM_DIR = os.path.join(ROOT, 'assets', 'animations')
IMG_DIR = os.path.join(ROOT, 'assets', 'resources', 'imgs')

# Nicmo palette, one hue (~105°); kept in sync with lib/theme/metro_theme.dart.
GREEN = '#65BC4B'
GREEN_BRIGHT = '#8BD373'
GREEN_DEEP = '#2D5D1D'
NIGHT = '#10150F'
SURFACE = '#1A2118'
SURFACE_HIGH = '#262F23'
MINT = '#C8E3BF'
WHITE = '#F4FBF7'
WINDOW = '#1E2A1B'
LINE_A = '#215CA0'
LINE_B = '#EB8530'

W, H, FPS, FRAMES = 400, 240, 30, 90


def rgb(hex_color):
    h = hex_color.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lcolor(hex_color):
    return [round(c / 255, 4) for c in rgb(hex_color)] + [1]


# --------------------------------------------------------------------------
# Minimal Lottie (bodymovin 5.7) builder
# --------------------------------------------------------------------------

def static(value):
    return {'a': 0, 'k': value}


def anim(keys, ease_in=(0.33, 1), ease_out=(0.67, 0)):
    """keys: list of (frame, value). Values are lists (multi-dim) or numbers."""
    k = []
    for idx, (t, v) in enumerate(keys):
        value = v if isinstance(v, list) else [v]
        frame = {'t': t, 's': value}
        if idx < len(keys) - 1:
            frame['i'] = {'x': [ease_in[0]], 'y': [ease_in[1]]}
            frame['o'] = {'x': [ease_out[0]], 'y': [ease_out[1]]}
        k.append(frame)
    return {'a': 1, 'k': k}


def transform(p=(0, 0), a=(0, 0), s=(100, 100), r=0, o=100):
    def wrap(v, dims=None):
        if isinstance(v, dict):
            return v
        return static(list(v) if dims else v)
    return {
        'ty': 'tr',
        'p': wrap(p, True), 'a': wrap(a, True), 's': wrap(s, True),
        'r': wrap(r), 'o': wrap(o),
        'sk': static(0), 'sa': static(0),
    }


def rect(x, y, w, h, r=0):
    """Rectangle with top-left corner at (x, y)."""
    return {'ty': 'rc', 'd': 1, 's': static([w, h]),
            'p': static([x + w / 2, y + h / 2]), 'r': static(r)}


def ellipse(cx, cy, w, h=None):
    return {'ty': 'el', 'd': 1, 's': static([w, h or w]), 'p': static([cx, cy])}


def path(points, closed=True):
    n = len(points)
    return {'ty': 'sh', 'ks': static({
        'i': [[0, 0]] * n, 'o': [[0, 0]] * n,
        'v': [list(p) for p in points], 'c': closed})}


def fill(color, opacity=100):
    o = opacity if isinstance(opacity, dict) else static(opacity)
    return {'ty': 'fl', 'c': static(lcolor(color)), 'o': o, 'r': 1}


def gfill(stops, start, end, opacity=100):
    """Linear gradient fill. stops: [(offset 0..1, '#hex', alpha 0..1)]."""
    colors, alphas = [], []
    for offset, color, alpha in stops:
        colors += [offset] + lcolor(color)[:3]
        alphas += [offset, alpha]
    return {'ty': 'gf', 'o': static(opacity), 'r': 1, 't': 1,
            's': static(list(start)), 'e': static(list(end)),
            'g': {'p': len(stops), 'k': static(colors + alphas)}}


def stroke(color, width, opacity=100):
    o = opacity if isinstance(opacity, dict) else static(opacity)
    return {'ty': 'st', 'c': static(lcolor(color)), 'o': o,
            'w': static(width), 'lc': 2, 'lj': 2, 'ml': 4}


def trim(end):
    return {'ty': 'tm', 's': static(0), 'e': end, 'o': static(0), 'm': 1}


def group(name, items, tr=None):
    return {'ty': 'gr', 'nm': name, 'it': items + [tr or transform()]}


def layer(index, name, shapes, ks=None, ip=0, op=FRAMES):
    # Like layers, Lottie paints the first shape group on top; callers list
    # groups back-to-front, so reverse them here.
    shapes = list(reversed(shapes))
    return {
        'ddd': 0, 'ind': index, 'ty': 4, 'nm': name, 'sr': 1,
        'ks': ks or {
            'o': static(100), 'r': static(0), 'p': static([0, 0, 0]),
            'a': static([0, 0, 0]), 's': static([100, 100, 100]),
        },
        'ao': 0, 'shapes': shapes, 'ip': ip, 'op': op, 'st': 0, 'bm': 0,
    }


def layer_ks(p=None, r=None, o=None, s=None, a=(0, 0, 0)):
    return {
        'o': o or static(100),
        'r': r or static(0),
        'p': p or static([0, 0, 0]),
        'a': static(list(a)),
        's': s or static([100, 100, 100]),
    }


def composition(name, layers, w=W, h=H, frames=FRAMES):
    # Lottie draws the first layer on top; callers pass back-to-front.
    ordered = list(reversed(layers))
    for i, lay in enumerate(ordered, start=1):
        lay['ind'] = i
    return {'v': '5.7.4', 'fr': FPS, 'ip': 0, 'op': frames, 'w': w, 'h': h,
            'nm': name, 'ddd': 0, 'assets': [], 'layers': ordered}


def mountains(base_y, color, opacity, seed, width=W):
    rnd = random.Random(seed)
    pts = [(-40, base_y)]
    x = -40
    while x < width * 2 + 40:
        x += rnd.randint(50, 90)
        pts.append((x, base_y - rnd.randint(25, 70)))
    pts += [(width * 2 + 40, base_y), (width * 2 + 40, H + 10), (-40, H + 10)]
    return [group('mountains', [path(pts), fill(color, opacity)])]


def train_car(x, nose=None):
    """One car at local x. nose='front'|'back' rounds that end more."""
    items = [
        group('roof', [rect(x + 8, -5, 96, 7, 3),
                       gfill([(0, '#E4EEE8', 1), (1, '#A9BEB3', 1)], (0, -5), (0, 2))]),
        group('body', [rect(x, 0, 112, 42, 10),
                       gfill([(0, '#FFFFFF', 1), (0.55, '#EEF4F0', 1), (1, '#B9CBC1', 1)],
                             (0, 0), (0, 42))]),
        group('skirt', [rect(x + 3, 36, 106, 6, 3), fill('#7E978A')]),
        group('stripe', [rect(x, 26, 112, 7, 0),
                         gfill([(0, GREEN_BRIGHT, 1), (1, GREEN_DEEP, 1)], (0, 26), (0, 33))]),
    ]
    for wx in range(x + 12, x + 100, 22):
        items.append(group('window', [rect(wx, 7, 16, 15, 3),
                                      gfill([(0, '#1D5A40', 1), (1, WINDOW, 1)], (0, 7), (0, 22))]))
        items.append(group('glare', [path([(wx + 3, 20), (wx + 9, 8), (wx + 12, 8), (wx + 6, 20)]),
                                     fill('#FFFFFF', 22)]))
    for cx in (x + 22, x + 90):
        items.append(group('bogie', [rect(cx - 12, 40, 24, 5, 2), fill('#24362D')]))
        items.append(group('wheel', [ellipse(cx - 6, 46, 9), fill('#1C2B24')]))
        items.append(group('wheel', [ellipse(cx + 6, 46, 9), fill('#1C2B24')]))
    if nose == 'front':
        items.append(group('nose', [rect(x + 98, 2, 18, 38, 12),
                                    gfill([(0, '#FFFFFF', 1), (1, '#B9CBC1', 1)], (0, 2), (0, 40))]))
        items.append(group('windshield', [rect(x + 104, 7, 10, 15, 4), fill(WINDOW)]))
        items.append(group('light', [ellipse(x + 112, 31, 6), fill('#FFF6C2')]))
        # Headlight beam fading forward.
        items.append(group('beam', [path([(x + 114, 29), (x + 190, 14), (x + 190, 50), (x + 114, 33)]),
                                    gfill([(0, '#FFF6C2', 0.55), (1, '#FFF6C2', 0)],
                                          (x + 114, 31), (x + 190, 31))]))
    return items


def lottie_metro_train():
    track_y = 160
    layers = []
    # Far mountains drift slowly (parallax), near ones a bit faster.
    layers.append(layer(0, 'mountains_far', mountains(150, GREEN_DEEP, 55, 3),
                        layer_ks(p=anim([(0, [0, 0, 0]), (FRAMES, [-120, 0, 0])],
                                        (1, 1), (0, 0)))))
    layers.append(layer(0, 'mountains_near', mountains(168, SURFACE_HIGH, 90, 7),
                        layer_ks(p=anim([(0, [0, 0, 0]), (FRAMES, [-200, 0, 0])],
                                        (1, 1), (0, 0)))))
    # Medellín skyline with windows that light up and fade.
    rnd = random.Random(21)
    skyline, lights = [], []
    x = -10
    while x < W + 10:
        w, h = rnd.randint(18, 34), rnd.randint(30, 85)
        skyline.append(group('building', [rect(x, 178 - h, w, h + 10, 1),
                                          gfill([(0, '#123B28', 1), (1, '#0A2619', 1)],
                                                (0, 178 - h), (0, 178))]))
        for wy in range(178 - h + 6, 172, 9):
            for wx in range(x + 4, x + w - 5, 7):
                if rnd.random() < 0.35:
                    start = rnd.randint(0, 60)
                    lights.append(group('light', [rect(wx, wy, 3, 4, 0.5),
                                                  fill('#F4E9A6', anim([(start, 20), (start + 15, 85),
                                                                        (start + 30, 35)]))]))
        x += w + rnd.randint(2, 8)
    layers.append(layer(0, 'skyline', skyline + lights))
    # Viaduct with pillars.
    viaduct = [group('deck', [rect(-10, track_y + 22, W + 20, 9, 2), fill('#2F5A45')]),
               group('rail', [rect(-10, track_y + 18, W + 20, 4, 1), fill('#9BB7A8')])]
    for px in range(10, W, 70):
        viaduct.append(group('pillar', [rect(px, track_y + 31, 14, 60, 2), fill('#24493A')]))
    layers.append(layer(0, 'viaduct', viaduct))
    # Station platform in the middle.
    layers.append(layer(0, 'station', [
        group('canopy', [rect(130, track_y - 48, 150, 8, 4), fill(GREEN)]),
        group('posts', [rect(140, track_y - 40, 5, 58, 1), rect(265, track_y - 40, 5, 58, 1),
                        fill('#2F5A45')]),
        group('sign', [ellipse(205, track_y - 62, 22), fill(GREEN_BRIGHT)]),
        group('sign_m', [path([(197, track_y - 56), (197, track_y - 68), (205, track_y - 60),
                               (213, track_y - 68), (213, track_y - 56)], closed=False),
                         stroke(NIGHT, 3)]),
    ]))
    # The train: arrives, dwells at the platform, departs.
    cars = train_car(0) + train_car(116) + train_car(232, nose='front')
    shadow = [group('shadow', [ellipse(170, 50, 340, 8), fill('#000000', 30)])]
    speed_lines = []
    for i, y in enumerate((6, 18, 30)):
        speed_lines.append(group(f'speed{i}', [
            rect(-60 - i * 12, y, 40 - i * 6, 3, 1.5),
            fill(MINT, anim([(0, 0), (12, 80), (30, 0), (55, 0), (68, 80), (90, 0)]))]))
    move = anim([(0, [-380, track_y - 30, 0]), (34, [60, track_y - 30, 0]),
                 (56, [60, track_y - 30, 0]), (FRAMES, [480, track_y - 30, 0])],
                ease_in=(0.25, 1), ease_out=(0.75, 0))
    layers.append(layer(0, 'train', shadow + speed_lines + cars, layer_ks(p=move)))
    return composition('Metro de Medellín - tren', layers)


def lottie_metrocable():
    layers = []
    layers.append(layer(0, 'mountains', mountains(200, GREEN_DEEP, 70, 11)))
    # Comuna houses on the hillside.
    rnd = random.Random(5)
    houses = []
    palette = ['#E07A3F', '#F2C14E', '#E8E2D0', '#C4553A', MINT]
    for _ in range(26):
        x = rnd.randint(0, W)
        y = 175 + rnd.randint(-10, 50) + int(abs(x - 200) / 8)
        houses.append(group('house', [rect(x, y, rnd.randint(12, 20), rnd.randint(9, 14), 1),
                                      fill(rnd.choice(palette), 85)]))
    layers.append(layer(0, 'comunas', houses))
    # Towers and cable.
    a, b = (-20, 70), (W + 20, 130)
    def cable_y(x):
        return a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
    towers = []
    for tx in (90, 300):
        ty = cable_y(tx)
        towers.append(group('tower', [path([(tx - 12, H), (tx - 3, ty), (tx + 3, ty), (tx + 12, H)]),
                                      fill('#9BB7A8')]))
    layers.append(layer(0, 'towers', towers))
    layers.append(layer(0, 'cable', [group('cable', [path([a, b], closed=False), stroke('#D5E5DC', 2)])]))
    # Gondola anchored at its grip on the cable; position follows the cable.
    def gondola_shapes(scale=1.0):
        k = scale
        return [
            group('arm', [rect(-1.5 * k, 0, 3 * k, 22 * k, 1), fill('#D5E5DC')]),
            group('grip', [rect(-6 * k, -3 * k, 12 * k, 6 * k, 2), fill('#D5E5DC')]),
            group('roof', [rect(-20 * k, 20 * k, 40 * k, 6 * k, 3), fill(GREEN_DEEP)]),
            group('cabin', [rect(-22 * k, 25 * k, 44 * k, 34 * k, 8 * k),
                            gfill([(0, GREEN_BRIGHT, 1), (1, GREEN_DEEP, 1)],
                                  (0, 25 * k), (0, 59 * k))]),
            group('window', [rect(-16 * k, 30 * k, 32 * k, 13 * k, 3 * k),
                             gfill([(0, '#1D5A40', 1), (1, WINDOW, 1)], (0, 30 * k), (0, 43 * k))]),
            group('glare', [path([(-12 * k, 41 * k), (-6 * k, 31 * k), (-2 * k, 31 * k),
                                  (-8 * k, 41 * k)]), fill('#FFFFFF', 25)]),
            group('stripe', [rect(-22 * k, 48 * k, 44 * k, 3 * k, 0), fill(WHITE)]),
        ]
    # Return cable (further away, smaller) with a gondola going the other way.
    a2, b2 = (-20, 52), (W + 20, 110)
    def cable2_y(x):
        return a2[1] + (b2[1] - a2[1]) * (x - a2[0]) / (b2[0] - a2[0])
    layers.append(layer(0, 'cable_back', [group('cable', [path([a2, b2], closed=False),
                                                         stroke('#D5E5DC', 1.2, 70)])]))
    back = anim([(0, [W + 30, cable2_y(W + 30), 0]), (FRAMES, [-30, cable2_y(-30), 0])],
                (1, 1), (0, 0))
    layers.append(layer(0, 'gondola_back', gondola_shapes(0.7),
                        layer_ks(p=back, o=static(75),
                                 r=anim([(0, 3), (30, -3), (60, 3), (FRAMES, -3)]))))
    gondola = gondola_shapes()
    x0, x1 = -40, W + 40
    move = anim([(0, [x0, cable_y(x0), 0]), (FRAMES, [x1, cable_y(x1), 0])], (1, 1), (0, 0))
    swing = anim([(0, -4), (22, 4), (45, -4), (67, 4), (FRAMES, -4)])
    layers.append(layer(0, 'gondola', gondola, layer_ks(p=move, r=swing)))
    return composition('Metrocable', layers)


def lottie_arrival():
    cx, cy = 200, 130
    layers = []
    for i in range(3):
        start = i * 12
        ring = [group('ring', [ellipse(0, 0, 60), stroke(GREEN_BRIGHT, 3)])]
        layers.append(layer(0, f'ring{i}', ring, layer_ks(
            p=static([cx, cy + 40, 0]),
            s=anim([(start, [20, 8, 100]), (start + 50, [260, 100, 100])], (0.2, 1), (0.4, 0)),
            o=anim([(start, 90), (start + 50, 0)]))))
    pin = [
        group('pin', [path([(-26, -40), (26, -40), (0, 0)]), ellipse(0, -46, 52), fill(GREEN)]),
        group('dot', [ellipse(0, -46, 20), fill(WHITE)]),
    ]
    drop = anim([(0, [cx, -40, 0]), (18, [cx, cy + 40, 0]), (24, [cx, cy + 26, 0]),
                 (30, [cx, cy + 40, 0])], (0.3, 1), (0.6, 0))
    layers.append(layer(0, 'pin', pin, layer_ks(p=drop)))
    check = [group('check', [path([(-18, 0), (-5, 13), (20, -14)], closed=False),
                             stroke(WHITE, 7),
                             trim(anim([(32, 0), (52, 100)]))])]
    layers.append(layer(0, 'badge_check', [group('badge', [ellipse(0, 0, 54), fill(GREEN_DEEP)])] + check,
                        layer_ks(p=static([cx + 70, cy - 60, 0]),
                                 s=anim([(26, [0, 0, 100]), (40, [115, 115, 100]), (48, [100, 100, 100])]))))
    for i in range(10):
        angle = 2 * math.pi * i / 10
        dist = 70 + (i % 3) * 14
        end = [cx + 70 + math.cos(angle) * dist, cy - 60 + math.sin(angle) * dist, 0]
        color = [GREEN_BRIGHT, MINT, '#F4E9A6'][i % 3]
        layers.append(layer(0, f'spark{i}', [group('spark', [ellipse(0, 0, 7 - (i % 3) * 1.5),
                                                              fill(color)])],
                            layer_ks(p=anim([(34, [cx + 70, cy - 60, 0]), (58, end)], (0.1, 1), (0.3, 0)),
                                     o=anim([(34, 0), (38, 100), (66, 0)]),
                                     s=anim([(34, [40, 40, 100]), (58, [100, 100, 100])]))))
    return composition('Llegada', layers)


# --------------------------------------------------------------------------
# GIF renderer (Pillow), same scenes drawn frame by frame
# --------------------------------------------------------------------------

SS = 2  # supersampling factor for anti-aliasing


def ease_in_out(t):
    return t * t * (3 - 2 * t)


def gif_frame_base():
    img = Image.new('RGB', (W * SS, H * SS), rgb(NIGHT))
    d = ImageDraw.Draw(img)
    for y in range(H * SS):  # vertical gradient night -> surface
        k = y / (H * SS)
        c = tuple(int(rgb(NIGHT)[i] * (1 - k) + rgb(SURFACE)[i] * k) for i in range(3))
        d.line([(0, y), (W * SS, y)], fill=c)
    return img, d


def s(v):
    return [int(c * SS) for c in v]


def draw_mountains(d, base_y, color, seed, offset):
    rnd = random.Random(seed)
    pts = [(-40, base_y)]
    x = -40
    while x < W * 2 + 40:
        x += rnd.randint(50, 90)
        pts.append((x, base_y - rnd.randint(25, 70)))
    pts += [(W * 2 + 40, base_y), (W * 2 + 40, H + 10), (-40, H + 10)]
    d.polygon([(int((px + offset) * SS), int(py * SS)) for px, py in pts], fill=rgb(color))


def draw_car(d, x, y, front=False):
    d.rounded_rectangle(s([x + 8, y - 5, x + 104, y + 2]), 3 * SS, fill=rgb('#C9D8D0'))
    d.rounded_rectangle(s([x, y, x + 112, y + 42]), 9 * SS, fill=rgb(WHITE))
    d.rectangle(s([x, y + 27, x + 112, y + 33]), fill=rgb(GREEN))
    for wx in range(int(x) + 12, int(x) + 100, 22):
        d.rounded_rectangle(s([wx, y + 8, wx + 16, y + 22]), 3 * SS, fill=rgb(WINDOW))
    for cx in (x + 22, x + 90):
        d.ellipse(s([cx - 5.5, y + 40.5, cx + 5.5, y + 51.5]), fill=rgb('#1C2B24'))
    if front:
        d.ellipse(s([x + 105, y + 31, x + 111, y + 37]), fill=rgb('#FFF6C2'))


def gif_metro_train():
    frames = []
    track_y = 160
    for f in range(FRAMES):
        img, d = gif_frame_base()
        draw_mountains(d, 150, GREEN_DEEP, 3, -120 * f / FRAMES)
        draw_mountains(d, 168, SURFACE_HIGH, 7, -200 * f / FRAMES)
        d.rounded_rectangle(s([-10, track_y + 22, W + 10, track_y + 31]), 2 * SS, fill=rgb('#2F5A45'))
        d.rectangle(s([-10, track_y + 18, W + 10, track_y + 22]), fill=rgb('#9BB7A8'))
        for px in range(10, W, 70):
            d.rounded_rectangle(s([px, track_y + 31, px + 14, H + 10]), 2 * SS, fill=rgb('#24493A'))
        d.rounded_rectangle(s([130, track_y - 48, 280, track_y - 40]), 4 * SS, fill=rgb(GREEN))
        d.rectangle(s([140, track_y - 40, 145, track_y + 18]), fill=rgb('#2F5A45'))
        d.rectangle(s([265, track_y - 40, 270, track_y + 18]), fill=rgb('#2F5A45'))
        d.ellipse(s([194, track_y - 73, 216, track_y - 51]), fill=rgb(GREEN_BRIGHT))
        d.line(s([197, track_y - 56, 197, track_y - 68, 205, track_y - 60, 213, track_y - 68,
                  213, track_y - 56]), fill=rgb(NIGHT), width=3 * SS, joint='curve')
        # Same timing as the Lottie version.
        if f <= 34:
            x = -380 + 440 * (1 - (1 - f / 34) ** 3)
        elif f <= 56:
            x = 60
        else:
            x = 60 + 420 * ((f - 56) / 34) ** 3
        y = track_y - 30
        moving = f < 30 or f > 60
        if moving:
            for i, ly in enumerate((6, 18, 30)):
                lx = x - 60 - i * 12
                d.rounded_rectangle(s([lx, y + ly, lx + 40 - i * 6, y + ly + 3]), 1 * SS, fill=rgb(MINT))
        for i in range(3):
            draw_car(d, x + i * 116, y, front=(i == 2))
        frames.append(img.resize((W, H), Image.LANCZOS))
    return frames


def gif_metrocable():
    frames = []
    a, b = (-20, 70), (W + 20, 130)
    def cable_y(x):
        return a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
    rnd = random.Random(5)
    palette = ['#E07A3F', '#F2C14E', '#E8E2D0', '#C4553A', MINT]
    houses = []
    for _ in range(26):
        x = rnd.randint(0, W)
        y = 175 + rnd.randint(-10, 50) + int(abs(x - 200) / 8)
        houses.append((x, y, rnd.randint(12, 20), rnd.randint(9, 14), rnd.choice(palette)))
    for f in range(FRAMES):
        img, d = gif_frame_base()
        draw_mountains(d, 200, GREEN_DEEP, 11, 0)
        for x, y, w, h, c in houses:
            d.rectangle(s([x, y, x + w, y + h]), fill=rgb(c))
        for tx in (90, 300):
            ty = cable_y(tx)
            d.polygon([tuple(s([tx - 12, H])), tuple(s([tx - 3, ty])), tuple(s([tx + 3, ty])),
                       tuple(s([tx + 12, H]))], fill=rgb('#9BB7A8'))
        d.line(s([a[0], a[1], b[0], b[1]]), fill=rgb('#D5E5DC'), width=2 * SS)
        gx = -40 + (W + 80) * f / FRAMES
        gy = cable_y(gx)
        angle = math.radians(-4 * math.cos(2 * math.pi * f / 45))
        def rot(px, py):
            return (gx + px * math.cos(angle) - py * math.sin(angle),
                    gy + px * math.sin(angle) + py * math.cos(angle))
        def poly(x0, y0, x1, y1, color):
            pts = [rot(x0, y0), rot(x1, y0), rot(x1, y1), rot(x0, y1)]
            d.polygon([tuple(s(p)) for p in pts], fill=rgb(color))
        poly(-1.5, 0, 1.5, 22, '#D5E5DC')
        poly(-6, -3, 6, 3, '#D5E5DC')
        poly(-20, 20, 20, 26, GREEN_DEEP)
        poly(-22, 25, 22, 59, GREEN)
        poly(-16, 30, 16, 43, WINDOW)
        poly(-22, 48, 22, 51, WHITE)
        frames.append(img.resize((W, H), Image.LANCZOS))
    return frames


def save_gif(frames, name):
    # Every 2nd frame at 15 fps keeps motion smooth with half the size.
    path_out = os.path.join(ANIM_DIR, name)
    frames = frames[::2]
    paletted = [f.convert('P', palette=Image.ADAPTIVE, colors=64, dither=Image.NONE)
                for f in frames]
    paletted[0].save(path_out, save_all=True, append_images=paletted[1:],
                     duration=int(2000 / FPS), loop=0, optimize=True, disposal=2)
    return path_out


# --------------------------------------------------------------------------
# Background
# --------------------------------------------------------------------------

def background(name, top, bottom, line_alpha, dot, dot_alpha, hills=None):
    """Stylised Metro network over a vertical gradient (app background)."""
    bw, bh = 1080, 1920
    img = Image.new('RGB', (bw, bh), rgb(bottom))
    d = ImageDraw.Draw(img)
    for y in range(bh):
        k = y / bh
        t, b = rgb(top), rgb(bottom)
        d.line([(0, y), (bw, y)], fill=tuple(int(t[i] * (1 - k) + b[i] * k) for i in range(3)))
    overlay = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
    o = ImageDraw.Draw(overlay)
    if hills:
        # Valle de Aburrá silhouettes at the bottom.
        for color, alpha, base, seed in hills:
            rnd = random.Random(seed)
            pts, x = [(-40, bh)], -40
            while x < bw + 80:
                pts.append((x, base - rnd.randint(40, 170)))
                x += rnd.randint(110, 200)
            pts += [(bw + 80, bh)]
            o.polygon(pts, fill=rgb(color) + (alpha,))
    # Stylised network: line A (N-S), B (to the west), cable lines to the hills.
    lines = [
        (LINE_A, [(560, -40), (600, 400), (560, 800), (520, 1200), (470, 1600), (420, 1980)]),
        (LINE_B, [(560, 800), (380, 860), (200, 900), (-40, 940)]),
        (GREEN, [(600, 400), (820, 300), (1120, 220)]),
        (GREEN, [(200, 900), (60, 760), (-40, 650)]),
        ('#7AB929', [(520, 1200), (760, 1160), (1120, 1120)]),
    ]
    for color, pts in lines:
        o.line(pts, fill=rgb(color) + (line_alpha,), width=14, joint='curve')
        for p in pts[1:-1]:
            o.ellipse([p[0] - 18, p[1] - 18, p[0] + 18, p[1] + 18], fill=rgb(color) + (line_alpha,))
            o.ellipse([p[0] - 11, p[1] - 11, p[0] + 11, p[1] + 11], fill=rgb(dot) + (dot_alpha,))
    img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    img.save(os.path.join(IMG_DIR, name), optimize=True)


def login_illustration():
    """Round hero image for the login: the valley, the metro, a Metrocable
    and a dashed route from A to B (clipped to a circle in the app)."""
    size = 900
    k = 2  # supersampling
    img = Image.new('RGBA', (size * k, size * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    S = lambda v: int(v * k)
    # Sky gradient.
    for y in range(size * k):
        t = y / (size * k)
        c = tuple(int(rgb('#8ED46F')[i] * (1 - t) + rgb('#2F7D32')[i] * t) for i in range(3))
        d.line([(0, y), (size * k, y)], fill=c + (255,))
    # Sun.
    d.ellipse([S(130), S(120), S(260), S(250)], fill=rgb('#F4E9A6') + (255,))
    # Far and near hills.
    def hills(base, color, seed, amp):
        rnd = random.Random(seed)
        pts, x = [(0, size * k)], -40
        while x < size + 120:
            pts.append((S(x), S(base - rnd.randint(amp // 3, amp))))
            x += rnd.randint(90, 160)
        pts.append((size * k, size * k))
        d.polygon(pts, fill=rgb(color) + (255,))
    hills(470, '#4E9A3A', 3, 170)
    # Metrocable over the far hill.
    d.line([S(430), S(250), S(900), S(130)], fill=rgb('#E8F5EE') + (255,), width=S(4))
    gx, gy = 540, 220
    d.line([S(gx), S(gy - 8), S(gx), S(gy + 22)], fill=rgb('#E8F5EE') + (255,), width=S(5))
    d.rounded_rectangle([S(gx - 34), S(gy + 20), S(gx + 34), S(gy + 72)], S(12), fill=rgb(GREEN_DEEP) + (255,))
    d.rounded_rectangle([S(gx - 24), S(gy + 30), S(gx + 24), S(gy + 50)], S(5), fill=rgb(WINDOW) + (255,))
    hills(560, '#3E8A2E', 7, 140)
    # Skyline.
    rnd = random.Random(11)
    x = 40
    while x < 860:
        w, h = rnd.randint(36, 70), rnd.randint(80, 210)
        d.rectangle([S(x), S(640 - h), S(x + w), S(660)], fill=rgb('#1F5C2C') + (255,))
        for wy in range(640 - h + 14, 640, 22):
            for wx in range(x + 8, x + w - 10, 16):
                if rnd.random() < 0.45:
                    d.rectangle([S(wx), S(wy), S(wx + 7), S(wy + 9)], fill=rgb('#F4E9A6') + (230,))
        x += w + rnd.randint(4, 14)
    # Viaduct with the metro (line A blue rail).
    d.rectangle([0, S(650), size * k, S(668)], fill=rgb('#2F5A45') + (255,))
    d.rectangle([0, S(640), size * k, S(650)], fill=rgb(LINE_A) + (255,))
    for px in range(30, 900, 120):
        d.rectangle([S(px), S(668), S(px + 26), size * k], fill=rgb('#24493A') + (255,))
    tx, ty = 170, 572
    for i in range(3):
        cx = tx + i * 190
        d.rounded_rectangle([S(cx), S(ty), S(cx + 182), S(ty + 66)], S(16), fill=rgb(WHITE) + (255,))
        d.rectangle([S(cx), S(ty + 42), S(cx + 182), S(ty + 52)], fill=rgb(GREEN) + (255,))
        for wx in range(cx + 18, cx + 165, 36):
            d.rounded_rectangle([S(wx), S(ty + 12), S(wx + 26), S(ty + 34)], S(5), fill=rgb(WINDOW) + (255,))
    # Ground.
    d.rectangle([0, S(700), size * k, size * k], fill=rgb('#1B4D26') + (255,))
    # Dashed route A -> B.
    route = [(170, 800), (330, 760), (420, 700), (520, 560), (650, 470), (750, 430)]
    for (x1, y1), (x2, y2) in zip(route, route[1:]):
        steps = int(math.hypot(x2 - x1, y2 - y1) // 26)
        for j in range(0, steps, 2):
            a, b = j / steps, min((j + 1) / steps, 1)
            d.line([S(x1 + (x2 - x1) * a), S(y1 + (y2 - y1) * a),
                    S(x1 + (x2 - x1) * b), S(y1 + (y2 - y1) * b)],
                   fill=(255, 255, 255, 255), width=S(9))
    def pin(x, y, letter, color):
        d.ellipse([S(x - 44), S(y - 120), S(x + 44), S(y - 32)], fill=rgb(color) + (255,))
        d.polygon([(S(x - 38), S(y - 66)), (S(x + 38), S(y - 66)), (S(x), S(y))], fill=rgb(color) + (255,))
        d.ellipse([S(x - 26), S(y - 102), S(x + 26), S(y - 50)], fill=(255, 255, 255, 255))
        # Letter drawn with strokes (no font dependency).
        if letter == 'A':
            d.line([S(x - 12), S(y - 58), S(x), S(y - 94), S(x + 12), S(y - 58)], fill=rgb(color) + (255,), width=S(7))
            d.line([S(x - 7), S(y - 72), S(x + 7), S(y - 72)], fill=rgb(color) + (255,), width=S(6))
        else:
            d.line([S(x - 9), S(y - 94), S(x - 9), S(y - 58)], fill=rgb(color) + (255,), width=S(7))
            d.arc([S(x - 14), S(y - 96), S(x + 12), S(y - 76)], 270, 90, fill=rgb(color) + (255,), width=S(6))
            d.arc([S(x - 14), S(y - 78), S(x + 14), S(y - 56)], 270, 90, fill=rgb(color) + (255,), width=S(6))
    pin(170, 800, 'A', GREEN_DEEP)
    pin(750, 430, 'B', '#E0533D')
    img = img.resize((size, size), Image.LANCZOS)
    # Circular mask with a soft white ring.
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    ring = ImageDraw.Draw(out)
    ring.ellipse([4, 4, size - 5, size - 5], outline=(255, 255, 255, 230), width=10)
    out.save(os.path.join(IMG_DIR, 'nicmo_login.png'), optimize=True)


def main():
    os.makedirs(ANIM_DIR, exist_ok=True)
    for name, comp in (('metro_train.json', lottie_metro_train()),
                       ('metrocable.json', lottie_metrocable()),
                       ('arrival.json', lottie_arrival())):
        with open(os.path.join(ANIM_DIR, name), 'w') as fh:
            json.dump(comp, fh, separators=(',', ':'))
    save_gif(gif_metro_train(), 'metro_train.gif')
    save_gif(gif_metrocable(), 'metrocable.gif')
    login_illustration()
    background('background_metro.png', '#1A2418', NIGHT, 46, WHITE, 40)
    background('background_metro_light.png', '#FFFFFF', '#E6F4DE', 70, '#FFFFFF', 255,
               hills=[('#B9DFA6', 90, 1800, 4), ('#8FCB74', 70, 1900, 9)])
    for name in sorted(os.listdir(ANIM_DIR)):
        print(name, os.path.getsize(os.path.join(ANIM_DIR, name)), 'bytes')


if __name__ == '__main__':
    main()

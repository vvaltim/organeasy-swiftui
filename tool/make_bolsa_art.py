#!/usr/bin/env python3
import json
import os
import sys

from PIL import Image, ImageDraw

OUTLINE = (43, 43, 58, 255)
FLOOR = (201, 200, 232, 255)
FLOOR_LINE = (179, 177, 217, 255)
DESK = [(238, 240, 245, 255), (199, 203, 214, 255), (166, 171, 185, 255)]
MONITOR = [(85, 91, 104, 255), (58, 63, 75, 255), (40, 44, 54, 255)]
UP = [(61, 220, 132, 255), (31, 160, 92, 255)]
DOWN = [(255, 90, 95, 255), (190, 50, 58, 255)]
SKIN = [(241, 194, 125, 255), (214, 158, 98, 255)]
HAIR = (74, 44, 29, 255)
SHIRT = [(59, 111, 216, 255), (41, 82, 168, 255)]
PANTS = (46, 53, 80, 255)
SHOES = (29, 29, 38, 255)
POT = [(194, 106, 61, 255), (150, 76, 40, 255)]
LEAF = [(63, 163, 77, 255), (46, 125, 58, 255), (98, 196, 104, 255)]
SHELF = [(74, 120, 209, 255), (52, 90, 168, 255), (40, 70, 135, 255)]
BOOKS = [(230, 92, 92, 255), (247, 197, 72, 255), (91, 200, 172, 255), (240, 240, 240, 255)]


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def iso(ox, oy, x, y, z):
    return (ox + 2 * (x - y), oy + (x + y) - z)


def box(img, ox, oy, x, y, z, w, d, h, colors):
    draw = ImageDraw.Draw(img)
    p = lambda a, b, c: iso(ox, oy, x + a, y + b, z + c)
    draw.polygon([p(0, d, 0), p(w, d, 0), p(w, d, h), p(0, d, h)], fill=colors[1])
    draw.polygon([p(w, 0, 0), p(w, d, 0), p(w, d, h), p(w, 0, h)], fill=colors[2])
    draw.polygon([p(0, 0, h), p(w, 0, h), p(w, d, h), p(0, d, h)], fill=colors[0])


def outline(img):
    src = img.load()
    out = img.copy()
    dst = out.load()
    w, h = img.size
    for x in range(w):
        for y in range(h):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3]:
                    dst[x, y] = OUTLINE
                    break
    return out


def draw_floor():
    img = canvas(32, 17)
    draw = ImageDraw.Draw(img)
    draw.polygon([(16, 0), (31, 8), (16, 16), (1, 8)], fill=FLOOR)
    draw.line([(16, 0), (31, 8)], fill=FLOOR_LINE)
    draw.line([(16, 0), (1, 8)], fill=FLOOR_LINE)
    return img


def draw_desk(up):
    img = canvas(48, 44)
    ox, oy = 22, 12
    box(img, ox, oy, 0, 0, 0, 14, 8, 9, DESK)
    box(img, ox, oy, 4, 2, 9, 2, 5, 1, MONITOR)
    box(img, ox, oy, 5, 1, 10, 1, 7, 8, MONITOR)
    screen = UP if up else DOWN
    draw = ImageDraw.Draw(img)
    p = lambda a, b, c: iso(ox, oy, a, b, c)
    draw.polygon([p(5, 1.6, 11), p(5, 7.4, 11), p(5, 7.4, 17), p(5, 1.6, 17)], fill=screen[0])
    for i, row in enumerate((12.5, 14, 15.5)):
        length = (4.2, 3.0, 4.6)[i]
        a, b = p(5, 2.3, row), p(5, 2.3 + length, row)
        draw.line([a, b], fill=screen[1])
    box(img, ox, oy, 9, 2, 9, 3, 5, 1, [(220, 222, 230, 255), (180, 184, 196, 255), (150, 154, 168, 255)])
    return outline(img)


def draw_worker(mood, frame):
    img = canvas(16, 28)
    d = ImageDraw.Draw(img)
    bob = 1 if (mood == "up" and frame == 1) else 0
    y = 2 - bob
    d.rectangle([5, 22 - bob, 7, 25 - bob], fill=PANTS)
    d.rectangle([9, 22 - bob, 11, 25 - bob], fill=PANTS)
    d.rectangle([4, 26 - bob, 7, 27 - bob], fill=SHOES)
    d.rectangle([9, 26 - bob, 12, 27 - bob], fill=SHOES)
    d.rectangle([4, y + 10, 12, y + 20], fill=SHIRT[0])
    d.rectangle([4, y + 18, 12, y + 20], fill=SHIRT[1])
    d.rectangle([5, y + 2, 11, y + 8], fill=SKIN[0])
    d.rectangle([5, y + 7, 11, y + 8], fill=SKIN[1])
    d.rectangle([5, y + 1, 11, y + 3], fill=HAIR)
    d.point([(5, y + 4), (11, y + 4)], fill=HAIR)
    d.rectangle([7, y + 9, 9, y + 9], fill=SKIN[1])
    if mood == "up":
        d.point([(7, y + 5), (9, y + 5)], fill=OUTLINE)
        d.line([(7, y + 7), (9, y + 7)], fill=OUTLINE)
        arm = 0 if frame == 0 else -2
        d.line([(3, y + 11), (1, y + 4 + arm)], fill=SHIRT[0], width=2)
        d.line([(13, y + 11), (14, y + 4 + arm)], fill=SHIRT[0], width=2)
        d.rectangle([0, y + 2 + arm, 2, y + 4 + arm], fill=SKIN[0])
        d.rectangle([13, y + 2 + arm, 15, y + 4 + arm], fill=SKIN[0])
    else:
        d.point([(7, y + 6), (9, y + 6)], fill=OUTLINE)
        d.point([(7, y + 8), (9, y + 8)], fill=OUTLINE)
        d.point([(8, y + 7)], fill=OUTLINE)
        d.rectangle([3, y + 11, 3, y + 18], fill=SHIRT[1])
        if frame == 0:
            d.rectangle([13, y + 11, 13, y + 18], fill=SHIRT[1])
            d.rectangle([3, y + 19, 4, y + 20], fill=SKIN[0])
            d.rectangle([12, y + 19, 13, y + 20], fill=SKIN[0])
        else:
            d.line([(13, y + 11), (12, y + 3)], fill=SHIRT[1], width=2)
            d.rectangle([10, y + 1, 12, y + 3], fill=SKIN[0])
            d.rectangle([3, y + 19, 4, y + 20], fill=SKIN[0])
    return outline(img)


def draw_plant():
    img = canvas(20, 26)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 17, 13, 24], fill=POT[0])
    d.rectangle([10, 17, 13, 24], fill=POT[1])
    d.rectangle([5, 16, 14, 17], fill=POT[1])
    d.ellipse([3, 2, 16, 15], fill=LEAF[1])
    d.ellipse([5, 3, 14, 12], fill=LEAF[0])
    d.ellipse([6, 3, 10, 7], fill=LEAF[2])
    d.ellipse([1, 7, 7, 13], fill=LEAF[0])
    d.ellipse([12, 6, 18, 12], fill=LEAF[1])
    return outline(img)


def draw_shelf():
    img = canvas(28, 44)
    ox, oy = 6, 8
    box(img, ox, oy, 0, 0, 0, 7, 3, 26, SHELF)
    draw = ImageDraw.Draw(img)
    p = lambda a, c: iso(ox, oy, a, 3, c)
    for level in (3, 10, 17):
        draw.polygon([p(0.5, level - 0.6), p(6.5, level - 0.6), p(6.5, level + 5.6), p(0.5, level + 5.6)], fill=SHELF[2])
        for i in range(5):
            color = BOOKS[(i + level) % len(BOOKS)]
            a0 = 0.8 + i * 1.15
            top = level + 4.6 - (i % 2)
            draw.polygon([p(a0, level), p(a0 + 0.9, level), p(a0 + 0.9, top), p(a0, top)], fill=color)
    return outline(img)


SPRITES = {
    "bolsaFloor": draw_floor,
    "bolsaDeskUp": lambda: draw_desk(True),
    "bolsaDeskDown": lambda: draw_desk(False),
    "bolsaWorkerUp": lambda: draw_worker("up", 0),
    "bolsaWorkerUp2": lambda: draw_worker("up", 1),
    "bolsaWorkerDown": lambda: draw_worker("down", 0),
    "bolsaWorkerDown2": lambda: draw_worker("down", 1),
    "bolsaPlant": draw_plant,
    "bolsaShelf": draw_shelf,
}


def write_imageset(folder, name, image):
    path = os.path.join(folder, f"{name}.imageset")
    os.makedirs(path, exist_ok=True)
    image.save(os.path.join(path, f"{name}.png"))
    contents = {
        "images": [{"filename": f"{name}.png", "idiom": "universal", "scale": "1x"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": False, "template-rendering-intent": "original"},
    }
    with open(os.path.join(path, "Contents.json"), "w") as output:
        json.dump(contents, output, indent=2)


def preview(images, path):
    scene = canvas(232, 150)
    floor = images["bolsaFloor"]
    for gx in range(7):
        for gy in range(7):
            sx, sy = 100 + (gx - gy) * 16, 8 + (gx + gy) * 8
            scene.alpha_composite(floor, (sx, sy))
    spots = [(0, 0, True), (3, 0, False), (0, 3, False), (3, 3, True)]
    for gx, gy, up in spots:
        sx, sy = 100 + (gx - gy) * 16, 8 + (gx + gy) * 8
        scene.alpha_composite(images["bolsaDeskUp" if up else "bolsaDeskDown"], (sx - 6, sy - 6))
        scene.alpha_composite(images["bolsaWorkerUp" if up else "bolsaWorkerDown"], (sx + 26, sy + 12))
    scene.alpha_composite(images["bolsaPlant"], (8, 60))
    scene.alpha_composite(images["bolsaShelf"], (196, 36))
    row = canvas(232, 40)
    x = 2
    for name in ("bolsaWorkerUp", "bolsaWorkerUp2", "bolsaWorkerDown", "bolsaWorkerDown2", "bolsaDeskUp", "bolsaDeskDown", "bolsaPlant", "bolsaShelf"):
        sprite = images[name]
        row.alpha_composite(sprite, (x, 40 - sprite.height))
        x += sprite.width + 4
    sheet = Image.new("RGBA", (232, 194), (245, 245, 250, 255))
    sheet.alpha_composite(scene, (0, 0))
    sheet.alpha_composite(row, (0, 152))
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(path)


def main():
    out_dir = sys.argv[1]
    preview_path = sys.argv[sys.argv.index("--preview") + 1] if "--preview" in sys.argv else None
    images = {name: build() for name, build in SPRITES.items()}
    for name, image in images.items():
        write_imageset(out_dir, name, image)
    folder = os.path.join(out_dir, "Contents.json")
    with open(folder, "w") as output:
        json.dump({"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": False}}, output, indent=2)
    if preview_path:
        preview(images, preview_path)


if __name__ == "__main__":
    main()

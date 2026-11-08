"""Gera as imagens da App Store a partir das capturas do simulador.

Uso: uv run --with pillow python -I tool/make_store_images.py <pasta_capturas> publicacao
As capturas se chamam <aparelho>_<idioma>_<cena>.png (aparelho = iphone | ipad13).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = '/System/Library/Fonts/HelveticaNeue.ttc'
TOP = (6, 120, 100)
BOTTOM = (5, 60, 120)
GOLD = (255, 201, 71)

SCENES = ['6_invest', '8_perfil', '7_detalhe', '2_ia', '3_analise', '5_chat', '4_grafico', '1_home']
CAPTIONS = {
    'pt-BR': {'6_invest': ('Ranking de investimentos', 'pelo seu perfil'), '7_detalhe': ('Fundamentos de verdade', 'dos balanços oficiais'), '8_perfil': ('Seu perfil de risco', 'em 1 minuto'), '2_ia': ('Sua IA pessoal', 'para as contas do mês'), '3_analise': ('Analise seu mês', 'em um toque'), '5_chat': ('Pergunte sobre', 'suas contas'), '4_grafico': ('Veja seus gastos', 'mês a mês'), '1_home': ('Tudo o que vence', 'em um só lugar')},
    'en': {'6_invest': ('Investment ranking', 'for your profile'), '7_detalhe': ('Real fundamentals', 'from official filings'), '8_perfil': ('Your risk profile', 'in 1 minute'), '2_ia': ('Your personal AI', 'for monthly bills'), '3_analise': ('Analyze your month', 'in one tap'), '5_chat': ('Ask about', 'your bills'), '4_grafico': ('See your spending', 'month by month'), '1_home': ('Every due date', 'in one place')},
    'es': {'6_invest': ('Ranking de inversiones', 'según tu perfil'), '7_detalhe': ('Fundamentales reales', 'de balances oficiales'), '8_perfil': ('Tu perfil de riesgo', 'en 1 minuto'), '2_ia': ('Tu IA personal', 'para las cuentas del mes'), '3_analise': ('Analiza tu mes', 'con un toque'), '5_chat': ('Pregunta sobre', 'tus cuentas'), '4_grafico': ('Mira tus gastos', 'mes a mes'), '1_home': ('Todo lo que vence', 'en un solo lugar')},
    'fr': {'6_invest': ('Classement d’investissements', 'selon votre profil'), '7_detalhe': ('De vrais fondamentaux', 'issus des bilans officiels'), '8_perfil': ('Votre profil de risque', 'en 1 minute'), '2_ia': ('Votre IA personnelle', 'pour les factures'), '3_analise': ('Analysez votre mois', 'en un geste'), '5_chat': ('Posez vos questions', 'sur vos factures'), '4_grafico': ('Suivez vos dépenses', 'mois par mois'), '1_home': ('Toutes vos échéances', 'au même endroit')},
    'it': {'6_invest': ('Classifica investimenti', 'in base al tuo profilo'), '7_detalhe': ('Fondamentali veri', 'dai bilanci ufficiali'), '8_perfil': ('Il tuo profilo di rischio', 'in 1 minuto'), '2_ia': ('La tua IA personale', 'per le bollette'), '3_analise': ('Analizza il mese', 'con un tocco'), '5_chat': ('Chiedi delle', 'tue bollette'), '4_grafico': ('Guarda le spese', 'mese per mese'), '1_home': ('Tutte le scadenze', 'in un unico posto')},
}
PHONE = [('iphone_6.3', (1206, 2622)), ('iphone_6.1', (1179, 2556))]
TABLET = [('ipad_11_a', (1398, 2034)), ('ipad_11_b', (2007, 2853)), ('ipad_13', (2064, 2752)), ('ipad_12.9', (2048, 2732))]


def gradient(size):
    w, h = size
    column = Image.new('RGB', (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        column.putpixel((0, y), tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    return column.resize(size)


def rounded(img, radius):
    mask = Image.new('L', (img.width * 2, img.height * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, mask.width, mask.height], radius * 2, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask.resize(img.size, Image.LANCZOS))
    return out


def font(size, index):
    return ImageFont.truetype(FONT, size, index=index)


def centered(draw, y, text, face, width, fill):
    box = draw.textbbox((0, 0), text, font=face)
    draw.text(((width - (box[2] - box[0])) / 2, y), text, font=face, fill=fill)


def fit(draw, text, width, size, index):
    while draw.textlength(text, font=font(size, index)) > width and size > 20:
        size -= 2
    return font(size, index)


def marketing(raw, caption, size):
    w, h = size
    canvas = gradient(size).convert('RGBA')
    draw = ImageDraw.Draw(canvas)
    top = int(h * 0.055)
    usable = int(w * 0.9)
    first = fit(draw, caption[0], usable, int(w * 0.082), 1)
    second = fit(draw, caption[1], usable, int(w * 0.066), 0)
    centered(draw, top, caption[0], first, w, (255, 255, 255))
    line = top + int(first.size * 1.25)
    centered(draw, line, caption[1], second, w, GOLD)

    y = line + int(second.size * 1.75)
    shot_h = int(h * 1.02) - y
    shot_w = int(shot_h * raw.width / raw.height)
    if shot_w > w * 0.86:
        shot_w = int(w * 0.86)
        shot_h = int(shot_w * raw.height / raw.width)
    shot = rounded(raw.resize((shot_w, shot_h), Image.LANCZOS), int(shot_w * 0.055))
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 110), ((w - shot_w) // 2, y + 12), shot)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(int(w * 0.018))))
    canvas.alpha_composite(shot, ((w - shot_w) // 2, y))
    return canvas.convert('RGB')


def banner(raws, size, title, subtitle):
    w, h = size
    canvas = gradient(size).convert('RGBA')
    draw = ImageDraw.Draw(canvas)
    margin = int(w * 0.06)
    text_w = int(w * 0.42)
    head = fit(draw, title, text_w, int(h * 0.1), 1)
    sub = fit(draw, subtitle, text_w, int(h * 0.056), 0)
    draw.text((margin, int(h * 0.36)), title, font=head, fill=(255, 255, 255))
    draw.text((margin, int(h * 0.36) + int(head.size * 1.35)), subtitle, font=sub, fill=GOLD)
    shot_h = int(h * 1.08)
    x = int(w * 0.52)
    for i, raw in enumerate(raws):
        shot_w = int(shot_h * raw.width / raw.height)
        shot = rounded(raw.resize((shot_w, shot_h), Image.LANCZOS), int(shot_w * 0.055))
        canvas.alpha_composite(shot, (x + i * int(shot_w * 1.07), int(h * 0.1)))
    return canvas.convert('RGB')


def main(raw_dir, out_dir):
    for lang, captions in CAPTIONS.items():
        targets = [('iphone', PHONE if lang == 'pt-BR' else PHONE[:1])]
        if lang in ('pt-BR', 'en'):
            targets.append(('ipad13', TABLET if lang == 'pt-BR' else TABLET[2:3]))
        for device, sizes in targets:
            for folder, size in sizes:
                out = os.path.join(out_dir, 'imagens', lang, folder)
                os.makedirs(out, exist_ok=True)
                for n, scene in enumerate(SCENES, 1):
                    raw = Image.open(os.path.join(raw_dir, f'{device}_{lang}_{scene}.png')).convert('RGB')
                    marketing(raw, captions[scene], size).save(os.path.join(out, f'{n}_{scene}.png'))

    raws = [Image.open(os.path.join(raw_dir, f'iphone_pt-BR_{s}.png')).convert('RGB') for s in ('2_ia', '5_chat')]
    out = os.path.join(out_dir, 'imagens', 'banners')
    os.makedirs(out, exist_ok=True)
    for size in ((5244, 2950), (3840, 1646)):
        banner(raws, size, 'Sua IA pessoal', 'para as contas do mês').save(os.path.join(out, f'banner_{size[0]}x{size[1]}.png'))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])

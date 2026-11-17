# Makes, for each case, the page Chrome measures: Splitting.js's markup for each [data-splitting] element (as
# ../css_letters/split.py builds it), Splitting's stylesheet and the case's CSS as engine/community/css loads them, the
# rule that stills every animation and transform (the check gives the engine the same rule), and measure.js.
import html, re, sys, os
OFF = '*,*::before,*::after{animation:none!important;transition:none!important;transform:none!important;translate:none!important;rotate:none!important;scale:none!important}'
def split(text):
    words = text.split(); out, chars = [], 0
    for w, word in enumerate(words):
        if w: out.append('<span class="whitespace"> </span>')
        inner = ''.join(f'<span class="char" data-char="{html.escape(c)}" style="--char-index: {chars + j};">{html.escape(c)}</span>' for j, c in enumerate(word))
        chars += len(word)
        out.append(f'<span class="word" data-word="{html.escape(word)}" style="--word-index: {w};">{inner}</span>')
    return ''.join(out), len(words), chars
def one(m):
    tag, attrs, text = m.group(1), m.group(2), m.group(3)
    body, nw, nc = split(text)
    cls = re.search(r'class="([^"]*)"', attrs); attrs = re.sub(r'\s*class="[^"]*"', '', attrs)
    classes = ((cls.group(1) + ' ') if cls else '') + 'words chars splitting'
    return f'<{tag}{attrs} data-text="{html.escape(text)}" class="{classes}" style="--word-total: {nw}; --char-total: {nc};">{body}</{tag}>'
cases, pages, splitting = sys.argv[1], sys.argv[2], open(sys.argv[3]).read()
measure = open(os.path.join(os.path.dirname(__file__), 'measure.js')).read()
for f in sorted(os.listdir(cases)):
    if not f.endswith('.css'): continue
    name = f[:-4]; css = open(f'{cases}/{f}').read()
    h = open(f'{cases}/{name}.html').read() if os.path.exists(f'{cases}/{name}.html') else '<div data-splitting>Motolii</div>'
    body = re.sub(r'<(\w+)([^>]*\bdata-splitting\b[^>]*)>([^<]*)</\1>', one, h)
    open(f'{pages}/{name}.html', 'w').write(f'<!doctype html><html><head><meta charset="utf-8"><style>{splitting}</style><style>{css}</style><style>{OFF}</style></head><body>{body}<script>{measure}</script></body></html>')

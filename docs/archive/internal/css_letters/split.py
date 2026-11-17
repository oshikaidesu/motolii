# Builds the markup Splitting.js 1.x makes for [data-splitting] (read from its sources: core/splitting.js, utils/split-text.js,
# utils/css-vars.js, utils/dom.js, plugins/words.js, plugins/chars.js; MIT, github.com/shshaw/Splitting), so a page's CSS meets
# the letters it was written for. Only the default "chars" split (words, then chars); no other plugins.
import html, json, re, sys
from html.parser import HTMLParser

def split(text):
    words = text.split()
    out, chars = [], 0
    if text[:1] == ' ': out.append(' ')
    for w, word in enumerate(words):
        if w: out.append('<span class="whitespace"> </span>')
        inner = ''.join(f'<span class="char" data-char="{html.escape(c)}" style="--char-index: {chars + j};">{html.escape(c)}</span>' for j, c in enumerate(word))
        chars += len(word)
        out.append(f'<span class="word" data-word="{html.escape(word)}" style="--word-index: {w};">{inner}</span>')
    if text[-1:] == ' ' and words: out.append(' ')
    return ''.join(out), len(words), chars

def page(src_html, css):
    def one(m):
        tag, attrs, text = m.group(1), m.group(2), m.group(3)
        body, nw, nc = split(text)
        cls = re.search(r'class="([^"]*)"', attrs)
        attrs = re.sub(r'\s*class="[^"]*"', '', attrs)
        classes = ((cls.group(1) + ' ') if cls else '') + 'words chars splitting'
        return f'<{tag}{attrs} class="{classes}" style="--word-total: {nw}; --char-total: {nc};">{body}</{tag}>'
    body = re.sub(r'<(\w+)([^>]*\bdata-splitting\b[^>]*)>([^<]*)</\1>', one, src_html)
    css = re.sub(r'@import[^;]*;', '', css)  # (fonts from the net: neither side fetches them)
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{css}</style></head><body>{body}</body></html>'

pens = json.load(open(sys.argv[1]))
for key in sorted({k.rsplit('.', 1)[0] for k in pens}):
    name = key
    open(f'{sys.argv[2]}/{name}.html', 'w').write(page(pens[key + '.html'], pens[key + '.css']))
    print(name)

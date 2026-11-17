#!/bin/zsh
# Measures every page in Chrome (headless, 1280 x 720) and writes chrome/<name>.json.
cd ${0:a:h}
python3 gen.py cases pages ../../../engine/third_party/splitting/splitting.css
for p in pages/*.html; do
  n=${p:t:r}
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars --window-size=1280,720 --virtual-time-budget=1500 --dump-dom "file://$PWD/$p" 2>/dev/null \
    | python3 -c "import sys,re,html; m=re.search(r'<pre id=\"out\">(.*?)</pre>', sys.stdin.read(), re.S); open('chrome/$n.json','w').write(html.unescape(m.group(1)) if m else '[]')"
  echo "$n $(python3 -c "import json; d=json.load(open('chrome/$n.json')); print(len(d), 'element(s),', sum(len(r['chars']) for r in d), 'letters, view', d[0]['view'] if d else None)")"
done

#!/bin/zsh
# Writes chrome_analyser.json: what headless Chrome's AnalyserNode reads (chrome_analyser.html).
# The offline rendering runs on its own thread, so a dump can come before it ends: tried until it has.
here=${0:a:h}
for try in {1..8}; do
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --virtual-time-budget=60000 \
    --autoplay-policy=no-user-gesture-required --dump-dom "file://$here/chrome_analyser.html" 2>/dev/null |
    python3 -c "
import sys,re,json
m=re.search(r'<pre id=\"out\">(\{.*?)</pre>',sys.stdin.read(),re.S)
if not m: sys.exit(1)
json.dump(json.loads(m.group(1)),open('$here/chrome_analyser.json','w'))" && exit 0
done
exit 1

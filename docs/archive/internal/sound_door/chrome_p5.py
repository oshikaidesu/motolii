#!/usr/bin/env python3
"""Writes chrome_p5.json: what a p5.sound sketch draws in headless Chrome, frame by frame, measured.

    python3 chrome_p5.py [sketch.js]        (p5_fft_example.js when left out)

The page is the sketch as it is, with p5.js and p5.sound from engine/third_party/js/p5. Two things are done to it so
that Chrome's answer is the same every time:
  - p5.sound makes its AudioContext when it loads; the page hands it an OfflineAudioContext (two channels, the length
    of tones.wav, 48,000 Hz), so the sound is worked out sample by sample and not played to a loudspeaker.
  - The sketch does not draw by itself (noLoop). The canvas is clicked once before the sound starts, as the visitor
    would ("tap to play"), then the rendering is stopped every 1/60 s and draw() is run once (redraw).
The canvas is made 1080 pixels wide (pixelDensity), the width the film has, and each frame is measured as
measure_p5_against_chrome.py measures Motolii's stills: per pixel column, how high magenta is painted (the bars), and
the mean height of the dark line in the middle band (the wave). Any sound file the sketch asks for is tones.wav.
"""
import http.server, json, os, subprocess, sys, threading

here = os.path.dirname(os.path.abspath(__file__))
p5 = os.path.join(here, "..", "..", "..", "engine", "third_party", "js", "p5")
sketch = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "p5_fft_example.js")
page = """<!doctype html><meta charset="utf-8"><title>p5.sound sketch, measured</title>
<script>
const offline = new OfflineAudioContext(2, 48000 * 10, 48000);
window.AudioContext = function () { return offline; };
</script>
<script src="/p5.min.js"></script><script src="/p5.sound.min.js"></script><script src="/sketch.js"></script>
<script>
const asked = window.setup;
window.setup = function () {
  pixelDensity(10.8);
  asked();
  noLoop();
  setTimeout(run, 0);
};
function measured() {
  const c = document.querySelector('canvas'), w = c.width, h = c.height, d = drawingContext.getImageData(0, 0, w, h).data;
  // Per column: how high magenta is painted (the pixels that are at least a quarter of the way from the grey to
  // magenta: Chrome paints the seam between two bars one pixel wide lighter than the bars, so how much is painted
  // says less than how high), and where the dark line of the wave lies in the middle band (the mean height, each
  // pixel weighed by how dark it is).
  const bars = new Array(w).fill(0), sum = new Array(w).fill(0), n = new Array(w).fill(0);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const i = 4 * (y * w + x), r = d[i], g = d[i + 1], b = d[i + 2];
    if ((r - g) / 255 > 0.25) bars[x]++;
    const dark = Math.max(0, (220 - Math.max(r, g, b)) / 200);
    if (y > 0.3 * h && y < 0.7 * h) sum[x] += dark * y, n[x] += dark;
  }
  return [w, h, bars, sum.map((s, x) => n[x] > 0.5 ? Math.round(100 * s / n[x]) / 100 : -1)];
}
async function run() {
  let said;
  try {
    document.querySelector('canvas').dispatchEvent(new MouseEvent('click', { bubbles: true }));
    const rows = {};
    for (let k = 1; k < 600; k++) offline.suspend(k / 60).then(() => { redraw(); rows[k] = measured(); offline.resume(); });
    await offline.startRendering();
    said = { rows };
  } catch (e) { said = { error: String(e) }; }
  fetch('/result', { method: 'POST', body: JSON.stringify(said) });
}
window.onerror = (m) => { fetch('/result', { method: 'POST', body: JSON.stringify({ error: String(m) }) }); };
</script>"""
got = threading.Event()

class Serve(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        name = self.path.split("?")[0]
        if name == "/":
            body, kind = page.encode(), "text/html"
        elif name in ("/p5.min.js", "/p5.sound.min.js"):
            body, kind = open(os.path.join(p5, "addons" if "sound" in name else "", name[1:]), "rb").read(), "text/javascript"
        elif name == "/sketch.js":
            body, kind = open(sketch, "rb").read(), "text/javascript"
        elif name == "/favicon.ico":
            self.send_response(404); self.end_headers(); return
        else:
            body, kind = open(os.path.join(here, "tones.wav"), "rb").read(), "audio/wav"
        self.send_response(200); self.send_header("Content-Type", kind); self.send_header("Content-Length", str(len(body))); self.end_headers()
        self.wfile.write(body)
    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        self.send_response(200); self.end_headers()
        open(os.path.join(here, "chrome_p5.json"), "wb").write(body); got.set()

server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Serve)
threading.Thread(target=server.serve_forever, daemon=True).start()
chrome = subprocess.Popen(["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", "--headless=new",
                           "--remote-debugging-port=0", "--window-size=1200,1200", "http://127.0.0.1:%d/" % server.server_port],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
ok = got.wait(600)
chrome.terminate(); server.shutdown()
said = json.load(open(os.path.join(here, "chrome_p5.json"))) if ok else {"error": "no answer in 600 s"}
print(said.get("error") or "%d frames measured" % len(said["rows"]))
raise SystemExit(0 if ok and "rows" in said else 1)

#!/usr/bin/env python3
"""Asks headless Chrome what a DynamicsCompressorNode set as p5.sound sets its limiter (threshold -3, knee 1, ratio 20)
does to quiet sound: its gain and its delay, for one tone and for two together, and for the node as it comes.
Prints one line a case: the gain (output RMS over input RMS, over the last half second) and the delay in samples
(where the output best matches the input). Offline, 48,000 Hz.
"""
import http.server, json, subprocess, threading
page = """<!doctype html><meta charset="utf-8"><script>
(async () => {
  const rate = 48000, n = rate * 2, out = [];
  const cases = [['p5 limiter, one tone 0.098', [-3, 1, 20], [[1000, 0.098]]], ['p5 limiter, two tones 0.098', [-3, 1, 20], [[639, 0.098], [1134, 0.098]]],
    ['p5 limiter, one tone 0.49', [-3, 1, 20], [[1000, 0.49]]], ['p5 limiter, two tones 0.49', [-3, 1, 20], [[639, 0.49], [1134, 0.49]]],
    ['as it comes, one tone 0.01', null, [[1000, 0.01]]]];
  for (const [name, set, tones] of cases) {
    const ctx = new OfflineAudioContext(1, n, rate), b = ctx.createBuffer(1, n, rate), d = b.getChannelData(0);
    for (let i = 0; i < n; i++) for (const [f, a] of tones) d[i] += a * Math.sin(2 * Math.PI * f * i / rate);
    const s = ctx.createBufferSource(); s.buffer = b;
    const c = ctx.createDynamicsCompressor();
    if (set) c.threshold.value = set[0], c.knee.value = set[1], c.ratio.value = set[2];
    s.connect(c); c.connect(ctx.destination); s.start();
    const o = (await ctx.startRendering()).getChannelData(0);
    let a = 0, e = 0; for (let i = n - rate / 2; i < n; i++) a += d[i] * d[i], e += o[i] * o[i];
    let best = [-1, 0]; for (let lag = 0; lag < 600; lag++) { let x = 0; for (let i = rate; i < rate + 4800; i++) x += o[i] * d[i - lag]; if (x > best[0]) best = [x, lag]; }
    out.push(name + ': gain ' + Math.sqrt(e / a).toFixed(4) + ', delay ' + best[1] + ' samples, reduction ' + c.reduction.toFixed(3));
  }
  fetch('/result', { method: 'POST', body: JSON.stringify(out) });
})();
</script>"""
got = threading.Event(); said = []
class Serve(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        self.send_response(200 if self.path == "/" else 404); self.send_header("Content-Type", "text/html"); self.end_headers()
        if self.path == "/": self.wfile.write(page.encode())
    def do_POST(self):
        said.extend(json.loads(self.rfile.read(int(self.headers["Content-Length"])))); self.send_response(200); self.end_headers(); got.set()
server = http.server.HTTPServer(("127.0.0.1", 0), Serve)
threading.Thread(target=server.serve_forever, daemon=True).start()
chrome = subprocess.Popen(["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", "--headless=new", "--remote-debugging-port=0",
                           "http://127.0.0.1:%d/" % server.server_port], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
got.wait(120); chrome.terminate(); server.shutdown()
print("\n".join(said) or "no answer")

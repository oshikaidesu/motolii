#!/usr/bin/env python3
"""Writes chrome_tones.json: what headless Chrome's AnalyserNode reads of tones.wav.

An AnalyserNode as it comes (fftSize 2048) on a 48,000 Hz context is asked sixty times a second from the
start of the sound; for call k (second k / 60) the bytes of pitches 0 to 99 are kept. The sound goes into the page as
samples (ffmpeg makes them one channel at 48,000 Hz). Chrome's --dump-dom does not wait for the offline rendering, so
the page is served from this machine and posts its result back here.
"""
import base64, http.server, json, os, subprocess, threading

here = os.path.dirname(os.path.abspath(__file__))
samples = subprocess.run(["ffmpeg", "-v", "error", "-i", os.path.join(here, "tones.wav"), "-ac", "1", "-ar", "48000",
                          "-f", "f32le", "-"], capture_output=True, check=True).stdout
page = """<!doctype html><meta charset="utf-8"><title>AnalyserNode on tones.wav</title><script>
const wav = '%s';
(async () => {
  let said;
  try {
    const rate = 48000, bytes = Uint8Array.from(atob(wav), c => c.charCodeAt(0)), samples = new Float32Array(bytes.buffer);
    const ctx = new OfflineAudioContext(1, samples.length, rate), buffer = ctx.createBuffer(1, samples.length, rate);
    buffer.copyToChannel(samples, 0);
    const source = ctx.createBufferSource(); source.buffer = buffer;
    const analyser = ctx.createAnalyser();
    source.connect(analyser); analyser.connect(ctx.destination); source.start();
    const rows = {}, heard = new Uint8Array(1024);
    for (let k = 1; k * rate / 60 < samples.length; k++)
      ctx.suspend(k / 60).then(() => { analyser.getByteFrequencyData(heard); rows[k] = Array.from(heard.subarray(0, 100)); ctx.resume(); });
    await ctx.startRendering();
    said = { rate, fftSize: analyser.fftSize, rows };
  } catch (e) { said = { error: String(e) }; }
  fetch('/result', { method: 'POST', body: JSON.stringify(said) });
})();
</script>""" % base64.b64encode(samples).decode()
got = threading.Event()

class Serve(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        self.send_response(200); self.send_header("Content-Type", "text/html"); self.end_headers()
        self.wfile.write(page.encode())
    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        self.send_response(200); self.end_headers()
        open(os.path.join(here, "chrome_tones.json"), "wb").write(body); got.set()

server = http.server.HTTPServer(("127.0.0.1", 0), Serve)
threading.Thread(target=server.serve_forever, daemon=True).start()
chrome = subprocess.Popen(["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", "--headless=new",
                           "--remote-debugging-port=0", "http://127.0.0.1:%d/" % server.server_port],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
ok = got.wait(180)
chrome.terminate(); server.shutdown()
said = json.load(open(os.path.join(here, "chrome_tones.json"))) if ok else {"error": "no answer in 180 s"}
print(said.get("error") or "%d calls kept" % len(said["rows"]))
raise SystemExit(0 if ok and "rows" in said else 1)

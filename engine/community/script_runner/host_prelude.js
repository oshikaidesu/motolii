// Concise, typed host API over project_reads.cpp natives (see shelves/motolii-host.d.ts).
// Keeps expression code idiomatic JS rather than raw C-style bridge calls.
(function (g) {
  function hostK() {
    return g.__hostK || {};
  }
  function now(t) {
    if (t !== undefined) return t;
    if (typeof g.__hostT === 'number') return g.__hostT;
    const k = hostK();
    return typeof k.time === 'number' ? k.time : 0;
  }
  function resolveId(ref) {
    if (ref === undefined || ref === null) {
      const k = hostK();
      return typeof k.id === 'number' ? k.id : 0;
    }
    if (typeof ref === 'number') return ref | 0;
    if (typeof ref === 'string') return g.layerNamed ? g.layerNamed(ref) : 0;
    if (typeof ref === 'object' && typeof ref.id === 'number') return ref.id | 0;
    return 0;
  }

  function makeLayer(id, fixedT, copyIdx, explicitZero) {
    const exists = explicitZero ? id === 0 : id > 0;
    const tOf = (t) => (t !== undefined ? t : fixedT !== undefined ? fixedT : now());
    const num = (prop, fallback, t) => {
      if (!exists || !g.layerValue) return fallback;
      const v = g.layerValue(id, prop, tOf(t), fallback, copyIdx);
      return Number.isNaN(v) ? fallback : v;
    };
    const word = (prop) => (exists && g.layerWord ? g.layerWord(id, prop) : '');
    const handle = {
      id,
      exists,
      at(t) { return makeLayer(id, t, copyIdx, explicitZero); },
      copy(i) { return makeLayer(id, fixedT, i | 0, explicitZero); },
      get(prop, fallback, t) { return num(prop, fallback === undefined ? 0 : fallback, t); },
      word(prop) { return word(prop); },
      keys(prop) { return exists && g.layerKeys ? g.layerKeys(id, prop) : []; },
      fx(effectName, paramName, fallback, t) {
        const fb = fallback === undefined ? 0 : fallback;
        if (!exists || !g.layerEffect) return fb;
        const v = g.layerEffect(id, String(effectName), String(paramName), tOf(t));
        return Number.isNaN(v) ? fb : v;
      },
      toWorld(point, t) {
        return exists && g.toWorld ? g.toWorld(id, point, tOf(t)) : [NaN, NaN, NaN];
      },
      fromWorld(point, t) {
        return exists && g.fromWorld ? g.fromWorld(id, point, tOf(t)) : [NaN, NaN];
      },
      sample(point, radius, postEffect, t) {
        if (!exists || !g.sampleImage) return [0, 0, 0, 0];
        return g.sampleImage(
          id,
          point,
          radius === undefined ? [0.5, 0.5] : radius,
          postEffect === undefined ? true : postEffect,
          tOf(t)
        );
      },
      get name() { return word('name'); },
      get kind() { return word('kind'); },
      get text() { return word('text'); },
      get index() {
        if (!exists || !g.layers) return 0;
        return g.layers().indexOf(id) + 1;
      },
      get parent() {
        const pid = num('parent', 0, 0) | 0;
        return pid > 0 ? makeLayer(pid, fixedT, -1, false) : null;
      },
      get children() {
        if (!exists || !g.layerChildren) return [];
        return g.layerChildren(id).map((cid) => makeLayer(cid, fixedT, -1, false));
      },
      get start() { return num('start', 0, 0); },
      get duration() { return num('duration', -1, 0); },
      get x() { return num('x', 0); },
      get y() { return num('y', 0); },
      get z() { return num('z', 0); },
      get pos() { return [num('x', 0), num('y', 0), num('z', 0)]; },
      get size() { return num('size', 1); },
      get scaleX() { return num('scale_x', 1); },
      get scaleY() { return num('scale_y', 1); },
      get scaleZ() { return num('scale_z', 1); },
      get scale() { return [num('scale_x', 1), num('scale_y', 1), num('scale_z', 1)]; },
      get anchor() { return [num('anchor_x', 0), num('anchor_y', 0), num('anchor_z', 0)]; },
      get rotate() { return num('rotate', 0); },
      get rotateX() { return num('rotate_x', 0); },
      get rotateY() { return num('rotate_y', 0); },
      get opacity() { return num('opacity', 1); },
      get bounds() {
        return exists && g.layerBounds ? g.layerBounds(id, tOf()) : null;
      },
    };
    return handle;
  }

  function layer(ref, t) {
    const explicitZero = ref === 0;
    const id = resolveId(ref);
    return makeLayer(id, t, -1, explicitZero);
  }

  function makeAudio(id, fixedT) {
    const tOf = (t) => (t !== undefined ? t : fixedT !== undefined ? fixedT : now());
    const readBands = (t) =>
      g.audioBands ? g.audioBands(id, tOf(t)) : [0, 0, 0, 0, 0];
    return {
      at(t) { return makeAudio(id, t); },
      bands(t) {
        const b = readBands(t);
        return { bass: b[0], lowMid: b[1], highMid: b[2], treble: b[3], rms: b[4] };
      },
      get bass() { return readBands()[0]; },
      get lowMid() { return readBands()[1]; },
      get highMid() { return readBands()[2]; },
      get treble() { return readBands()[3]; },
      get rms() { return readBands()[4]; },
      spectrum(out, t) {
        const buf = out || new Uint8Array(128);
        const at = tOf(t);
        if (buf instanceof Float32Array) {
          if (g.getFloatFrequencyData) g.getFloatFrequencyData(id, buf, at);
        } else if (g.getByteFrequencyData) {
          g.getByteFrequencyData(id, buf, at);
        }
        return buf;
      },
      wave(out, t) {
        const buf = out || new Float32Array(1024);
        if (g.getFloatTimeDomainData) g.getFloatTimeDomainData(id, buf, tOf(t));
        return buf;
      },
    };
  }

  function audio(ref, t) {
    const id = ref === undefined || ref === null ? 0 : resolveId(ref);
    return makeAudio(id, t);
  }
  const masterAudio = makeAudio(0, undefined);
  for (const prop of ['bass', 'lowMid', 'highMid', 'treble', 'rms']) {
    Object.defineProperty(audio, prop, {
      get() { return masterAudio[prop]; },
      enumerable: true,
    });
  }
  audio.bands = (t) => masterAudio.bands(t);
  audio.spectrum = (out, t) => masterAudio.spectrum(out, t);
  audio.wave = (out, t) => masterAudio.wave(out, t);
  audio.at = (t) => makeAudio(0, t);

  function readMidi(source, channel, t) {
    const k = hostK();
    const cur = typeof k.id === 'number' ? k.id : 0;
    const src =
      source === undefined || source === null
        ? ''
        : typeof source === 'number'
        ? String(source | 0)
        : String(source);
    const ch = channel === undefined || channel === null ? -1 : channel | 0;
    return g.midiInfo
      ? g.midiInfo(cur, src, ch, now(t))
      : { vel: 0, pitch: 0, gate: 0, bpm: 120 };
  }
  function midi(source, channel, t) {
    return readMidi(source, channel, t);
  }
  for (const prop of ['vel', 'pitch', 'gate', 'bpm']) {
    Object.defineProperty(midi, prop, {
      get() { return readMidi('', -1)[prop]; },
      enumerable: true,
    });
  }

  const stage = {
    get time() { return now(); },
    get fps() {
      const k = hostK();
      if (typeof k.fps === 'number' && k.fps > 0) return k.fps;
      const v = g.layerValue ? g.layerValue(0, 'frame_rate', 0, 60, -1) : 60;
      return !Number.isNaN(v) && v > 0 ? v : 60;
    },
    get frame() { return now() * stage.fps; },
    get width() { return hostK().wide || 1920; },
    get height() { return hostK().high || 1080; },
    get duration() { return hostK().round || 0; },
    get px() { return hostK().px || 1; },
    get bpm() {
      const k = hostK();
      if (typeof k.bpm === 'number') return k.bpm;
      const v = g.layerValue ? g.layerValue(0, 'bpm', now(), 0, -1) : 0;
      return Number.isNaN(v) ? 0 : v;
    },
    get bpmFrom() {
      const k = hostK();
      if (typeof k.bpm_from === 'number') return k.bpm_from;
      const v = g.layerValue ? g.layerValue(0, 'bpm_from', 0, 0, -1) : 0;
      return Number.isNaN(v) ? 0 : v;
    },
    get beat() {
      const bpm = stage.bpm;
      return bpm > 0 ? (now() - stage.bpmFrom) * bpm / 60 : 0;
    },
    get layers() {
      return g.layers ? g.layers().map((id) => makeLayer(id, undefined, -1, false)) : [];
    },
    get self() { return layer(); },
    camera(t) {
      return g.cameraInfo
        ? g.cameraInfo(now(t))
        : { eye: [0, 0, 6], look: [0, 0, 0], up: [0, 1, 0], fov: 30, distance: 1, id: 0 };
    },
    toScreen(point, t) {
      return g.toScreen ? g.toScreen(point, now(t)) : [NaN, NaN];
    },
    get(prop, fallback, t) {
      const fb = fallback === undefined ? 0 : fallback;
      if (!g.layerValue) return fb;
      const v = g.layerValue(0, prop, now(t), fb, -1);
      return Number.isNaN(v) ? fb : v;
    },
    word(prop) { return g.layerWord ? g.layerWord(0, prop) : ''; },
  };

  g.layer = layer;
  g.stage = stage;
  g.audio = audio;
  g.midi = midi;
})(globalThis);

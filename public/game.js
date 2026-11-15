/*
 * Min Mis – en lille virtuel kat til en gammel iPad.
 *
 * Skrevet til Safari 12 (iPad Air 1. generation, iOS 12):
 *  - ingen ?. eller ??, ingen pointer events, ingen nyere canvas-funktioner
 *  - alt tegnes med kode på et canvas, så der er ingen billedfiler at hente
 *  - tilstanden gemmes i localStorage, og tiden går, også når spillet er lukket
 *  - katten dør aldrig; bliver den glemt, er den bare ked af det
 */
(function () {
  'use strict';

  // ================================================================ hjælpere
  const TAU = Math.PI * 2;
  const SAVE_KEY = 'minmis.v1';
  const FONT = '"Avenir Next", "Helvetica Neue", Helvetica, Arial, sans-serif';
  const POOP_EVERY = 420; // sekunder med spillet åbent mellem hver tur i kattebakken

  function clamp(v, a, b) { return v < a ? a : (v > b ? b : v); }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function rand(a, b) { return a + Math.random() * (b - a); }
  function pick(list) { return list[Math.floor(Math.random() * list.length)]; }
  function now() { return Date.now(); }
  function $(id) { return document.getElementById(id); }
  function dayKey(t) { const d = new Date(t); return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
  function hourOf(t) { const d = new Date(t); return d.getHours() + d.getMinutes() / 60; }
  function isNightAt(t) { const h = hourOf(t); return h >= 20 || h < 7; }
  function each(list, fn) { Array.prototype.forEach.call(list, fn); }

  function ell(c, x, y, rx, ry, rot) { c.beginPath(); c.ellipse(x, y, Math.max(rx, 0.1), Math.max(ry, 0.1), rot || 0, 0, TAU); }
  function circ(c, x, y, r) { c.beginPath(); c.arc(x, y, Math.max(r, 0.1), 0, TAU); }
  function rr(c, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    c.beginPath();
    c.moveTo(x + r, y);
    c.arcTo(x + w, y, x + w, y + h, r);
    c.arcTo(x + w, y + h, x, y + h, r);
    c.arcTo(x, y + h, x, y, r);
    c.arcTo(x, y, x + w, y, r);
    c.closePath();
  }
  function heartPath(c, x, y, r) {
    c.beginPath();
    c.moveTo(x, y + r * 0.95);
    c.bezierCurveTo(x - r * 1.7, y - r * 0.2, x - r * 0.65, y - r * 1.45, x, y - r * 0.45);
    c.bezierCurveTo(x + r * 0.65, y - r * 1.45, x + r * 1.7, y - r * 0.2, x, y + r * 0.95);
    c.closePath();
  }
  function starPath(c, x, y, r) {
    c.beginPath();
    for (let i = 0; i < 8; i++) {
      const a = i * Math.PI / 4 - Math.PI / 2;
      const d = i % 2 ? r * 0.38 : r;
      if (i === 0) c.moveTo(x + Math.cos(a) * d, y + Math.sin(a) * d);
      else c.lineTo(x + Math.cos(a) * d, y + Math.sin(a) * d);
    }
    c.closePath();
  }

  // ================================================================ data
  const COATS = {
    orange: { label: 'Rød', fur: '#F6A35B', dark: '#E07F2C', light: '#FFE9CF', inner: '#F8B4B0', eye: '#73C24A', line: '#7A4317', nose: '#F28B9B', whisker: 'rgba(90,50,30,0.5)', pattern: 'stripes' },
    gray: { label: 'Grå', fur: '#A3AEBB', dark: '#748291', light: '#E8EDF2', inner: '#F2B6C1', eye: '#EDB93C', line: '#46505B', nose: '#EE8C9E', whisker: 'rgba(50,55,65,0.5)', pattern: null },
    black: { label: 'Sort', fur: '#3C3B47', dark: '#24232B', light: '#5E5D6C', inner: '#C98394', eye: '#F4C430', line: '#141318', nose: '#C9707F', whisker: 'rgba(255,255,255,0.55)', pattern: null },
    white: { label: 'Hvid', fur: '#FCFBF7', dark: '#E2DED3', light: '#FFFFFF', inner: '#F8B9C6', eye: '#52A8E8', line: '#8F897E', nose: '#F49AAA', whisker: 'rgba(120,110,100,0.5)', pattern: null },
    tabby: { label: 'Stribet', fur: '#BC9168', dark: '#6F4C2D', light: '#EEDFCA', inner: '#EBAA9F', eye: '#7FBF5E', line: '#4B321D', nose: '#E58A8A', whisker: 'rgba(70,45,25,0.5)', pattern: 'stripes' },
    calico: { label: 'Trefarvet', fur: '#FCF8F1', dark: '#3C3B47', light: '#FFFFFF', inner: '#F8B9C6', eye: '#73C24A', line: '#6E5E50', nose: '#F49AAA', whisker: 'rgba(110,94,80,0.5)', pattern: 'calico', p1: '#EE9A4D', p2: '#3C3B47' }
  };
  const COAT_ORDER = ['orange', 'gray', 'black', 'white', 'tabby', 'calico'];

  // Katten vokser med tiden: killing de første 2 dage, ung kat til dag 6, derefter voksen.
  const STAGES = [
    { name: 'Killing', size: 0.95, body: 0.8, head: 1.18, pitch: 1.35 },
    { name: 'Ung kat', size: 1.08, body: 0.92, head: 1.07, pitch: 1.15 },
    { name: 'Voksen kat', size: 1.22, body: 1, head: 1, pitch: 1 }
  ];
  function stageFor(born, t) { const d = (t - born) / 86400000; return d < 2 ? 0 : (d < 6 ? 1 : 2); }

  // Pynt låses op, når man har samlet nok hjerter i alt (hjerterne bliver ikke brugt).
  const ITEMS = [
    { id: 'bow', slot: 'head', name: 'Sløjfe', icon: '🎀', cost: 0 },
    { id: 'bell', slot: 'neck', name: 'Klokke', icon: '🔔', cost: 15 },
    { id: 'flowers', slot: 'head', name: 'Blomster', icon: '🌸', cost: 35 },
    { id: 'glasses', slot: 'face', name: 'Solbriller', icon: '🕶️', cost: 60 },
    { id: 'hat', slot: 'head', name: 'Høj hat', icon: '🎩', cost: 90 },
    { id: 'scarf', slot: 'neck', name: 'Halstørklæde', icon: '🧣', cost: 130 },
    { id: 'crown', slot: 'head', name: 'Krone', icon: '👑', cost: 180 }
  ];

  const FOODS = {
    kibble: { food: 25, fun: 0 },
    fish: { food: 40, fun: 5 },
    shrimp: { food: 8, fun: 15, treat: true }
  };

  const HAPPY_LINES = ['Miav! ❤️', 'Purrr…', 'Jeg elsker dig! ❤️', 'Hvad skal vi lave nu?', 'Jeg er så glad i dag! 😸', 'Miav miav!'];

  const SKY = { night: ['#141B45', '#2C3A7A'], dawn: ['#A9D4F5', '#FFB59A'], day: ['#6EC3F4', '#CDEFFF'], dusk: ['#5A5BA8', '#F7945E'] };
  const HILLS = { night: ['#24365A', '#1C2C4C'], dawn: ['#9CC98A', '#7FB874'], day: ['#8BD17C', '#6CC05F'], dusk: ['#6E8F6A', '#5A7A5C'] };
  function skyPhase(t) { const h = hourOf(t); if (h >= 21 || h < 6) return 'night'; if (h < 8) return 'dawn'; if (h < 18) return 'day'; return 'dusk'; }

  // ================================================================ tilstand
  let S = null;          // det der gemmes
  let mode = 'normal';   // 'normal' | 'play' | 'wash'
  let T = 0;             // sekunder siden start (til animationer)
  let bubble = null;     // taleboble
  const parts = [];      // partikler (hjerter, bobler, stjerner …)
  const cat = { x: 0, y: 0, state: 'idle', timer: 2, t: 0, tail: 0, blink: 0, blinkT: 3, look: 0, walk: null, jump: null, hop: 0, petT: 0, scrubT: 0, happyT: 0, mouthT: 0, needT: 10, cool: 0, zT: 0, eatT: 0, moving: false, sleepHeart: false };
  const feather = { x: 0, y: 0, tx: 0, ty: 0, ang: 0, held: 0, catches: 0 };
  const sponge = { x: 0, y: 0 };
  let bowl = null;
  let poopClock = 0, modeEndT = 0, washDone = false, washGain = 0;
  let petAcc = 0, heartAcc = 0, bubAcc = 0;
  let stageT = 0, saveT = 5, hudT = 0, skyT = 0, skyNow = 'day';

  let canvas = null, ctx = null, bg = null, bgx = null;
  let W = 0, H = 0, U = 1, DPR = Math.min(window.devicePixelRatio || 1, 2);
  const G = {};

  function freshState(name, coat) {
    const t = now();
    return {
      v: 1, name: name, coat: coat, born: t, last: t,
      needs: { food: 75, fun: 80, energy: 90, clean: 95 },
      poop: 0, awakeMin: 0, hearts: 0, seenHearts: 0,
      wear: { head: 'bow', face: null, neck: null },
      lightsOff: false, sound: true, treats: [], stage: 0, bonusDay: dayKey(t)
    };
  }

  function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return null;
      const s = JSON.parse(raw);
      if (!s || typeof s.name !== 'string' || !s.needs) return null;
      const d = freshState(s.name, COATS[s.coat] ? s.coat : 'orange');
      Object.keys(d).forEach(k => { if (!(k in s)) s[k] = d[k]; });
      if (!COATS[s.coat]) s.coat = 'orange';
      ['food', 'fun', 'energy', 'clean'].forEach(k => { if (typeof s.needs[k] !== 'number' || isNaN(s.needs[k])) s.needs[k] = 70; });
      if (!s.wear || typeof s.wear !== 'object') s.wear = { head: null, face: null, neck: null };
      if (!Array.isArray(s.treats)) s.treats = [];
      return s;
    } catch (e) { return null; }
  }
  function save() {
    if (!S) return;
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(S)); } catch (e) { /* privat browsing */ }
  }

  // ================================================================ behov og tid
  function clampNeeds() { const n = S.needs; Object.keys(n).forEach(k => { n[k] = clamp(n[k], 0, 100); }); }

  // Mens spillet er åbent.
  function liveTick(sec, sleeping) {
    const h = sec / 3600, n = S.needs;
    if (sleeping) { n.food -= 2 * h; n.fun -= 1 * h; n.clean -= 1 * h; n.energy += 0.5 * sec; }
    else { n.food -= 6 * h; n.fun -= 6 * h; n.energy -= 5 * h; n.clean -= (3.5 + 3 * S.poop) * h; }
    clampNeeds();
  }
  // Mens spillet er lukket. Om natten (20-7) sover katten.
  function offlineTick(sec, sleeping) {
    const h = sec / 3600, n = S.needs;
    if (sleeping) { n.food -= 2 * h; n.fun -= 1 * h; n.clean -= 1 * h; n.energy += 25 * h; }
    else {
      n.food -= 6 * h; n.fun -= 6 * h; n.energy -= 5 * h; n.clean -= (3.5 + 3 * S.poop) * h;
      S.awakeMin += sec / 60;
      if (S.awakeMin >= 240) { S.awakeMin -= 240; if (S.poop < 3) S.poop++; }
    }
    clampNeeds();
  }
  function catchUp() {
    const t = now();
    let from = S.last || t;
    if (from > t) from = t;
    const away = t - from;
    let left = Math.min(away, 3 * 86400000);
    let cur = t - left;
    while (left > 0) {
      const ch = Math.min(600000, left);
      offlineTick(ch / 1000, S.lightsOff || isNightAt(cur));
      cur += ch; left -= ch;
    }
    S.last = t;
    return away;
  }

  function minNeed() { const n = S.needs; return Math.min(n.food, n.fun, n.energy, n.clean); }
  function moodOf() {
    const n = S.needs, m = minNeed();
    const avg = (n.food + n.fun + n.energy + n.clean) / 4;
    if (m < 15) return 'sad';
    if (m < 35) return 'meh';
    if (avg >= 65) return 'happy';
    return 'ok';
  }
  function needLine() {
    const n = S.needs;
    if (S.poop >= 2) return 'Kattebakken lugter! 💩';
    const list = [
      { v: n.food, t: 'Jeg er sulten! 🐟' },
      { v: n.energy, t: 'Jeg er så træt… 💤' },
      { v: n.clean, t: 'Jeg trænger til en vask! 🛁' },
      { v: n.fun, t: 'Vil du lege med mig? 🧶' }
    ].sort((a, b) => a.v - b.v);
    if (list[0].v < 40) return list[0].t;
    if (isNightAt(now()) && !S.lightsOff) return 'Det er sengetid… 🌙';
    return null;
  }

  // ================================================================ lyd (Web Audio, ingen lydfiler)
  let actx = null, master = null, noiseBuf = null, purr = null, lastMeow = 0;
  function unlockAudio() {
    if (actx) { if (actx.state === 'suspended' && actx.resume) actx.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    try {
      actx = new AC();
      master = actx.createGain(); master.gain.value = 0.55; master.connect(actx.destination);
      const b = actx.createBuffer(1, 1, 22050);
      const src = actx.createBufferSource(); src.buffer = b; src.connect(actx.destination); src.start(0);
    } catch (e) { actx = null; }
  }
  function soundOn() { return !!(actx && S && S.sound); }
  function tone(type, f0, f1, dur, vol, delay) {
    if (!soundOn()) return;
    const t = actx.currentTime + (delay || 0);
    const o = actx.createOscillator(), g = actx.createGain();
    o.type = type;
    o.frequency.setValueAtTime(f0, t);
    if (f1) o.frequency.exponentialRampToValueAtTime(f1, t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(vol, t + 0.015);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g); g.connect(master);
    o.start(t); o.stop(t + dur + 0.05);
  }
  function meow(pitch) {
    if (!soundOn()) return;
    const tn = now();
    if (tn - lastMeow < 700) return;
    lastMeow = tn;
    const p = pitch || 1, t = actx.currentTime;
    const o = actx.createOscillator(), f = actx.createBiquadFilter(), g = actx.createGain();
    o.type = 'sawtooth';
    o.frequency.setValueAtTime(430 * p, t);
    o.frequency.linearRampToValueAtTime(780 * p, t + 0.17);
    o.frequency.linearRampToValueAtTime(520 * p, t + 0.55);
    f.type = 'bandpass'; f.Q.value = 3.5;
    f.frequency.setValueAtTime(900 * p, t);
    f.frequency.linearRampToValueAtTime(1900 * p, t + 0.2);
    f.frequency.linearRampToValueAtTime(1000 * p, t + 0.55);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.55, t + 0.06);
    g.gain.setValueAtTime(0.55, t + 0.36);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.6);
    o.connect(f); f.connect(g); g.connect(master);
    o.start(t); o.stop(t + 0.65);
  }
  function startPurr() {
    if (!soundOn() || purr) return;
    const t = actx.currentTime;
    if (!noiseBuf) {
      const n = actx.sampleRate;
      noiseBuf = actx.createBuffer(1, n, actx.sampleRate);
      const d = noiseBuf.getChannelData(0);
      for (let i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
    }
    const src = actx.createBufferSource(); src.buffer = noiseBuf; src.loop = true;
    const lp = actx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 170;
    const amp = actx.createGain(); amp.gain.value = 0.5;
    const lfo = actx.createOscillator(); lfo.frequency.value = 24;
    const depth = actx.createGain(); depth.gain.value = 0.5;
    const out = actx.createGain();
    out.gain.setValueAtTime(0.0001, t); out.gain.exponentialRampToValueAtTime(1.4, t + 0.3);
    lfo.connect(depth); depth.connect(amp.gain);
    src.connect(lp); lp.connect(amp); amp.connect(out); out.connect(master);
    src.start(t); lfo.start(t);
    purr = { src: src, lfo: lfo, out: out };
  }
  function stopPurr() {
    if (!purr) return;
    const p = purr; purr = null;
    try {
      const t = actx.currentTime;
      p.out.gain.cancelScheduledValues(t);
      p.out.gain.setValueAtTime(Math.max(p.out.gain.value, 0.001), t);
      p.out.gain.exponentialRampToValueAtTime(0.0001, t + 0.35);
    } catch (e) { /* ignorer */ }
    setTimeout(() => { try { p.src.stop(); p.lfo.stop(); } catch (e) { /* ignorer */ } }, 450);
  }
  function clickSound() { tone('sine', 660, 0, 0.06, 0.07); }
  function popSound() { tone('sine', 520, 1250, 0.07, 0.1); }
  function chime() { tone('sine', 988, 0, 0.28, 0.16); tone('sine', 1319, 0, 0.4, 0.13, 0.09); }
  function nomSound() { tone('triangle', 250, 150, 0.1, 0.22); }
  function plopSound() { tone('sine', 320, 90, 0.2, 0.3); }
  function jumpSound() { tone('triangle', 300, 650, 0.14, 0.12); }
  function scoopSound() { tone('triangle', 200, 420, 0.12, 0.15); tone('sine', 880, 0, 0.18, 0.1, 0.1); }
  function fanfare() { [523, 659, 784, 1047].forEach((f, i) => tone('triangle', f, 0, 0.3, 0.16, i * 0.13)); }

  // ================================================================ tale, hjerter, beskeder
  function say(text, dur) { bubble = { text: text, t: dur || 3.2, d: dur || 3.2 }; }
  function meowSay(text, dur) {
    say(text, dur);
    cat.mouthT = 0.45;
    meow(STAGES[S.stage].pitch * rand(0.95, 1.08));
  }

  const toastQ = [];
  let toastBusy = false;
  function toast(text) { toastQ.push(text); if (!toastBusy) nextToast(); }
  function nextToast() {
    const el = $('toast');
    const t = toastQ.shift();
    if (!t) { toastBusy = false; return; }
    toastBusy = true;
    el.textContent = t;
    el.classList.add('show');
    setTimeout(() => { el.classList.remove('show'); setTimeout(nextToast, 350); }, 2600);
  }

  function addHearts(n, x, y) {
    const before = S.hearts;
    S.hearts += n;
    const hx = x === undefined ? cat.x : x, hy = y === undefined ? cat.y - 160 * U : y;
    for (let i = 0; i < n; i++) spawn('heart', hx + rand(-20, 20) * U, hy + rand(-10, 10) * U, { vy: -70 - rand(0, 30), vx: rand(-20, 20), life: 1.4, size: 14 * U });
    chime();
    const el = $('hearts');
    el.classList.remove('bump'); void el.offsetWidth; el.classList.add('bump');
    ITEMS.forEach(it => { if (it.cost > before && it.cost <= S.hearts) toast('Nyt pynt låst op: ' + it.icon + ' ' + it.name + '!'); });
  }

  // ================================================================ partikler
  function spawn(type, x, y, o) {
    o = o || {};
    parts.push({ type: type, x: x, y: y, vx: o.vx || 0, vy: o.vy || 0, life: o.life || 1, max: o.life || 1, size: o.size || 10, color: o.color || null, text: o.text || '', ph: Math.random() * TAU });
    if (parts.length > 140) parts.shift();
  }
  function burst(type, x, y, n, speed, o) {
    for (let i = 0; i < n; i++) {
      const a = rand(0, TAU), v = rand(speed * 0.4, speed);
      spawn(type, x, y, Object.assign({}, o, { vx: Math.cos(a) * v, vy: Math.sin(a) * v }));
    }
  }
  function updateParts(dt) {
    for (let i = parts.length - 1; i >= 0; i--) {
      const p = parts[i];
      p.life -= dt;
      if (p.life <= 0) { parts.splice(i, 1); continue; }
      p.x += p.vx * dt; p.y += p.vy * dt;
      if (p.type === 'heart' || p.type === 'zzz' || p.type === 'bubble') p.x += Math.sin(p.ph + p.life * 4) * 18 * dt;
      if (p.type === 'sparkle') { p.vx *= 0.93; p.vy *= 0.93; }
    }
  }
  function drawParts(c) {
    for (let i = 0; i < parts.length; i++) {
      const p = parts[i];
      c.globalAlpha = clamp(p.life / p.max * 1.6, 0, 1);
      if (p.type === 'heart') {
        c.fillStyle = p.color || '#FF4F86'; heartPath(c, p.x, p.y, p.size); c.fill();
        c.fillStyle = 'rgba(255,255,255,0.6)'; circ(c, p.x - p.size * 0.45, p.y - p.size * 0.55, p.size * 0.2); c.fill();
      } else if (p.type === 'bubble') {
        c.fillStyle = 'rgba(255,255,255,0.45)'; c.strokeStyle = 'rgba(110,170,230,0.9)'; c.lineWidth = 2;
        circ(c, p.x, p.y, p.size); c.fill(); c.stroke();
        c.fillStyle = 'rgba(255,255,255,0.9)'; circ(c, p.x - p.size * 0.35, p.y - p.size * 0.35, p.size * 0.25); c.fill();
      } else if (p.type === 'sparkle') {
        c.fillStyle = p.color || '#FFD84D';
        starPath(c, p.x, p.y, p.size * (0.6 + 0.4 * Math.sin(p.ph + p.life * 10))); c.fill();
      } else if (p.type === 'zzz' || p.type === 'text') {
        const sz = p.type === 'zzz' ? p.size * (1.6 - p.life / p.max * 0.6) : p.size;
        c.fillStyle = p.type === 'zzz' ? '#C9D2FF' : (p.color || '#8A5A3C');
        c.font = '800 ' + Math.round(sz) + 'px ' + FONT;
        c.textAlign = 'center'; c.textBaseline = 'middle';
        c.fillText(p.type === 'zzz' ? 'Z' : p.text, p.x, p.y);
      }
    }
    c.globalAlpha = 1;
  }

  // ================================================================ tegning af katten
  // Katten tegnes med fødderne i (0,0) og ca. 190 enheder høj ved skala 1.
  function drawCat(c, p) {
    const k = COATS[p.coat] || COATS.orange;
    const st = STAGES[p.stage || 0];
    const bs = st.body, hs = st.head;
    const lift = p.lift || 0;
    c.save();
    c.translate(p.x, p.y);
    if (!p.noShadow) {
      const sh = 1 - Math.min(lift / (220 * p.s), 0.6);
      c.fillStyle = 'rgba(90,55,30,0.18)';
      ell(c, 0, 0, 60 * p.s * bs * sh, 11 * p.s * sh); c.fill();
    }
    c.translate(0, -lift);
    c.scale(p.s, p.s);
    c.lineJoin = 'round'; c.lineCap = 'round';

    // krop
    c.save();
    c.scale(bs, bs);
    const sw = Math.sin(p.tail || 0);
    c.beginPath();
    c.moveTo(26, -20);
    c.bezierCurveTo(80, -12, 98 + sw * 6, -60, 72 + sw * 18, -106);
    c.strokeStyle = k.line; c.lineWidth = 22; c.stroke();
    c.strokeStyle = k.pattern === 'calico' ? k.p1 : k.fur; c.lineWidth = 15.5; c.stroke();
    if (k.pattern === 'stripes') {
      c.lineCap = 'butt'; c.setLineDash([7, 10]); c.strokeStyle = k.dark; c.stroke();
      c.setLineDash([]); c.lineCap = 'round';
    }
    c.fillStyle = k.fur; c.strokeStyle = k.line; c.lineWidth = 3.2;
    ell(c, -30, -22, 24, 21); c.fill(); c.stroke();
    ell(c, 30, -22, 24, 21); c.fill(); c.stroke();
    ell(c, 0, -56, 45, 55); c.fill();
    bodyMarkings(c, k);
    c.strokeStyle = k.line; c.lineWidth = 3.2; ell(c, 0, -56, 45, 55); c.stroke();
    c.fillStyle = k.light; ell(c, 0, -44, 26, 34); c.fill();
    if (p.dirt > 0.05) dirtSpots(c, p.dirt, [[-18, -40, 9], [21, -72, 7], [10, -22, 6], [-30, -20, 6]]);
    if (!p.pawsUp) {
      const step = p.step || 0;
      paw(c, k, -15, -7 - Math.max(0, step) * 7);
      paw(c, k, 15, -7 - Math.max(0, -step) * 7);
    }
    c.restore();

    // hoved
    const headY = -118 * bs;
    c.save();
    c.translate(0, headY);
    c.rotate(p.tilt || 0);
    c.scale(hs, hs);
    drawHead(c, k, p);
    c.restore();

    // halsbånd mm. tegnes efter hovedet, så det ses under hagen
    const neckY = headY + 47 * hs;
    if (p.wear && p.wear.neck) drawNeck(c, p.wear.neck, neckY, bs);
    if (p.pawsUp) { paw(c, k, -40 * hs, headY + 32 * hs); paw(c, k, 40 * hs, headY + 32 * hs); }
    c.restore();
  }

  function bodyMarkings(c, k) {
    if (!k.pattern) return;
    c.save();
    ell(c, 0, -56, 45, 55); c.clip();
    if (k.pattern === 'stripes') {
      c.strokeStyle = k.dark; c.lineWidth = 6;
      for (let i = 0; i < 3; i++) {
        const y = -84 + i * 19;
        c.beginPath(); c.moveTo(-48, y); c.quadraticCurveTo(-36, y + 7, -27, y + 3); c.stroke();
        c.beginPath(); c.moveTo(48, y); c.quadraticCurveTo(36, y + 7, 27, y + 3); c.stroke();
      }
    } else if (k.pattern === 'calico') {
      c.fillStyle = k.p1; ell(c, -30, -84, 28, 30); c.fill();
      c.fillStyle = k.p2; ell(c, 36, -42, 22, 26); c.fill();
      c.fillStyle = k.p1; ell(c, 26, -100, 16, 12); c.fill();
    }
    c.restore();
  }

  function paw(c, k, x, y) {
    c.fillStyle = k.light; c.strokeStyle = k.line; c.lineWidth = 3;
    ell(c, x, y, 13, 9); c.fill(); c.stroke();
    c.lineWidth = 1.6;
    c.beginPath(); c.moveTo(x - 4, y + 1); c.lineTo(x - 4, y + 7); c.moveTo(x + 4, y + 1); c.lineTo(x + 4, y + 7); c.stroke();
  }

  function dirtSpots(c, a, spots) {
    c.fillStyle = 'rgba(115,80,45,' + (0.5 * a).toFixed(2) + ')';
    spots.forEach(s => { circ(c, s[0], s[1], s[2]); c.fill(); });
  }

  function ear(c, k, side, fill) {
    c.save();
    c.scale(side, 1);
    c.beginPath(); c.moveTo(-53, -12); c.lineTo(-45, -68); c.lineTo(-12, -44); c.closePath();
    c.fillStyle = fill; c.fill(); c.strokeStyle = k.line; c.lineWidth = 3.2; c.stroke();
    c.beginPath(); c.moveTo(-45, -22); c.lineTo(-41, -56); c.lineTo(-22, -41); c.closePath();
    c.fillStyle = k.inner; c.fill();
    c.restore();
  }

  function drawHead(c, k, p) {
    ear(c, k, 1, k.pattern === 'calico' ? k.p1 : k.fur);
    ear(c, k, -1, k.pattern === 'calico' ? k.p2 : k.fur);
    c.fillStyle = k.fur; ell(c, 0, 0, 60, 48); c.fill();
    if (k.pattern) {
      c.save(); ell(c, 0, 0, 60, 48); c.clip();
      if (k.pattern === 'stripes') {
        c.strokeStyle = k.dark; c.lineWidth = 5;
        c.beginPath();
        c.moveTo(0, -46); c.lineTo(0, -30); c.moveTo(-13, -44); c.lineTo(-10, -31); c.moveTo(13, -44); c.lineTo(10, -31);
        c.moveTo(-62, -2); c.lineTo(-47, 1); c.moveTo(-62, 8); c.lineTo(-48, 8);
        c.moveTo(62, -2); c.lineTo(47, 1); c.moveTo(62, 8); c.lineTo(48, 8);
        c.stroke();
      } else if (k.pattern === 'calico') {
        c.fillStyle = k.p1; ell(c, -38, -28, 32, 26); c.fill();
        c.fillStyle = k.p2; ell(c, 42, -24, 28, 24); c.fill();
      }
      c.restore();
    }
    c.strokeStyle = k.line; c.lineWidth = 3.2; ell(c, 0, 0, 60, 48); c.stroke();
    // snude
    c.fillStyle = k.light; ell(c, -12, 15, 16, 12); c.fill(); ell(c, 12, 15, 16, 12); c.fill();
    if (p.blush) { c.fillStyle = 'rgba(255,110,140,0.33)'; ell(c, -38, 14, 10, 6); c.fill(); ell(c, 38, 14, 10, 6); c.fill(); }
    eye(c, k, p, -23, -6, -1);
    eye(c, k, p, 23, -6, 1);
    c.fillStyle = k.nose;
    c.beginPath(); c.moveTo(-6.5, 6); c.lineTo(6.5, 6); c.lineTo(0, 13); c.closePath(); c.fill();
    mouth(c, p.mouth || 'w');
    c.strokeStyle = k.whisker; c.lineWidth = 1.6;
    c.beginPath();
    c.moveTo(-26, 12); c.lineTo(-64, 4); c.moveTo(-26, 16); c.lineTo(-66, 17); c.moveTo(-26, 20); c.lineTo(-62, 29);
    c.moveTo(26, 12); c.lineTo(64, 4); c.moveTo(26, 16); c.lineTo(66, 17); c.moveTo(26, 20); c.lineTo(62, 29);
    c.stroke();
    if (p.dirt > 0.05) dirtSpots(c, p.dirt, [[-34, -22, 7], [30, 26, 6], [44, -12, 5]]);
    if (p.wear) {
      if (p.wear.face) drawFace(c, p.wear.face);
      if (p.wear.head) drawHat(c, p.wear.head);
    }
  }

  function eye(c, k, p, ex, ey, side) {
    const kind = p.eyes || 'open';
    c.strokeStyle = '#2B2027'; c.lineWidth = 4;
    if (kind === 'happy') { c.beginPath(); c.arc(ex, ey + 5, 10, Math.PI * 1.15, Math.PI * 1.85); c.stroke(); return; }
    if (kind === 'closed') { c.beginPath(); c.arc(ex, ey - 5, 10, Math.PI * 0.15, Math.PI * 0.85); c.stroke(); return; }
    if (kind === 'blink') { c.beginPath(); c.moveTo(ex - 10, ey + 1); c.lineTo(ex + 10, ey + 1); c.stroke(); return; }
    c.fillStyle = k.eye; ell(c, ex, ey, 12, 14); c.fill();
    c.lineWidth = 2.4; c.stroke();
    const wide = kind === 'wide';
    const lx = (p.lookX || 0) * 3, ly = (p.lookY || 0) * 3;
    c.fillStyle = '#1D1820'; ell(c, ex + lx, ey + ly, wide ? 9 : 6.2, wide ? 12 : 10.5); c.fill();
    c.fillStyle = '#FFFFFF';
    circ(c, ex + lx - 3, ey + ly - 5, 3.6); c.fill();
    circ(c, ex + lx + 3.2, ey + ly + 4, 1.7); c.fill();
    if (p.lid > 0) {
      c.save(); ell(c, ex, ey, 12.6, 14.6); c.clip();
      c.fillStyle = k.fur; c.fillRect(ex - 14, ey - 16, 28, 2 + 28 * p.lid);
      c.restore();
      const lidY = ey - 14 + 28 * p.lid;
      c.strokeStyle = '#2B2027'; c.lineWidth = 3;
      c.beginPath(); c.moveTo(ex - 11, lidY); c.lineTo(ex + 11, lidY); c.stroke();
    }
    if (kind === 'sad') {
      c.strokeStyle = '#2B2027'; c.lineWidth = 3.2;
      c.beginPath(); c.moveTo(ex + side * 11, ey - 19); c.lineTo(ex - side * 9, ey - 26); c.stroke();
      if (p.tear && side < 0) { c.fillStyle = '#7EC8F2'; ell(c, ex + 3, ey + 21, 4, 6); c.fill(); }
    }
  }

  function mouth(c, m) {
    c.strokeStyle = '#2B2027'; c.lineWidth = 2.6;
    if (m === 'flat') { c.beginPath(); c.moveTo(-7, 21); c.lineTo(7, 21); c.stroke(); return; }
    if (m === 'sad') { c.beginPath(); c.moveTo(-8, 24); c.quadraticCurveTo(0, 16, 8, 24); c.stroke(); return; }
    if (m === 'open') {
      c.fillStyle = '#7A2C3A'; ell(c, 0, 22, 7, 8); c.fill();
      c.fillStyle = '#F27C8C'; ell(c, 0, 26, 4.5, 3.4); c.fill();
    }
    c.beginPath();
    c.moveTo(0, 13); c.quadraticCurveTo(-1, 21, -9, 20);
    c.moveTo(0, 13); c.quadraticCurveTo(1, 21, 9, 20);
    c.stroke();
  }

  function drawHat(c, id) {
    if (id === 'bow') {
      c.save(); c.translate(36, -40); c.rotate(0.35);
      c.fillStyle = '#FF5C9A'; c.strokeStyle = '#B5306A'; c.lineWidth = 2.5;
      c.beginPath(); c.moveTo(0, 0); c.lineTo(-24, -14); c.lineTo(-22, 14); c.closePath(); c.fill(); c.stroke();
      c.beginPath(); c.moveTo(0, 0); c.lineTo(24, -14); c.lineTo(22, 14); c.closePath(); c.fill(); c.stroke();
      c.fillStyle = '#FF8DBA'; circ(c, 0, 0, 6.5); c.fill(); c.stroke();
      c.restore();
    } else if (id === 'flowers') {
      const cols = ['#FF8FB1', '#FFD166', '#FFFFFF', '#C3A6FF'];
      for (let i = 0; i < 7; i++) {
        const a = Math.PI * 1.1 + i * (Math.PI * 0.8 / 6);
        const x = Math.cos(a) * 54, y = Math.sin(a) * 42 - 4;
        c.fillStyle = '#6BBF59'; ell(c, x + 7, y + 3, 7, 3.5, a); c.fill();
        c.fillStyle = cols[i % 4];
        for (let j = 0; j < 5; j++) { const b = j * TAU / 5; circ(c, x + Math.cos(b) * 5.5, y + Math.sin(b) * 5.5, 5); c.fill(); }
        c.fillStyle = '#F4A300'; circ(c, x, y, 3.6); c.fill();
      }
    } else if (id === 'hat') {
      c.fillStyle = '#2B2B36'; c.strokeStyle = '#111118'; c.lineWidth = 2.5;
      rr(c, -29, -106, 58, 66, 7); c.fill(); c.stroke();
      c.fillStyle = '#E63946'; c.fillRect(-29, -56, 58, 11);
      c.fillStyle = '#2B2B36'; ell(c, 0, -40, 48, 10); c.fill(); c.stroke();
      c.fillStyle = 'rgba(255,255,255,0.18)'; c.fillRect(-21, -100, 7, 40);
    } else if (id === 'crown') {
      c.fillStyle = '#F7C531'; c.strokeStyle = '#B07A06'; c.lineWidth = 2.5;
      c.beginPath();
      c.moveTo(-32, -40); c.lineTo(-34, -84); c.lineTo(-16, -62); c.lineTo(0, -92); c.lineTo(16, -62); c.lineTo(34, -84); c.lineTo(32, -40);
      c.closePath(); c.fill(); c.stroke();
      c.fillStyle = '#E63946'; circ(c, 0, -51, 5.5); c.fill();
      c.fillStyle = '#3A86FF'; circ(c, -19, -50, 4.5); c.fill();
      c.fillStyle = '#2EC4B6'; circ(c, 19, -50, 4.5); c.fill();
      c.fillStyle = '#FFE680'; circ(c, -34, -86, 4); c.fill(); circ(c, 0, -94, 4); c.fill(); circ(c, 34, -86, 4); c.fill();
    }
  }

  function drawFace(c, id) {
    if (id !== 'glasses') return;
    c.fillStyle = 'rgba(28,28,44,0.94)'; c.strokeStyle = '#0E0E16'; c.lineWidth = 2.5;
    rr(c, -41, -19, 35, 26, 10); c.fill(); c.stroke();
    rr(c, 6, -19, 35, 26, 10); c.fill(); c.stroke();
    c.beginPath(); c.moveTo(-6, -10); c.quadraticCurveTo(0, -15, 6, -10); c.stroke();
    c.beginPath(); c.moveTo(-41, -12); c.lineTo(-58, -18); c.moveTo(41, -12); c.lineTo(58, -18); c.stroke();
    c.strokeStyle = 'rgba(255,255,255,0.55)'; c.lineWidth = 3;
    c.beginPath(); c.moveTo(-34, -12); c.lineTo(-26, -4); c.moveTo(13, -12); c.lineTo(21, -4); c.stroke();
  }

  function drawNeck(c, id, y, bs) {
    const rx = 27 * bs + 4;
    if (id === 'bell') {
      c.strokeStyle = '#E63946'; c.lineWidth = 7;
      c.beginPath(); c.ellipse(0, y - 5, rx, 9, 0, 0.12 * Math.PI, 0.88 * Math.PI); c.stroke();
      c.fillStyle = '#FFD23F'; c.strokeStyle = '#B8860B'; c.lineWidth = 2;
      circ(c, 0, y + 9, 8); c.fill(); c.stroke();
      c.beginPath(); c.moveTo(-5, y + 10); c.lineTo(5, y + 10); c.stroke();
      c.fillStyle = '#8A6508'; circ(c, 0, y + 13, 1.8); c.fill();
    } else if (id === 'scarf') {
      c.strokeStyle = '#3FA7D6'; c.lineWidth = 13;
      c.beginPath(); c.ellipse(0, y - 6, rx + 2, 10, 0, 0.05 * Math.PI, 0.95 * Math.PI); c.stroke();
      c.save(); c.translate(rx * 0.45, y + 1); c.rotate(0.22);
      c.fillStyle = '#3FA7D6'; rr(c, -7, 0, 15, 36, 4); c.fill();
      c.fillStyle = '#FFFFFF'; c.fillRect(-7, 11, 15, 4); c.fillRect(-7, 23, 15, 4);
      c.restore();
    }
  }

  function drawSleepingCat(c, p) {
    const k = COATS[p.coat] || COATS.orange;
    const st = STAGES[p.stage || 0];
    const bs = st.body;
    const br = 1 + Math.sin(p.t * 2.2) * 0.03;
    c.save();
    c.translate(p.x, p.y);
    c.scale(p.s, p.s);
    c.lineJoin = 'round'; c.lineCap = 'round';
    c.save();
    c.scale(bs, bs);
    c.save();
    c.translate(0, -32); c.scale(1, br);
    c.fillStyle = k.fur; ell(c, 10, 0, 74, 34); c.fill();
    if (k.pattern) {
      c.save(); ell(c, 10, 0, 74, 34); c.clip();
      if (k.pattern === 'stripes') {
        c.strokeStyle = k.dark; c.lineWidth = 6;
        for (let i = 0; i < 4; i++) { const x = i * 20; c.beginPath(); c.moveTo(x, -36); c.quadraticCurveTo(x + 8, -22, x + 4, -12); c.stroke(); }
      } else if (k.pattern === 'calico') {
        c.fillStyle = k.p1; ell(c, 40, -14, 30, 22); c.fill();
        c.fillStyle = k.p2; ell(c, -6, 14, 22, 16); c.fill();
      }
      c.restore();
    }
    c.strokeStyle = k.line; c.lineWidth = 3.2; ell(c, 10, 0, 74, 34); c.stroke();
    c.restore();
    c.beginPath(); c.moveTo(78, -26); c.quadraticCurveTo(92, 2, 30, 0); c.quadraticCurveTo(0, -1, -16, -6);
    c.strokeStyle = k.line; c.lineWidth = 20; c.stroke();
    c.strokeStyle = k.pattern === 'calico' ? k.p1 : k.fur; c.lineWidth = 14; c.stroke();
    paw(c, k, 24, -6);
    c.restore();
    c.save();
    c.translate(-50 * bs, -50 * bs); c.rotate(-0.15); c.scale(st.head * 0.88, st.head * 0.88);
    drawHead(c, k, { eyes: 'closed', mouth: 'w', blush: true, wear: p.wear, dirt: p.dirt });
    c.restore();
    c.restore();
  }

  function drawFlies(c, hx, hy, s) {
    for (let i = 0; i < 2; i++) {
      const a = T * (3 + i) + i * 2;
      const x = hx + Math.cos(a) * 70 * s, y = hy + Math.sin(a * 1.3) * 40 * s - 20 * s;
      c.fillStyle = 'rgba(255,255,255,0.75)';
      ell(c, x - 3, y - 4, 4, 2.5, -0.5); c.fill();
      ell(c, x + 3, y - 4, 4, 2.5, 0.5); c.fill();
      c.fillStyle = '#222'; circ(c, x, y, 3); c.fill();
    }
  }

  // ================================================================ stuen
  function objScale(y) { const d = clamp((y - G.floorY) / (H - G.floorY), 0, 1); return U * (0.72 + 0.32 * d); }
  function catScale() { return objScale(cat.y) * STAGES[S.stage].size; }

  function layout() {
    const r = canvas.getBoundingClientRect();
    W = Math.max(1, r.width); H = Math.max(1, r.height);
    canvas.width = Math.round(W * DPR); canvas.height = Math.round(H * DPR);
    U = Math.min(W / 760, H / 560);
    G.floorY = H * 0.56;
    G.catY = H * 0.88;
    G.litter = { x: Math.max(W * 0.11, 92 * U), y: H * 0.72 };
    G.bowl = { x: Math.max(W * 0.28, G.litter.x + 172 * U), y: H * 0.905 };
    G.bed = { x: Math.min(W * 0.83, W - 122 * U), y: H * 0.8 };
    G.minX = Math.max(W * 0.12, 90 * U);
    G.maxX = W - Math.max(W * 0.1, 125 * U);
    const ww = Math.min(W * 0.3, H * 0.55);
    G.win = { x: Math.max(W * 0.16, 50 * U), y: H * 0.08, w: ww, h: H * 0.34 };
    G.clock = { x: Math.min(W * 0.84, W - 60 * U), y: H * 0.19, r: 34 * U };
    G.pic = { x: G.win.x + ww + Math.max(60 * U, W * 0.07), y: H * 0.12, w: 110 * U, h: 84 * U };
    if (G.pic.x + G.pic.w > G.clock.x - G.clock.r - 16 * U) G.pic = null;
    if (S) snapCat();
    renderBg();
  }

  // Efter en drejning af skærmen: flyt katten hen, hvor den hører til.
  function snapCat() {
    if (cat.state === 'sleep') { cat.x = G.bed.x; cat.y = G.bed.y; return; }
    if (cat.state === 'eat') { cat.x = G.bowl.x + 78 * objScale(G.catY); cat.y = G.catY; return; }
    if (cat.state === 'poop') { cat.x = G.litter.x; cat.y = G.litter.y; return; }
    cat.x = clamp(cat.x || W * 0.55, G.minX, G.maxX);
    cat.y = G.catY;
    if (cat.walk) {
      const tag = cat.walk.tag;
      if (tag === 'bed') { cat.walk.x = G.bed.x; cat.walk.y = G.bed.y; }
      else if (tag === 'bowl') { cat.walk.x = G.bowl.x + 78 * objScale(G.catY); cat.walk.y = G.catY; }
      else if (tag === 'litter') { cat.walk.x = G.litter.x; cat.walk.y = G.litter.y; }
      else { cat.walk.x = clamp(cat.walk.x, G.minX, G.maxX); cat.walk.y = G.catY; }
    }
  }

  function renderBg() {
    bg.width = canvas.width; bg.height = canvas.height;
    const c = bgx;
    c.setTransform(DPR, 0, 0, DPR, 0, 0);
    const fy = G.floorY;
    // væg med striber
    c.fillStyle = '#FDF0DD'; c.fillRect(0, 0, W, fy);
    c.fillStyle = '#FAE4C8';
    const sw = 24 * U;
    for (let x = 0; x < W; x += sw * 2) c.fillRect(x, 0, sw, fy);
    // gulv med brædder
    const fg = c.createLinearGradient(0, fy, 0, H);
    fg.addColorStop(0, '#D99A5B'); fg.addColorStop(1, '#E9B47A');
    c.fillStyle = fg; c.fillRect(0, fy, W, H - fy);
    c.strokeStyle = 'rgba(140,80,30,0.22)'; c.lineWidth = 2;
    let y = fy, ph = 14 * U, row = 0;
    while (y < H) {
      const y2 = y + ph;
      c.beginPath(); c.moveTo(0, y2); c.lineTo(W, y2); c.stroke();
      for (let x = (row % 2) * 90 * U + 40 * U; x < W; x += 180 * U) { c.beginPath(); c.moveTo(x, y); c.lineTo(x, y2); c.stroke(); }
      y = y2; ph *= 1.18; row++;
    }
    // fodliste
    c.fillStyle = '#FFF7EA'; c.fillRect(0, fy - 12 * U, W, 12 * U);
    c.fillStyle = 'rgba(140,90,40,0.25)'; c.fillRect(0, fy - 1, W, 2);
    // tæppe
    c.fillStyle = '#A9DCD7'; ell(c, W * 0.55, H * 0.885, W * 0.3, H * 0.075); c.fill();
    c.strokeStyle = '#FFFFFF'; c.lineWidth = 3 * U; c.setLineDash([10 * U, 8 * U]);
    ell(c, W * 0.55, H * 0.885, W * 0.27, H * 0.058); c.stroke();
    c.setLineDash([]);
    drawSky(c);
    if (G.pic) drawPicture(c);
  }

  function drawSky(c) {
    const w = G.win, ph = skyNow, cols = SKY[ph], hills = HILLS[ph];
    const g = c.createLinearGradient(0, w.y, 0, w.y + w.h);
    g.addColorStop(0, cols[0]); g.addColorStop(1, cols[1]);
    c.fillStyle = g; c.fillRect(w.x, w.y, w.w, w.h);
    c.save();
    c.beginPath(); c.rect(w.x, w.y, w.w, w.h); c.clip();
    if (ph === 'night') {
      c.fillStyle = '#FFFFFF';
      for (let i = 0; i < 26; i++) {
        const fx = Math.abs(Math.sin(i * 12.9898) * 43758.5453) % 1;
        const fy = Math.abs(Math.sin(i * 78.233) * 12345.678) % 1;
        c.globalAlpha = 0.5 + (i % 3) * 0.2;
        circ(c, w.x + fx * w.w, w.y + fy * w.h * 0.7, (1 + (i % 3) * 0.6) * U); c.fill();
      }
      c.globalAlpha = 1;
      const mx = w.x + w.w * 0.72, my = w.y + w.h * 0.26;
      c.fillStyle = 'rgba(255,244,194,0.18)'; circ(c, mx, my, 30 * U); c.fill();
      c.fillStyle = '#FFF4C2'; circ(c, mx, my, 19 * U); c.fill();
      c.fillStyle = 'rgba(220,200,140,0.5)'; circ(c, mx - 6 * U, my - 4 * U, 4 * U); c.fill(); circ(c, mx + 6 * U, my + 6 * U, 3 * U); c.fill();
    } else if (ph === 'day') {
      const sx = w.x + w.w * 0.78, sy = w.y + w.h * 0.25;
      c.fillStyle = 'rgba(255,216,77,0.35)'; circ(c, sx, sy, 32 * U); c.fill();
      c.fillStyle = '#FFD84D'; circ(c, sx, sy, 21 * U); c.fill();
    } else {
      c.fillStyle = '#FFB347'; circ(c, w.x + w.w * (ph === 'dawn' ? 0.25 : 0.75), w.y + w.h * 0.74, 22 * U); c.fill();
    }
    c.fillStyle = hills[0]; ell(c, w.x + w.w * 0.25, w.y + w.h * 1.05, w.w * 0.55, w.h * 0.32); c.fill();
    c.fillStyle = hills[1]; ell(c, w.x + w.w * 0.8, w.y + w.h * 1.1, w.w * 0.6, w.h * 0.36); c.fill();
    c.restore();
  }

  function drawPicture(c) {
    const p = G.pic;
    c.strokeStyle = '#8B5A2B'; c.lineWidth = 2;
    c.beginPath(); c.moveTo(p.x + p.w * 0.3, p.y - 7 * U); c.lineTo(p.x + p.w / 2, p.y - 26 * U); c.lineTo(p.x + p.w * 0.7, p.y - 7 * U); c.stroke();
    c.fillStyle = '#8B5A2B'; circ(c, p.x + p.w / 2, p.y - 26 * U, 3 * U); c.fill();
    c.fillStyle = '#C98B4F'; rr(c, p.x - 7 * U, p.y - 7 * U, p.w + 14 * U, p.h + 14 * U, 6 * U); c.fill();
    c.fillStyle = '#DFF3FF'; c.fillRect(p.x, p.y, p.w, p.h);
    c.save();
    c.translate(p.x + p.w / 2 + 6 * U, p.y + p.h / 2 + 4 * U); c.scale(U, U);
    c.fillStyle = '#F4A259'; ell(c, 0, 0, 28, 15); c.fill();
    c.beginPath(); c.moveTo(-24, 0); c.lineTo(-44, -14); c.lineTo(-44, 14); c.closePath(); c.fill();
    c.fillStyle = '#FFFFFF'; circ(c, 14, -4, 5); c.fill();
    c.fillStyle = '#2B2027'; circ(c, 15, -4, 2.6); c.fill();
    c.strokeStyle = 'rgba(80,150,200,0.7)'; c.lineWidth = 2;
    circ(c, 34, -18, 4); c.stroke(); circ(c, 40, -30, 3); c.stroke();
    c.restore();
  }

  function cloud(c, x, y, s) {
    circ(c, x, y, 16 * s); c.fill();
    circ(c, x + 18 * s, y - 6 * s, 20 * s); c.fill();
    circ(c, x + 38 * s, y, 15 * s); c.fill();
    ell(c, x + 18 * s, y + 6 * s, 32 * s, 10 * s); c.fill();
  }
  function drawClouds(c) {
    if (skyNow === 'night') return;
    const w = G.win;
    c.save();
    c.beginPath(); c.rect(w.x, w.y, w.w, w.h); c.clip();
    c.fillStyle = skyNow === 'day' ? 'rgba(255,255,255,0.95)' : 'rgba(255,235,225,0.85)';
    for (let i = 0; i < 3; i++) {
      const span = w.w + 160 * U;
      const x = w.x - 80 * U + ((T * (8 + i * 3) * U + i * span / 3) % span);
      cloud(c, x, w.y + w.h * (0.2 + i * 0.18), U * (0.8 + i * 0.15));
    }
    c.restore();
  }

  function curtain(c, w, ry) {
    const sway = Math.sin(T * 0.8) * 3 * U;
    const x0 = w.x - 38 * U, x1 = w.x + w.w * 0.2, bot = w.y + w.h + 26 * U;
    const tieY = w.y + w.h * 0.55, tieX = w.x + w.w * 0.04;
    c.beginPath();
    c.moveTo(x0, ry);
    c.lineTo(x1, ry);
    c.quadraticCurveTo(x1 - w.w * 0.04 + sway, tieY - w.h * 0.25, tieX, tieY);
    c.quadraticCurveTo(tieX + w.w * 0.12 + sway, tieY + w.h * 0.25, x1 - w.w * 0.04, bot);
    c.lineTo(x0, bot);
    c.closePath();
    c.fillStyle = '#F6A9B8'; c.fill();
    c.strokeStyle = '#D9798F'; c.lineWidth = 2; c.stroke();
    c.strokeStyle = 'rgba(255,255,255,0.35)'; c.lineWidth = 3 * U;
    c.beginPath();
    c.moveTo(x0 + 14 * U, ry + 6 * U); c.lineTo(x0 + 14 * U, bot - 6 * U);
    c.moveTo(x0 + 30 * U, ry + 6 * U); c.lineTo(x0 + 30 * U, bot - 6 * U);
    c.stroke();
    c.fillStyle = '#E56B86'; ell(c, tieX + 4 * U, tieY, 9 * U, 6 * U); c.fill();
  }
  function drawWindow(c) {
    const w = G.win, f = 9 * U;
    c.strokeStyle = '#FFFFFF'; c.lineWidth = f;
    c.strokeRect(w.x, w.y, w.w, w.h);
    c.lineWidth = f * 0.55;
    c.beginPath();
    c.moveTo(w.x + w.w / 2, w.y); c.lineTo(w.x + w.w / 2, w.y + w.h);
    c.moveTo(w.x, w.y + w.h * 0.45); c.lineTo(w.x + w.w, w.y + w.h * 0.45);
    c.stroke();
    c.strokeStyle = 'rgba(160,120,80,0.35)'; c.lineWidth = 1.5;
    c.strokeRect(w.x - f / 2, w.y - f / 2, w.w + f, w.h + f);
    c.fillStyle = '#FFFFFF'; rr(c, w.x - 16 * U, w.y + w.h + f / 2 - 2, w.w + 32 * U, 12 * U, 4 * U); c.fill(); c.stroke();
    const ry = w.y - 24 * U;
    c.strokeStyle = '#B07D4F'; c.lineWidth = 6 * U;
    c.beginPath(); c.moveTo(w.x - 46 * U, ry); c.lineTo(w.x + w.w + 46 * U, ry); c.stroke();
    c.fillStyle = '#B07D4F'; circ(c, w.x - 48 * U, ry, 7 * U); c.fill(); circ(c, w.x + w.w + 48 * U, ry, 7 * U); c.fill();
    curtain(c, w, ry);
    c.save(); c.translate(2 * w.x + w.w, 0); c.scale(-1, 1); curtain(c, w, ry); c.restore();
  }

  // Et katte-ur, der viser det rigtige klokkeslæt.
  function drawClock(c) {
    const k = G.clock, r = k.r;
    const d = new Date();
    const h = d.getHours() % 12 + d.getMinutes() / 60, m = d.getMinutes() + d.getSeconds() / 60;
    c.save();
    c.translate(k.x, k.y);
    c.fillStyle = '#E07A5F';
    for (let s = -1; s <= 1; s += 2) {
      c.beginPath(); c.moveTo(s * r * 0.85, -r * 0.45); c.lineTo(s * r * 0.78, -r * 1.28); c.lineTo(s * r * 0.2, -r * 0.92); c.closePath(); c.fill();
    }
    c.fillStyle = '#FFFFFF'; c.strokeStyle = '#E07A5F'; c.lineWidth = 5 * U;
    circ(c, 0, 0, r); c.fill(); c.stroke();
    c.fillStyle = '#C9B8A8';
    for (let i = 0; i < 12; i++) { const a = i * TAU / 12; circ(c, Math.sin(a) * r * 0.78, -Math.cos(a) * r * 0.78, (i % 3 ? 1.6 : 2.8) * U); c.fill(); }
    c.strokeStyle = '#4A3B35'; c.lineCap = 'round';
    c.save(); c.rotate(h / 12 * TAU); c.lineWidth = 4 * U; c.beginPath(); c.moveTo(0, 0); c.lineTo(0, -r * 0.48); c.stroke(); c.restore();
    c.save(); c.rotate(m / 60 * TAU); c.lineWidth = 2.6 * U; c.beginPath(); c.moveTo(0, 0); c.lineTo(0, -r * 0.72); c.stroke(); c.restore();
    c.fillStyle = '#E07A5F'; circ(c, 0, 0, 3.5 * U); c.fill();
    c.restore();
  }

  function pawPrint(c, x, y, r) {
    ell(c, x, y, r, r * 0.85); c.fill();
    circ(c, x - r, y - r * 1.2, r * 0.42); c.fill();
    circ(c, x - r * 0.35, y - r * 1.6, r * 0.42); c.fill();
    circ(c, x + r * 0.35, y - r * 1.6, r * 0.42); c.fill();
    circ(c, x + r, y - r * 1.2, r * 0.42); c.fill();
  }
  function poo(c, x, y) {
    c.fillStyle = '#8B5A2B'; c.strokeStyle = '#5A3A1A'; c.lineWidth = 2;
    ell(c, x, y, 13, 6); c.fill(); c.stroke();
    ell(c, x, y - 6, 9, 5); c.fill(); c.stroke();
    ell(c, x + 1, y - 11, 5, 4); c.fill(); c.stroke();
    c.fillStyle = 'rgba(255,255,255,0.35)'; circ(c, x - 4, y - 7, 1.8); c.fill();
  }
  function drawLitterBack(c) {
    const b = G.litter, s = objScale(b.y);
    c.save(); c.translate(b.x, b.y); c.scale(s, s);
    c.fillStyle = 'rgba(90,55,30,0.15)'; ell(c, 0, 0, 88, 12); c.fill();
    c.fillStyle = '#5FB48F'; c.strokeStyle = '#2F7A5A'; c.lineWidth = 3;
    rr(c, -76, -74, 152, 40, 10); c.fill(); c.stroke();
    c.fillStyle = '#EAD9A6'; ell(c, 0, -44, 70, 13); c.fill();
    c.fillStyle = 'rgba(180,150,90,0.5)';
    for (let i = 0; i < 9; i++) { circ(c, -56 + i * 14, -44 + ((i * 7) % 5) - 2, 1.6); c.fill(); }
    const px = [-36, 4, 36], py = [-46, -50, -44];
    for (let i = 0; i < S.poop && i < 3; i++) poo(c, px[i], py[i]);
    c.restore();
  }
  function drawLitterFront(c) {
    const b = G.litter, s = objScale(b.y);
    c.save(); c.translate(b.x, b.y); c.scale(s, s);
    c.fillStyle = '#7CCBA6'; c.strokeStyle = '#2F7A5A'; c.lineWidth = 3;
    rr(c, -82, -42, 164, 42, 10); c.fill(); c.stroke();
    c.fillStyle = 'rgba(255,255,255,0.35)'; rr(c, -70, -36, 60, 6, 3); c.fill();
    c.fillStyle = 'rgba(47,122,90,0.45)'; pawPrint(c, 50, -16, 7);
    if (S.poop > 0) {
      c.strokeStyle = 'rgb(130,175,70)'; c.lineWidth = 3;
      for (let i = 0; i < Math.min(3, S.poop + 1); i++) {
        const x0 = -30 + i * 30, ph = (T * 0.8 + i * 0.33) % 1;
        c.globalAlpha = 0.8 * (1 - ph);
        c.beginPath();
        for (let j = 0; j <= 10; j++) {
          const yy = -60 - j * 5 - ph * 30, xx = x0 + Math.sin(j * 0.9 + T * 4 + i) * 5;
          if (j === 0) c.moveTo(xx, yy); else c.lineTo(xx, yy);
        }
        c.stroke();
      }
      c.globalAlpha = 1;
    }
    c.restore();
  }

  function drawBowl(c) {
    const b = G.bowl, s = objScale(b.y);
    c.save(); c.translate(b.x, b.y); c.scale(s, s);
    c.fillStyle = 'rgba(90,55,30,0.16)'; ell(c, 0, 0, 56, 9); c.fill();
    c.fillStyle = '#4FA3E0'; c.strokeStyle = '#2B6A9A'; c.lineWidth = 3;
    c.beginPath();
    c.moveTo(-50, -32); c.lineTo(50, -32); c.quadraticCurveTo(46, -2, 34, 0); c.lineTo(-34, 0); c.quadraticCurveTo(-46, -2, -50, -32);
    c.closePath(); c.fill(); c.stroke();
    c.fillStyle = '#FFFFFF'; c.font = '800 12px ' + FONT; c.textAlign = 'center'; c.textBaseline = 'middle';
    c.fillText(S.name.toUpperCase().slice(0, 10), 0, -15);
    c.fillStyle = '#86C7F2'; ell(c, 0, -32, 50, 10); c.fill(); c.stroke();
    c.fillStyle = '#2D6E9E'; ell(c, 0, -32, 42, 7); c.fill();
    if (bowl && bowl.amt > 0.02) {
      if (bowl.type === 'kibble') {
        const n = Math.ceil(14 * bowl.amt);
        for (let i = 0; i < n; i++) { c.fillStyle = i % 2 ? '#A0612F' : '#C47B3E'; circ(c, -32 + (i * 37) % 64, -34 - (i % 3) * 4, 5); c.fill(); }
      } else if (bowl.type === 'fish') {
        c.save(); c.translate(0, -38);
        c.beginPath(); c.rect(-46, -30, 92 * bowl.amt, 60); c.clip();
        c.fillStyle = '#9FB7C9'; c.strokeStyle = '#5E7A90'; c.lineWidth = 2;
        ell(c, 4, 0, 26, 10); c.fill(); c.stroke();
        c.beginPath(); c.moveTo(-20, 0); c.lineTo(-36, -10); c.lineTo(-36, 10); c.closePath(); c.fill(); c.stroke();
        c.fillStyle = '#2B2027'; circ(c, 20, -2, 2.4); c.fill();
        c.restore();
      } else {
        c.strokeStyle = '#FF8A80'; c.lineWidth = 7;
        for (let i = 0; i < Math.ceil(3 * bowl.amt); i++) { c.beginPath(); c.arc(-20 + i * 20, -40, 8, 0.2 * Math.PI, 1.4 * Math.PI); c.stroke(); }
      }
    }
    c.restore();
  }

  function drawBedBack(c) {
    const b = G.bed, s = objScale(b.y);
    c.save(); c.translate(b.x, b.y); c.scale(s, s);
    c.fillStyle = 'rgba(90,55,30,0.15)'; ell(c, 0, 0, 116, 16); c.fill();
    c.fillStyle = '#D29A5E'; c.strokeStyle = '#8B5A2B'; c.lineWidth = 3;
    ell(c, 0, -36, 112, 42); c.fill(); c.stroke();
    c.fillStyle = '#F4A6C6'; ell(c, 0, -38, 94, 28); c.fill();
    c.strokeStyle = 'rgba(200,100,140,0.5)'; c.lineWidth = 2; ell(c, 0, -38, 70, 18); c.stroke();
    c.restore();
  }
  function drawBedFront(c) {
    const b = G.bed, s = objScale(b.y);
    c.save(); c.translate(b.x, b.y); c.scale(s, s);
    c.beginPath();
    c.ellipse(0, -36, 112, 42, 0, 0, Math.PI, false);
    c.ellipse(0, -30, 98, 22, 0, Math.PI, 0, true);
    c.closePath();
    c.fillStyle = '#D9A468'; c.fill();
    c.strokeStyle = '#8B5A2B'; c.lineWidth = 3; c.stroke();
    c.strokeStyle = 'rgba(139,90,43,0.45)'; c.lineWidth = 2;
    for (let a = 0.12; a < 0.9; a += 0.07) {
      const ang = a * Math.PI;
      c.beginPath();
      c.moveTo(Math.cos(ang) * 99, -30 + Math.sin(ang) * 23);
      c.lineTo(Math.cos(ang) * 111, -36 + Math.sin(ang) * 41);
      c.stroke();
    }
    c.restore();
  }

  function drawFeather(c) {
    const s = U;
    const tipX = feather.x + 60 * s, tipY = Math.max(20 * s, feather.y - 180 * s);
    c.strokeStyle = '#B07D4F'; c.lineWidth = 7 * s; c.lineCap = 'round';
    c.beginPath(); c.moveTo(clamp(feather.x + 200 * s, 0, W + 40), -10); c.lineTo(tipX, tipY); c.stroke();
    c.strokeStyle = 'rgba(80,60,50,0.7)'; c.lineWidth = 2;
    c.beginPath(); c.moveTo(tipX, tipY);
    c.quadraticCurveTo((tipX + feather.x) / 2 + 10 * s, (tipY + feather.y) / 2 + 30 * s, feather.x, feather.y);
    c.stroke();
    c.save();
    c.translate(feather.x, feather.y); c.rotate(feather.ang); c.scale(s, s);
    c.fillStyle = '#FF7EB6'; ell(c, 0, 26, 11, 30); c.fill();
    c.fillStyle = '#7AD3F0'; ell(c, -10, 30, 7, 22, 0.35); c.fill(); ell(c, 10, 30, 7, 22, -0.35); c.fill();
    c.strokeStyle = '#FFFFFF'; c.lineWidth = 2; c.beginPath(); c.moveTo(0, -2); c.lineTo(0, 54); c.stroke();
    c.fillStyle = '#FFD23F'; circ(c, 0, -2, 6); c.fill();
    c.restore();
  }

  function drawSponge(c) {
    c.save();
    c.translate(sponge.x, sponge.y);
    c.rotate(-0.25 + (cat.scrubT > 0 ? Math.sin(T * 30) * 0.12 : 0));
    c.scale(U, U);
    c.fillStyle = '#FFD84D'; c.strokeStyle = '#C9A21E'; c.lineWidth = 3;
    rr(c, -34, -22, 68, 44, 12); c.fill(); c.stroke();
    c.fillStyle = '#5BC57A'; rr(c, -34, -22, 68, 14, 8); c.fill(); c.stroke();
    c.fillStyle = '#E8BE2E';
    circ(c, -16, 4, 4); c.fill(); circ(c, 4, 10, 3); c.fill(); circ(c, 18, 2, 4.5); c.fill(); circ(c, -4, -2, 2.5); c.fill();
    c.restore();
  }

  function drawDark(c) {
    const w = G.win;
    c.fillStyle = 'rgba(14,18,48,0.62)';
    c.beginPath(); c.rect(0, 0, W, H); c.rect(w.x, w.y, w.w, w.h); c.fill('evenodd');
    c.fillStyle = 'rgba(200,210,255,0.06)';
    c.beginPath();
    c.moveTo(w.x, w.y + w.h); c.lineTo(w.x + w.w, w.y + w.h); c.lineTo(w.x + w.w * 1.5, H); c.lineTo(w.x + w.w * 0.1, H);
    c.closePath(); c.fill();
  }

  function bubblePath(c, x, y, w, h, r, tx) {
    c.beginPath();
    c.moveTo(x + r, y);
    c.lineTo(x + w - r, y); c.quadraticCurveTo(x + w, y, x + w, y + r);
    c.lineTo(x + w, y + h - r); c.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    c.lineTo(tx + 11, y + h); c.lineTo(tx, y + h + 14); c.lineTo(tx - 11, y + h);
    c.lineTo(x + r, y + h); c.quadraticCurveTo(x, y + h, x, y + h - r);
    c.lineTo(x, y + r); c.quadraticCurveTo(x, y, x + r, y);
    c.closePath();
  }
  function drawBubble(c) {
    if (!bubble) return;
    const s = catScale(), st = STAGES[S.stage];
    let ax, ay;
    if (cat.state === 'sleep') { ax = cat.x - 40 * s; ay = cat.y - 120 * s; }
    else { const hp = catHeadPos(); ax = hp.x; ay = hp.y - 72 * st.head * s; }
    const fs = Math.round(clamp(22 * U, 17, 30));
    c.font = '700 ' + fs + 'px ' + FONT;
    const tw = c.measureText(bubble.text).width;
    const bw = tw + fs * 1.4, bh = fs * 2;
    const bx = clamp(ax - bw / 2, 8, W - bw - 8);
    const by = Math.max(6, ay - bh - 16);
    const age = bubble.d - bubble.t;
    const pop = 0.85 + 0.15 * clamp(age * 6, 0, 1);
    c.save();
    c.globalAlpha = clamp(Math.min(age * 6, bubble.t * 3), 0, 1);
    c.translate(ax, by + bh); c.scale(pop, pop); c.translate(-ax, -(by + bh));
    bubblePath(c, bx, by, bw, bh, 16, clamp(ax, bx + 18, bx + bw - 18));
    c.fillStyle = '#FFFFFF'; c.fill();
    c.strokeStyle = '#5A4A42'; c.lineWidth = 2.5; c.stroke();
    c.fillStyle = '#4A3B35'; c.textAlign = 'center'; c.textBaseline = 'middle';
    c.fillText(bubble.text, bx + bw / 2, by + bh / 2 + 1);
    c.restore();
  }

  function catLift() {
    if (cat.jump) { const p = clamp(cat.jump.t / cat.jump.dur, 0, 1); return cat.jump.h * 4 * p * (1 - p); }
    if (cat.hop > 0) return Math.sin((1 - cat.hop / 0.35) * Math.PI) * 16 * U;
    if (cat.state === 'walk' || cat.moving) return Math.abs(Math.sin(cat.t * 11)) * 4 * U;
    return 0;
  }
  function catHeadPos() {
    const s = catScale(), st = STAGES[S.stage];
    return { x: cat.x, y: cat.y - catLift() - 118 * st.body * s };
  }

  function drawTheCat(c) {
    const s = catScale();
    const dirt = clamp((45 - S.needs.clean) / 45, 0, 1);
    if (cat.state === 'sleep') {
      drawSleepingCat(c, { x: cat.x + 6 * U, y: cat.y - 24 * objScale(cat.y), s: s, coat: S.coat, stage: S.stage, wear: S.wear, t: T, dirt: dirt });
      return;
    }
    const mood = moodOf();
    const walking = cat.state === 'walk' || (cat.state === 'play' && cat.moving);
    let eyes = 'open', mouthKind = 'w', lid = 0, blush = mood === 'happy', tear = false;
    let lookX = cat.look, lookY = 0, tilt = Math.sin(cat.t * 1.4) * 0.04;
    if (mood === 'sad') { eyes = 'sad'; mouthKind = 'sad'; tear = minNeed() < 6; }
    else if (mood === 'meh') mouthKind = 'flat';
    if (S.needs.energy < 25) lid = 0.45;
    if (cat.petT > 0 || cat.scrubT > 0 || cat.happyT > 0) { eyes = 'happy'; mouthKind = 'w'; blush = true; lid = 0; tear = false; }
    if (cat.state === 'eat') { eyes = 'happy'; mouthKind = Math.floor(cat.t * 6) % 2 ? 'open' : 'w'; tilt = -0.22; lookX = -1; }
    else if (cat.state === 'poop') { eyes = 'closed'; mouthKind = 'flat'; }
    else if (cat.state === 'play') {
      eyes = 'wide'; lid = 0; mouthKind = cat.jump ? 'open' : 'w';
      const hp = catHeadPos();
      lookX = clamp((feather.x - hp.x) / (120 * U), -1, 1);
      lookY = clamp((feather.y - hp.y) / (120 * U), -1, 1);
      tilt = clamp((feather.x - cat.x) / (600 * U), -0.25, 0.25);
    }
    if (cat.mouthT > 0) mouthKind = 'open';
    if (cat.blink > 0 && (eyes === 'open' || eyes === 'wide' || eyes === 'sad')) eyes = 'blink';
    if (walking) tilt += Math.sin(cat.t * 10) * 0.05;
    drawCat(c, {
      x: cat.x, y: cat.y, s: s, coat: S.coat, stage: S.stage, eyes: eyes, lid: lid, mouth: mouthKind,
      blush: blush, tear: tear, tilt: tilt, tail: cat.tail, lookX: lookX, lookY: lookY, wear: S.wear,
      dirt: dirt, pawsUp: !!cat.jump, lift: catLift(), step: walking ? Math.sin(cat.t * 10) : 0
    });
    if (S.needs.clean < 20) { const hp = catHeadPos(); drawFlies(c, hp.x, hp.y, s); }
  }

  function draw() {
    const c = ctx;
    c.setTransform(1, 0, 0, 1, 0, 0);
    c.drawImage(bg, 0, 0);
    c.setTransform(DPR, 0, 0, DPR, 0, 0);
    drawClouds(c);
    drawWindow(c);
    drawClock(c);
    const list = [
      { y: G.litter.y - 0.5, f: drawLitterBack }, { y: G.litter.y + 0.5, f: drawLitterFront },
      { y: G.bowl.y, f: drawBowl },
      { y: G.bed.y - 0.5, f: drawBedBack }, { y: G.bed.y + 0.5, f: drawBedFront },
      { y: cat.y, f: drawTheCat }
    ];
    list.sort((a, b) => a.y - b.y);
    for (let i = 0; i < list.length; i++) list[i].f(c);
    if (mode === 'play') drawFeather(c);
    if (mode === 'wash') drawSponge(c);
    if (S.lightsOff) drawDark(c);
    drawParts(c);
    drawBubble(c);
  }

  // ================================================================ kattens opførsel
  function goTo(x, y, after, speed, tag) {
    cat.walk = { x: x, y: y, after: after || null, speed: speed || 1, tag: tag || null };
    cat.state = 'walk';
  }

  function updateCat(dt) {
    cat.t += dt;
    cat.tail += dt * ((cat.state === 'walk' || cat.state === 'play') ? 5 : 1.8);
    cat.blinkT -= dt;
    if (cat.blinkT <= 0) { cat.blink = 0.15; cat.blinkT = rand(2.5, 5.5); }
    if (cat.blink > 0) cat.blink -= dt;
    if (cat.hop > 0) cat.hop -= dt;
    if (cat.happyT > 0) cat.happyT -= dt;
    if (cat.scrubT > 0) cat.scrubT -= dt;
    if (cat.mouthT > 0) cat.mouthT -= dt;
    if (cat.petT > 0) { cat.petT -= dt; if (cat.petT <= 0) stopPurr(); }

    // lyset er slukket: katten går i seng
    if (S.lightsOff && cat.state !== 'sleep' && !(cat.walk && cat.walk.tag === 'bed')) {
      cat.jump = null; bowl = null;
      goTo(G.bed.x, G.bed.y, () => { if (S.lightsOff) { cat.state = 'sleep'; cat.zT = 0.5; } }, 1, 'bed');
    }
    if (mode === 'normal' && cat.state !== 'sleep') poopClock += dt;

    switch (cat.state) {
      case 'walk': {
        const w = cat.walk;
        if (!w) { cat.state = 'idle'; break; }
        const dx = w.x - cat.x, dy = w.y - cat.y;
        const d = Math.sqrt(dx * dx + dy * dy);
        const sp = 170 * U * w.speed * dt;
        if (d <= sp) {
          cat.x = w.x; cat.y = w.y; cat.walk = null;
          cat.state = 'idle'; cat.timer = rand(2, 5);
          if (w.after) w.after();
        } else {
          cat.x += dx / d * sp; cat.y += dy / d * sp;
          cat.look = dx > 0 ? 0.8 : -0.8;
        }
        break;
      }
      case 'idle':
        cat.timer -= dt;
        if (mode === 'normal' && cat.timer <= 0 && cat.petT <= 0) {
          if (S.poop < 3 && poopClock >= POOP_EVERY && S.needs.food > 20) {
            poopClock = 0;
            goTo(G.litter.x, G.litter.y, () => { if (mode === 'normal' && !S.lightsOff) { cat.state = 'poop'; cat.timer = 2.6; } }, 0.9, 'litter');
          } else if (Math.random() < 0.55) {
            goTo(rand(G.minX, G.maxX), G.catY, null, 0.55);
          } else {
            cat.timer = rand(2, 5);
            cat.look = rand(-1, 1);
          }
        }
        break;
      case 'eat':
        cat.timer -= dt;
        cat.eatT -= dt;
        if (bowl) bowl.amt = clamp(cat.timer / 3.2, 0, 1);
        if (cat.eatT <= 0) {
          cat.eatT = 0.4;
          nomSound();
          spawn('text', cat.x - 50 * U, cat.y - 130 * U, { text: pick(['nam', 'nam!', 'mmm']), vy: -40, vx: rand(-20, 10), life: 0.9, size: 18 * U });
        }
        if (cat.timer <= 0) finishEating();
        break;
      case 'poop':
        cat.timer -= dt;
        if (cat.timer <= 0) {
          if (S.poop < 3) S.poop++;
          plopSound();
          say(pick(['Puh! 💩', 'Hihi… 💩', 'Så er det gjort! 💩']), 2);
          goTo(G.litter.x + 190 * U, G.catY, null, 0.9);
        }
        break;
      case 'sleep':
        cat.x = G.bed.x; cat.y = G.bed.y;
        cat.zT -= dt;
        if (cat.zT <= 0) {
          cat.zT = 1.3;
          const s = catScale();
          spawn('zzz', cat.x - 50 * s, cat.y - 100 * s, { vx: 14, vy: -26, life: 2.4, size: 18 * U });
        }
        if (!S.lightsOff) wakeUp(false);
        else if (S.needs.energy >= 100 && !isNightAt(now())) {
          S.lightsOff = false;
          if (cat.sleepHeart) { cat.sleepHeart = false; addHearts(1); }
          wakeUp(true);
          updateHud();
        }
        break;
      case 'play':
        updatePlay(dt);
        break;
      default:
        break;
    }

    // katten siger til, hvad den mangler
    cat.needT -= dt;
    if (cat.needT <= 0) {
      cat.needT = rand(16, 28);
      if (mode === 'normal' && !S.lightsOff && !bubble && (cat.state === 'idle' || cat.state === 'walk')) {
        const line = needLine();
        if (line) meowSay(line);
        else if (Math.random() < 0.4) say(pick(HAPPY_LINES), 2.6);
      }
    }
    if (modeEndT > 0) {
      modeEndT -= dt;
      if (modeEndT <= 0 && mode !== 'normal') setMode('normal');
    }
  }

  function wakeUp(rested) {
    cat.state = 'idle';
    cat.x = G.bed.x; cat.y = G.bed.y;
    goTo(G.bed.x - 160 * U, G.catY, null, 0.8);
    meowSay(rested ? 'Godmorgen! Jeg er udhvilet ☀️' : pick(['Miav? Er det morgen?', 'Gaab… hej! 😺']));
  }

  function tapCat() {
    if (S.lightsOff) { say('Zzz…', 1.5); return; }
    if (cat.state === 'idle' || cat.state === 'walk') cat.hop = 0.35;
    cat.happyT = 0.8;
    meowSay(needLine() || pick(['Miav! ❤️', 'Miav!', 'Purr… 😺', 'Hej med dig!']));
  }

  function pet(p, d) {
    if (cat.state === 'walk' && cat.walk && !cat.walk.tag) { cat.walk = null; cat.state = 'idle'; }
    if (cat.state !== 'idle') return;
    cat.petT = 0.5;
    cat.timer = Math.max(cat.timer, 2.5);
    startPurr();
    if (S.needs.fun < 100) S.needs.fun = Math.min(100, S.needs.fun + d * 0.012);
    heartAcc += d;
    if (heartAcc > 70) { heartAcc = 0; spawn('heart', p.x + rand(-10, 10), p.y - 10, { vy: -70, vx: rand(-15, 15), life: 1.2, size: rand(8, 12) * U }); }
    petAcc += d;
    if (petAcc > 900) { petAcc = 0; if (S.needs.fun < 99.9) addHearts(1, p.x, p.y - 30); }
  }

  // ---- mad
  function feed(type) {
    const f = FOODS[type];
    if (S.needs.food >= 96) { meowSay('Jeg er helt mæt! 😸'); return; }
    if (f.treat) {
      const t = now();
      S.treats = S.treats.filter(x => t - x < 15 * 60000);
      if (S.treats.length >= 3) { meowSay('Ikke flere godbidder lige nu 😸'); return; }
      S.treats.push(t);
    }
    bowl = { type: type, amt: 1 };
    cat.jump = null;
    goTo(G.bowl.x + 78 * objScale(G.catY), G.catY, () => {
      if (bowl) { cat.state = 'eat'; cat.timer = 3.2; cat.eatT = 0; }
    }, 1.2, 'bowl');
  }
  function finishEating() {
    cat.state = 'idle'; cat.timer = rand(2, 4);
    if (!bowl) return;
    const f = FOODS[bowl.type];
    const needed = S.needs.food < 85;
    S.needs.food += f.food; S.needs.fun += f.fun;
    clampNeeds();
    bowl = null;
    if (needed || f.treat) addHearts(1, G.bowl.x, G.bowl.y - 60 * U);
    meowSay(pick(['Nam nam! Tak! 😸', 'Mmm, det smagte godt!', 'Tak for mad! ❤️']));
  }

  // ---- leg med fjeren
  function startPlay() {
    if (S.needs.energy < 12) { meowSay('Jeg er for træt til at lege… 💤'); return; }
    setMode('play');
    bowl = null;
    cat.walk = null; cat.jump = null; cat.state = 'play'; cat.cool = 0.8;
    feather.x = feather.tx = clamp(cat.x + 160 * U, 60, W - 60);
    feather.y = feather.ty = G.catY - 240 * U;
    feather.held = 0; feather.catches = 0;
    setHint('Træk fjeren rundt – kan ' + S.name + ' fange den?');
  }
  function featherCenter() { return { x: feather.x, y: feather.y + 26 * U }; }
  function updatePlay(dt) {
    if (feather.held > 0) {
      feather.held -= dt;
      const hp = catHeadPos();
      feather.x = hp.x + 18 * U; feather.y = hp.y + 10 * U;
      feather.ang = -0.5;
      if (feather.held <= 0) {
        feather.tx = clamp(cat.x + (Math.random() < 0.5 ? -1 : 1) * 190 * U, 50, W - 50);
        feather.ty = G.catY - 300 * U;
      }
    } else {
      const k = Math.min(1, dt * 12), ox = feather.x;
      feather.x += (feather.tx - feather.x) * k;
      feather.y += (feather.ty - feather.y) * k;
      const vx = (feather.x - ox) / Math.max(dt, 0.001);
      feather.ang = lerp(feather.ang, clamp(-vx * 0.0025, -0.9, 0.9) + Math.sin(T * 3) * 0.15, Math.min(1, dt * 8));
    }
    const s = catScale(), st = STAGES[S.stage];
    cat.cool -= dt;
    if (cat.jump) {
      const j = cat.jump;
      j.t += dt;
      cat.x = clamp(cat.x + j.vx * dt, G.minX, G.maxX);
      if (!j.checked && j.t >= j.dur / 2) {
        j.checked = true;
        const hp = catHeadPos(), fc = featherCenter();
        const dist = Math.sqrt((fc.x - hp.x) * (fc.x - hp.x) + (fc.y - hp.y) * (fc.y - hp.y));
        if (feather.held <= 0 && dist < 105 * s) caught();
        else if (Math.random() < 0.35) say(pick(['Næsten!', 'Hov!', 'Den slap væk!']), 1.4);
      }
      if (j.t >= j.dur) { cat.jump = null; cat.cool = 0.9; }
      cat.moving = false;
    } else {
      const tx = clamp(feather.x, G.minX, G.maxX), dx = tx - cat.x, sp = 330 * U * dt;
      cat.moving = Math.abs(dx) > 6;
      if (cat.moving) cat.x += clamp(dx, -sp, sp);
      cat.y += (G.catY - cat.y) * Math.min(1, dt * 6);
      const fc = featherCenter();
      if (cat.cool <= 0 && feather.held <= 0 && Math.abs(fc.x - cat.x) < 90 * U && fc.y < cat.y - 50 * s && fc.y > cat.y - 340 * s) {
        const headY = cat.y - 118 * st.body * s;
        cat.jump = { t: 0, dur: 0.62, checked: false, h: clamp(headY - fc.y + 10 * s, 20 * U, 170 * U), vx: clamp((fc.x - cat.x) / 0.31, -260 * U, 260 * U) };
        jumpSound();
      }
    }
  }
  function caught() {
    feather.catches++;
    feather.held = 0.7;
    S.needs.fun = Math.min(100, S.needs.fun + 7);
    S.needs.energy = Math.max(0, S.needs.energy - 2.5);
    if (feather.catches % 2 === 0) addHearts(1, cat.x, cat.y - 220 * U);
    else chime();
    burst('sparkle', feather.x, feather.y + 20 * U, 8, 160 * U, { life: 0.8, size: 9 * U });
    say(pick(['Fanget! 🎉', 'Jeg fangede den!', 'Hihi! 😸', 'Mere, mere!']), 1.6);
    if (S.needs.energy < 8) { modeEndT = 1.8; say('Puh… nu er jeg træt 💤', 2.5); }
  }

  // ---- vask
  function startWash() {
    if (S.needs.clean >= 97 && S.poop === 0) { meowSay('Jeg er allerede helt ren! ✨'); return; }
    setMode('wash');
    washGain = 0; washDone = false; bowl = null; cat.jump = null;
    sponge.x = W * 0.55 - 170 * U; sponge.y = G.catY - 70 * U;
    goTo(W * 0.55, G.catY, () => { if (mode === 'wash') cat.state = 'wash'; }, 1.1, 'wash');
    setHint(S.poop > 0 ? 'Skrub ' + S.name + ' med svampen – og tryk på kattebakken!' : 'Skrub ' + S.name + ' med svampen!');
  }
  function scrub(p, d) {
    cat.scrubT = 0.4;
    const before = S.needs.clean;
    S.needs.clean = Math.min(100, S.needs.clean + d * 0.07);
    washGain += S.needs.clean - before;
    if (washGain >= 25) { washGain -= 25; addHearts(1, p.x, p.y - 30); }
    bubAcc += d;
    while (bubAcc > 14) {
      bubAcc -= 14;
      spawn('bubble', p.x + rand(-26, 26) * U, p.y + rand(-18, 18) * U, { vx: rand(-20, 20), vy: rand(-45, -10), life: rand(0.7, 1.5), size: rand(5, 12) * U });
      if (Math.random() < 0.25) popSound();
    }
    if (S.needs.clean >= 100 && !washDone) {
      washDone = true;
      meowSay('Skinnende ren! ✨', 2.6);
      burst('sparkle', cat.x, cat.y - 120 * U, 14, 160 * U, { life: 1, size: 9 * U });
      if (S.poop === 0) modeEndT = 1.8;
    }
  }
  function scoop() {
    if (S.poop <= 0) return false;
    S.poop--;
    S.needs.clean = Math.min(100, S.needs.clean + 4);
    scoopSound();
    const s = objScale(G.litter.y);
    burst('sparkle', G.litter.x, G.litter.y - 50 * s, 8, 120 * U, { life: 0.8, size: 8 * U });
    addHearts(1, G.litter.x, G.litter.y - 80 * s);
    if (S.poop === 0) {
      say('Tak! Nu er kattebakken ren 😸', 2.5);
      if (mode === 'wash' && S.needs.clean >= 99) modeEndT = 1.8;
    }
    return true;
  }

  // ---- søvn
  function toggleLights() {
    if (mode !== 'normal') return;
    S.lightsOff = !S.lightsOff;
    if (S.lightsOff) {
      bowl = null;
      cat.sleepHeart = S.needs.energy < 50;
      if (S.needs.energy > 85 && !isNightAt(now())) meowSay('Jeg er ikke så træt… men okay 😴');
      else meowSay('Godnat! 💤');
    } else if (cat.state === 'sleep') {
      wakeUp(false);
    }
    updateHud();
    save();
  }

  // ---- tilstande
  function setMode(m) {
    mode = m;
    $('actions').classList.toggle('hidden', m !== 'normal');
    $('modebar').classList.toggle('hidden', m === 'normal');
    if (m === 'normal') {
      cat.jump = null; cat.moving = false; modeEndT = 0;
      if (cat.walk && cat.walk.tag === 'wash') { cat.walk = null; cat.state = 'idle'; }
      if (cat.state === 'play' || cat.state === 'wash') { cat.state = 'idle'; cat.timer = 2; }
    }
  }
  function setHint(text) { $('modeHint').textContent = text; }

  function checkStage(celebrate) {
    const st = stageFor(S.born, now());
    if (st > S.stage) {
      S.stage = st;
      if (celebrate) {
        toast(S.name + ' er blevet til en ' + STAGES[st].name.toLowerCase() + '! 🎉');
        say('Se, jeg er blevet større! 🎉', 4);
        fanfare();
        addHearts(5);
        burst('sparkle', cat.x, cat.y - 150 * U, 20, 220 * U, { life: 1.2, size: 10 * U });
      }
    }
  }
  function dailyBonus() {
    const k = dayKey(now());
    if (S.bonusDay !== k) { S.bonusDay = k; toast('Dagens gave: +3 ❤️'); addHearts(3); }
  }
  function afterAway(away) {
    checkStage(true);
    dailyBonus();
    if (S.lightsOff && !isNightAt(now()) && S.needs.energy >= 60) {
      S.lightsOff = false;
      if (cat.state === 'sleep') wakeUp(true);
    }
    if (away > 6 * 3600000) meowSay('Der er du! Jeg har savnet dig ❤️', 3.5);
    else if (away > 20 * 60000) meowSay(pick(['Hej igen! 🐾', 'Miav! Der er du!']));
    updateHud();
  }

  // ================================================================ hovedløkken
  function update(dt) {
    T += dt;
    const t = now();
    const gap = (t - S.last) / 1000;
    if (gap > 8) afterAway(catchUp());
    else if (gap > 0) liveTick(gap, cat.state === 'sleep');
    S.last = t;
    stageT -= dt;
    if (stageT <= 0) { stageT = 5; checkStage(true); dailyBonus(); }
    skyT -= dt;
    if (skyT <= 0) { skyT = 30; const ph = skyPhase(t); if (ph !== skyNow) { skyNow = ph; renderBg(); } }
    updateCat(dt);
    updateParts(dt);
    if (bubble) { bubble.t -= dt; if (bubble.t <= 0) bubble = null; }
    saveT -= dt;
    if (saveT <= 0) { saveT = 5; save(); }
    hudT -= dt;
    if (hudT <= 0) { hudT = 0.25; updateHud(); }
  }

  let lastTs = 0, perfN = 0, perfSum = 0;
  function frame(ts) {
    requestAnimationFrame(frame);
    if (!lastTs) lastTs = ts;
    let dt = (ts - lastTs) / 1000;
    lastTs = ts;
    if (dt > 0.1) dt = 0.1;
    if (dt < 0) dt = 0;
    if (!S || W < 2) return;
    const t0 = performance.now();
    update(dt);
    draw();
    // Bruger den gamle iPad for lang tid på at tegne, tegner vi i lavere opløsning.
    if (perfN >= 0) {
      perfN++; perfSum += performance.now() - t0;
      if (perfN === 120) { if (perfSum / perfN > 12 && DPR > 1) { DPR = 1; layout(); } perfN = -1; }
    }
  }

  // ================================================================ knapper og skærme
  function setTxt(el, v) { if (el._v !== v) { el._v = v; el.textContent = v; } }
  function meterSet(key, v) {
    const f = $('m' + key), m = $('mt' + key);
    const w = Math.round(v) + '%';
    if (f._w !== w) { f._w = w; f.style.width = w; }
    const col = v > 60 ? '#5BC57A' : (v > 30 ? '#F2C14E' : '#EF6F6C');
    if (f._c !== col) { f._c = col; f.style.backgroundColor = col; }
    const low = v < 25;
    if (m._low !== low) { m._low = low; m.classList.toggle('low', low); }
  }
  function hasNewItems() { return ITEMS.some(it => it.cost > S.seenHearts && it.cost <= S.hearts); }
  function updateHud() {
    if (!S) return;
    const n = S.needs;
    meterSet('Food', n.food); meterSet('Fun', n.fun); meterSet('Energy', n.energy); meterSet('Clean', n.clean);
    setTxt($('catName'), S.name);
    setTxt($('heartNum'), String(S.hearts));
    setTxt($('stageLbl'), STAGES[S.stage].name + ' · dag ' + (Math.floor((now() - S.born) / 86400000) + 1));
    setTxt($('sleepIco'), S.lightsOff ? '☀️' : '🌙');
    setTxt($('sleepLbl'), S.lightsOff ? 'Tænd lys' : 'Sov');
    setTxt($('soundBtn'), S.sound ? '🔊' : '🔇');
    ['bFood', 'bPlay', 'bWash'].forEach(id => $(id).classList.toggle('off', S.lightsOff));
    $('dressBadge').classList.toggle('hidden', !hasNewItems());
  }

  function show(id) { $(id).classList.remove('hidden'); }
  function hide(id) { $(id).classList.add('hidden'); }
  function tapBtn(el, fn) {
    if (typeof el === 'string') el = $(el);
    el.addEventListener('click', e => { e.preventDefault(); unlockAudio(); clickSound(); fn(e); });
  }
  function shh() { toast(S.name + ' sover… tænd lyset først ☀️'); }

  function openFood() {
    if (mode !== 'normal' || S.lightsOff) return;
    $('foodTitle').textContent = 'Hvad skal ' + S.name + ' have?';
    show('foodSheet');
  }

  function openDress() {
    if (mode !== 'normal') return;
    const grid = $('dressGrid');
    grid.innerHTML = '';
    $('dressInfo').textContent = 'Du har ' + S.hearts + ' ❤️. Pas godt på ' + S.name + ', så får du flere.';
    ITEMS.forEach(it => {
      const unlocked = S.hearts >= it.cost, worn = S.wear[it.slot] === it.id;
      const b = document.createElement('button');
      b.className = 'opt' + (unlocked ? '' : ' locked') + (worn ? ' on' : '');
      const e = document.createElement('span'); e.className = 'e'; e.textContent = it.icon; b.appendChild(e);
      b.appendChild(document.createTextNode(it.name));
      const sm = document.createElement('small');
      sm.textContent = unlocked ? (worn ? 'Tag af' : 'Tag på') : '🔒 ' + it.cost + ' ❤️';
      b.appendChild(sm);
      tapBtn(b, () => {
        if (!unlocked) { toast('Du skal have ' + it.cost + ' ❤️ for at få ' + it.name.toLowerCase()); return; }
        S.wear[it.slot] = worn ? null : it.id;
        save();
        cat.happyT = 1.2;
        if (!worn) meowSay(pick(['Er jeg ikke fin? 😸', 'Den er flot!', 'Tak! ❤️']));
        openDress();
      });
      grid.appendChild(b);
    });
    S.seenHearts = Math.max(S.seenHearts, S.hearts);
    if (!S.lightsOff && (cat.state === 'idle' || (cat.walk && !cat.walk.tag))) goTo(clamp(W * 0.68, G.minX, G.maxX), G.catY, null, 1);
    show('dress');
    updateHud();
  }

  let chosenCoat = 'orange';
  function showStart() {
    const grid = $('coatGrid');
    grid.innerHTML = '';
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    COAT_ORDER.forEach(id => {
      const b = document.createElement('button');
      b.className = 'opt coat' + (id === chosenCoat ? ' on' : '');
      const cv = document.createElement('canvas');
      cv.width = 110 * dpr; cv.height = 110 * dpr;
      const c = cv.getContext('2d');
      c.scale(dpr, dpr);
      drawCat(c, { x: 53, y: 104, s: 0.56, coat: id, stage: 0, eyes: 'open', mouth: 'w', blush: true, tail: 0.6, noShadow: true, wear: {} });
      b.appendChild(cv);
      const l = document.createElement('span'); l.className = 'l'; l.textContent = COATS[id].label; b.appendChild(l);
      tapBtn(b, () => { chosenCoat = id; each(grid.children, x => x.classList.toggle('on', x === b)); });
      grid.appendChild(b);
    });
    show('start');
  }

  function startGame(isNew) {
    hide('start');
    skyNow = skyPhase(now());
    layout();
    cat.state = 'idle'; cat.timer = 2; cat.walk = null; cat.jump = null;
    cat.x = W * 0.55; cat.y = G.catY;
    if (S.lightsOff) { cat.x = G.bed.x; cat.y = G.bed.y; cat.state = 'sleep'; cat.zT = 1; }
    if (isNew) {
      meowSay('Hej! Jeg hedder ' + S.name + '! 🐾', 4);
      setTimeout(() => toast('Tip: Stryg over ' + S.name + ' for at kæle 🐾'), 4500);
    } else {
      afterAway(catchUp());
    }
    updateHud();
    save();
  }

  let pAns = 0, resetArmed = false;
  function openParent() {
    const a = 6 + Math.floor(Math.random() * 4), b = 12 + Math.floor(Math.random() * 8);
    pAns = a * b;
    $('pQ').textContent = 'Hvad er ' + a + ' × ' + b + '?';
    $('pA').value = '';
    $('pGate').classList.remove('hidden');
    $('pMenu').classList.add('hidden');
    resetArmed = false;
    show('parent');
  }
  function fillParentMenu() {
    const days = Math.floor((now() - S.born) / 86400000);
    $('pInfo').textContent = S.name + ' er ' + days + (days === 1 ? ' dag' : ' dage') + ' gammel og har samlet ' + S.hearts + ' hjerter.';
    $('pSound').textContent = 'Lyd: ' + (S.sound ? 'til 🔊' : 'fra 🔇');
    $('pReset').textContent = resetArmed ? 'Er du sikker? Tryk igen for at slette ' + S.name : 'Start forfra med en ny kat';
  }

  function buildUi() {
    tapBtn('bFood', () => { if (S.lightsOff) shh(); else openFood(); });
    tapBtn('bPlay', () => { if (S.lightsOff) shh(); else if (mode === 'normal') startPlay(); });
    tapBtn('bWash', () => { if (S.lightsOff) shh(); else if (mode === 'normal') startWash(); });
    tapBtn('bSleep', toggleLights);
    tapBtn('bDress', openDress);
    tapBtn('doneBtn', () => setMode('normal'));
    tapBtn('soundBtn', () => { S.sound = !S.sound; if (!S.sound) stopPurr(); updateHud(); save(); });
    each(document.querySelectorAll('[data-food]'), b => tapBtn(b, () => { hide('foodSheet'); feed(b.getAttribute('data-food')); }));
    each(document.querySelectorAll('[data-close]'), b => tapBtn(b, () => hide(b.getAttribute('data-close'))));
    each(document.querySelectorAll('.sheet'), sh => sh.addEventListener('click', e => { if (e.target === sh) hide(sh.id); }));

    tapBtn('startBtn', () => {
      const nm = ($('nameInput').value || '').replace(/\s+/g, ' ').trim().slice(0, 14) || 'Mis';
      $('nameInput').blur();
      S = freshState(nm, chosenCoat);
      save();
      startGame(true);
    });
    $('nameInput').addEventListener('blur', () => window.scrollTo(0, 0));
    $('pA').addEventListener('blur', () => window.scrollTo(0, 0));

    tapBtn('pOk', () => {
      if (parseInt($('pA').value, 10) === pAns) {
        $('pA').blur();
        $('pGate').classList.add('hidden');
        fillParentMenu();
        $('pMenu').classList.remove('hidden');
      } else { $('pA').value = ''; toast('Forkert svar'); }
    });
    tapBtn('pSound', () => { S.sound = !S.sound; if (!S.sound) stopPurr(); save(); updateHud(); fillParentMenu(); });
    tapBtn('pReset', () => {
      if (!resetArmed) { resetArmed = true; fillParentMenu(); return; }
      try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* ignorer */ }
      stopPurr();
      S = null; bubble = null; bowl = null; parts.length = 0;
      setMode('normal');
      hide('parent');
      $('nameInput').value = '';
      showStart();
    });

    // Forældremenu: hold fingeren på kattens navn i 2 sekunder.
    const nb = $('nameBox');
    let lp = null;
    const lpEnd = () => { if (lp) { clearTimeout(lp); lp = null; } };
    const lpStart = () => { lpEnd(); lp = setTimeout(() => { lp = null; if (S) openParent(); }, 2000); };
    nb.addEventListener('touchstart', lpStart, { passive: true });
    nb.addEventListener('mousedown', lpStart);
    ['touchend', 'touchcancel', 'touchmove', 'mouseup', 'mouseleave'].forEach(ev => nb.addEventListener(ev, lpEnd));

    // berøring på stuen
    const ptr = { down: false, lx: 0, ly: 0, t0: 0, moved: 0, onCat: false };
    const pos = e => {
      const r = canvas.getBoundingClientRect();
      const t = (e.touches && e.touches.length) ? e.touches[0] : ((e.changedTouches && e.changedTouches.length) ? e.changedTouches[0] : e);
      return { x: t.clientX - r.left, y: t.clientY - r.top };
    };
    const featherTo = p => { feather.tx = p.x; feather.ty = clamp(p.y - 70 * U, 20 * U, G.catY - 90 * U); };
    const down = p => {
      if (!S) return;
      ptr.down = true; ptr.lx = p.x; ptr.ly = p.y; ptr.t0 = now(); ptr.moved = 0;
      ptr.onCat = hitCat(p);
      if (mode === 'play') { featherTo(p); return; }
      if (mode === 'wash') { sponge.x = p.x; sponge.y = p.y; if (hitLitter(p)) scoop(); return; }
      if (S.lightsOff || ptr.onCat) return;
      if (hitLitter(p)) { if (!scoop()) say('Kattebakken er ren ✨', 1.6); }
      else if (hitBowl(p)) openFood();
    };
    const move = p => {
      if (!S) return;
      const dx = p.x - ptr.lx, dy = p.y - ptr.ly, d = Math.sqrt(dx * dx + dy * dy);
      ptr.lx = p.x; ptr.ly = p.y; ptr.moved += d;
      if (mode === 'play') { featherTo(p); return; }
      if (!ptr.down) return;
      if (mode === 'wash') { sponge.x = p.x; sponge.y = p.y; if (cat.state === 'wash' && hitCat(p)) scrub(p, d); return; }
      if (!S.lightsOff && ptr.onCat && ptr.moved > 10 && hitCat(p)) pet(p, d);
    };
    const up = () => {
      if (!S || !ptr.down) return;
      ptr.down = false;
      if (mode === 'normal' && ptr.onCat && ptr.moved < 12 && now() - ptr.t0 < 450) tapCat();
    };
    canvas.addEventListener('touchstart', e => { e.preventDefault(); unlockAudio(); down(pos(e)); }, { passive: false });
    canvas.addEventListener('touchmove', e => { e.preventDefault(); move(pos(e)); }, { passive: false });
    canvas.addEventListener('touchend', e => { e.preventDefault(); up(); }, { passive: false });
    canvas.addEventListener('touchcancel', () => up(), false);
    canvas.addEventListener('mousedown', e => { unlockAudio(); down(pos(e)); });
    window.addEventListener('mousemove', e => { if (ptr.down || mode === 'play') move(pos(e)); });
    window.addEventListener('mouseup', () => up());
  }

  function hitCat(p) {
    if (!S) return false;
    const s = catScale();
    if (cat.state === 'sleep') {
      const ax = (p.x - cat.x) / (95 * s), ay = (p.y - (cat.y - 40 * s)) / (60 * s);
      return ax * ax + ay * ay < 1;
    }
    const st = STAGES[S.stage];
    const top = (118 * st.body + 60 * st.head) * s;
    const cy = cat.y - catLift() - top / 2, ry = top / 2 + 10 * s, rx = 72 * s;
    const dx = (p.x - cat.x) / rx, dy = (p.y - cy) / ry;
    return dx * dx + dy * dy < 1;
  }
  function hitBox(p, o, w, h) { const s = objScale(o.y); return Math.abs(p.x - o.x) < w * s && p.y > o.y - h * s && p.y < o.y + 12 * s; }
  function hitLitter(p) { return hitBox(p, G.litter, 88, 80); }
  function hitBowl(p) { return hitBox(p, G.bowl, 60, 50); }

  // ================================================================ ikon (bruges kun af tools/icon.html)
  function renderIcon() {
    const size = window.MINMIS_ICON_SIZE || 180;
    const c = document.createElement('canvas');
    c.width = size; c.height = size;
    document.body.appendChild(c);
    const x = c.getContext('2d');
    x.scale(size / 180, size / 180);
    const g = x.createLinearGradient(0, 0, 0, 180);
    g.addColorStop(0, '#FFE3B8'); g.addColorStop(1, '#FFB8A8');
    x.fillStyle = g; x.fillRect(0, 0, 180, 180);
    x.save(); x.translate(90, 106); x.scale(1.12, 1.12); x.lineJoin = 'round'; x.lineCap = 'round';
    drawHead(x, COATS.orange, { eyes: 'open', mouth: 'w', blush: true, wear: { head: 'bow' } });
    x.restore();
  }

  // ================================================================ start
  if (window.MINMIS_ICON) { renderIcon(); return; }

  // Ny version hentet af iPad'en (AppCache): skift til den med det samme.
  try {
    const ac = window.applicationCache;
    if (ac && ac.addEventListener) ac.addEventListener('updateready', () => { try { ac.swapCache(); } catch (e) { /* ignorer */ } save(); location.reload(); });
  } catch (e) { /* ignorer */ }

  canvas = $('scene');
  ctx = canvas.getContext('2d');
  bg = document.createElement('canvas');
  bgx = bg.getContext('2d');
  buildUi();

  document.addEventListener('touchmove', e => { if (!(e.target.closest && e.target.closest('.scroll'))) e.preventDefault(); }, { passive: false });
  document.addEventListener('gesturestart', e => e.preventDefault());
  document.addEventListener('touchend', unlockAudio, false);
  let rzT = null;
  window.addEventListener('resize', () => { clearTimeout(rzT); rzT = setTimeout(layout, 120); });
  window.addEventListener('orientationchange', () => setTimeout(layout, 350));
  document.addEventListener('visibilitychange', () => {
    if (!S) return;
    if (document.hidden) { stopPurr(); save(); }
    else afterAway(catchUp());
  });
  window.addEventListener('pagehide', () => save());

  S = load();
  skyNow = skyPhase(now());
  layout();
  if (S) startGame(false); else showStart();
  if (/iPad|iPhone|iPod/.test(navigator.userAgent) && !navigator.standalone) $('installHint').classList.remove('hidden');
  requestAnimationFrame(frame);

  // Kun til test på Mac'en (index.html?debug): spol tiden frem uden at vente.
  if (/[?&]debug\b/.test(location.search)) {
    window.__minmis = {
      step: sec => { for (let i = 0; i < Math.round(sec * 30); i++) update(1 / 30); draw(); return { state: cat.state, x: Math.round(cat.x), needs: S.needs, hearts: S.hearts, poop: S.poop, mode: mode, bubble: bubble && bubble.text }; },
      drawMs: () => { const t0 = performance.now(); for (let i = 0; i < 20; i++) draw(); return (performance.now() - t0) / 20; },
      S: () => S, cat: cat, G: G,
      mouse: (type, px, py) => {
        const r = canvas.getBoundingClientRect();
        (type === 'mousedown' ? canvas : window).dispatchEvent(new MouseEvent(type, { clientX: r.left + px, clientY: r.top + py, bubbles: true }));
      }
    };
  }
})();

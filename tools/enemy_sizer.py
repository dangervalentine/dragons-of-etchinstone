"""Writes build/enemy-sizer/index.html: every Enemy on its panel, drawn as the game draws
it (ui/widgets/encounter_face.gd enemy_crop, region_panel.gd), with a size and a sideways
shift input each and a line-up of all sixteen on one ground line, to set Art.ENEMY_SIZE
and Art.ENEMY_SHIFT by eye.

The page reads the art straight from art/painted/ (open it from the repository, as a
file), measures nothing itself, and gives back the ENEMY_SIZE and ENEMY_SHIFT tables
to paste into ui/model/art.gd.

Run:
  python tools/enemy_sizer.py            # then open build/enemy-sizer/index.html
"""
import base64
import html
import io
import json
import os
import re

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "enemy-sizer")


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return f.read()


def gd_dict(text, name):
    """The body of a GDScript `const NAME := { ... }`."""
    m = re.search(r"const %s := \{(.*?)\n\}" % name, text, re.S)
    return m.group(1) if m else ""


# An Enemy drawn in its own colours: no fill and no rim.
PLAIN = {"fill": "ffffff", "fill_amount": 0.0, "rim": "ffffff", "rim_amount": 0.0, "rim_from": [1.0, 0.0], "rim_width": 0.03}


def read_lights(body):
    """Art.ENEMY_LIGHT as {key: {fill, fill_amount, rim, rim_amount, rim_from, rim_width}}."""
    out = {}
    for key, inner in re.findall(r'"([a-z-]+)": \{(.*?)\},', body, re.S):
        light = dict(PLAIN)
        for name, value in re.findall(r'"(\w+)": (Color\("[0-9a-fA-F]+"\)|Vector2\([^)]*\)|-?[0-9.]+)', inner):
            if value.startswith("Color"):
                light[name] = value[7:-2]
            elif value.startswith("Vector2"):
                light[name] = [float(v) for v in value[8:-1].split(",")]
            else:
                light[name] = float(value)
        out[key] = light
    return out


def figure_data(img):
    """The figure at 512, as a data URL."""
    buf = io.BytesIO()
    img.convert("RGBA").resize((512, 512), Image.LANCZOS).save(buf, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def main():
    art = read("ui/model/art.gd")
    tokens = read("ui/theme/tokens.gd")
    set_back = float(re.search(r"const ENEMY_SET_BACK := ([0-9.]+)", tokens).group(1))
    sizes = {k: int(v) for k, v in re.findall(r'"([a-z-]+)":\s*(-?\d+)', gd_dict(art, "ENEMY_SIZE"))}
    shifts = {k: int(v) for k, v in re.findall(r'"([a-z-]+)":\s*(-?\d+)', gd_dict(art, "ENEMY_SHIFT"))}
    lights = read_lights(gd_dict(art, "ENEMY_LIGHT"))
    regions = {}
    for r, body in re.findall(r"(\d): \[([^\]]*)\]", gd_dict(art, "ENEMIES")):
        regions[int(r)] = re.findall(r'"([a-z-]+)"', body)
    names = {}
    for r, body in re.findall(r"(\d): \[([^\]]*)\]", gd_dict(art, "ENEMY_NAMES")):
        names[int(r)] = re.findall(r'"([^"]+)"', body)

    enemies = []
    for r in sorted(regions):
        for i, key in enumerate(regions[r]):
            img = Image.open(os.path.join(ROOT, "art", "painted", key + ".png"))
            # As encounter_face.figure_bounds: the box round every pixel more than
            # 20% opaque, in the art's 512 units.
            box = img.getchannel("A").point(lambda a: 255 if a > 51 else 0).getbbox()
            k = 512.0 / img.width
            enemies.append({
                "key": key, "name": names[r][i], "region": r,
                "bounds": [box[0] * k, box[1] * k, (box[2] - box[0]) * k, (box[3] - box[1]) * k],
                "size": sizes.get(key, 100),
                "shift": shifts.get(key, 0),
                "light": lights.get(key, dict(PLAIN)),
                # Built into the page: the light reads the figure's pixels, which a
                # browser refuses for a picture loaded from disk.
                "figure": figure_data(img),
                "backdrop": "../../art/painted/backdrops/%s.png" % key,
            })

    os.makedirs(OUT, exist_ok=True)
    page = PAGE.replace("__DATA__", json.dumps({"setBack": set_back, "enemies": enemies}))
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print("wrote", os.path.relpath(os.path.join(OUT, "index.html"), ROOT))


PAGE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Enemy Sizes</title>
<style>
:root {
	color-scheme: dark;
	--ground: #0e1517; --stone: #172225; --raised: #213033; --line: #2e3f40; --edge: #64797a;
	--ink: #f1e3d1; --muted: #b4a894; --brass: #dcb35c; --jade: #8fc4a3;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--ground); color: var(--ink); font: 500 15px/1.45 "Segoe UI", system-ui, sans-serif; }
main { max-width: 1500px; margin: 0 auto; padding: 24px 16px 64px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 28px; }
main > *, .cell { min-width: 0; }
h1 { margin: 0; font-size: 26px; }
h2 { margin: 0 0 10px; font-size: 18px; color: var(--muted); font-weight: 600; }
p { margin: 0; color: var(--muted); max-width: 80ch; }
.bar { position: sticky; top: 0; z-index: 2; background: var(--ground); border-bottom: 2px solid var(--line);
	display: flex; flex-wrap: wrap; gap: 10px 18px; align-items: center; padding: 10px 0; }
.bar label { display: flex; gap: 6px; align-items: center; color: var(--muted); }
button { font: inherit; color: var(--ink); background: var(--raised); border: 2px solid var(--edge); padding: 6px 14px; border-radius: 4px; cursor: pointer; }
button:hover { border-color: var(--brass); }
button:focus-visible, input:focus-visible { outline: 3px solid var(--jade); outline-offset: 2px; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 300px), 1fr)); gap: 18px 16px; }
.cell { display: grid; gap: 6px; background: var(--stone); border: 2px solid var(--line); border-radius: 6px; padding: 8px; }
.cell.changed { border-color: var(--brass); }
.cell.cut { border-color: #ee7a62; }
.warn { color: #ee7a62; font-size: 14px; min-height: 0; }
.warn:empty { display: none; }
.cell canvas { width: 100%; height: auto; display: block; border-radius: 4px; }
.row { display: flex; align-items: center; gap: 8px; }
.row b { margin-right: auto; font-weight: 600; }
.row small { color: var(--muted); }
input[type=number] { width: 70px; font: inherit; color: var(--ink); background: var(--ground); border: 2px solid var(--edge); border-radius: 4px; padding: 3px 6px; }
input[type=range] { flex: 1; min-width: 0; accent-color: var(--brass); }
.lab { width: 3.2em; color: var(--muted); }
details { border-top: 1px solid var(--line); padding-top: 4px; }
summary { cursor: pointer; color: var(--muted); }
input[type=color] { width: 40px; height: 26px; padding: 0; border: 2px solid var(--edge); border-radius: 4px; background: var(--ground); }
.val { width: 3.4em; text-align: right; color: var(--ink); font-variant-numeric: tabular-nums; }
.lineup { overflow-x: auto; background: var(--stone); border: 2px solid var(--line); border-radius: 6px; padding: 8px; }
.lineup canvas { display: block; height: 340px; width: auto; }
pre { margin: 0; background: #0a1012; border: 2px solid var(--line); border-radius: 4px; padding: 12px; overflow-x: auto; }
</style>
</head>
<body>
<main>
<header>
<h1>Enemy Sizes</h1>
<p>Every Enemy on its panel as the game draws it: its backdrop, set back left of the middle, sized about its feet and moved by its own shift. Size is a percentage of the art; shift is a percentage of the panel's art width, negative to the left. Light is the scene's light on the figure, as the game's shader draws it: a fill that pulls its colours toward the scene's, and a rim of light on the edges facing the light, from the direction set by its angle. The panel, the line-up and the tables below follow. The dark strip on the left of each panel is where the stat badges sit.</p>
</header>
<div class="bar">
	<label><input type="checkbox" id="badges" checked> Badge strip</label>
	<label><input type="checkbox" id="ground"> Ground line</label>
	<button id="reset">Reset to art.gd</button>
	<button id="copy">Copy tables</button>
	<span id="note" role="status"></span>
</div>
<section><h2>Line-up: every figure on one ground line, at its size</h2><div class="lineup"><canvas id="lineup"></canvas></div></section>
<section id="regions"></section>
<section><h2>ENEMY_SIZE, ENEMY_SHIFT and ENEMY_LIGHT for ui/model/art.gd</h2><pre id="out"></pre></section>
</main>
<script>
const DATA = __DATA__;
const ART = 512;                       // the art's units (Art.FULL)
const PANEL = 1.4448;                  // an Enemy panel's width over height (region_card.gd LAYOUT)
const ART_X = 0.17;                    // the art starts after the badge column (region_panel.parts)
const PW = 660, PH = Math.round(PW / PANEL);
const start = Object.fromEntries(DATA.enemies.map(e => [e.key, e.size]));
const size = { ...start };
const startShift = Object.fromEntries(DATA.enemies.map(e => [e.key, e.shift]));
const shift = { ...startShift };
const startLight = Object.fromEntries(DATA.enemies.map(e => [e.key, JSON.stringify(e.light)]));
const light = Object.fromEntries(DATA.enemies.map(e => [e.key, JSON.parse(JSON.stringify(e.light))]));
const lit = {};     // each figure as the shader lights it, a 512 square canvas
const base = {};    // each figure's own pixels at that size

// creature_idle.gdshader's fill and rim, on the figure's pixels.
function hex(h) { return [parseInt(h.slice(0, 2), 16) / 255, parseInt(h.slice(2, 4), 16) / 255, parseInt(h.slice(4, 6), 16) / 255]; }
function relight(e) {
	const src = base[e.key]; if (!src) return;
	const N = 512, L = light[e.key], out = new ImageData(N, N), a = src.data, o = out.data;
	const f = hex(L.fill), r = hex(L.rim), fa = L.fill_amount, ra = L.rim_amount;
	const len = Math.hypot(L.rim_from[0], L.rim_from[1]) || 1;
	const dx = L.rim_from[0] / len * L.rim_width * N, dy = L.rim_from[1] / len * L.rim_width * N;
	const alpha = (x, y) => { x = Math.round(x); y = Math.round(y); return (x < 0 || y < 0 || x >= N || y >= N) ? 0 : a[(y * N + x) * 4 + 3] / 255; };
	for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
		const i = (y * N + x) * 4, al = a[i + 3];
		o[i + 3] = al;
		let R = a[i] / 255, G = a[i + 1] / 255, B = a[i + 2] / 255;
		if (al === 0) { o[i] = a[i]; o[i + 1] = a[i + 1]; o[i + 2] = a[i + 2]; continue; }
		if (fa > 0) {
			const lum = 0.299 * R + 0.587 * G + 0.114 * B;
			const lr = Math.min(1, R * f[0] * 1.6 * 0.65 + lum * f[0] * 1.8 * 0.35);
			const lg = Math.min(1, G * f[1] * 1.6 * 0.65 + lum * f[1] * 1.8 * 0.35);
			const lb = Math.min(1, B * f[2] * 1.6 * 0.65 + lum * f[2] * 1.8 * 0.35);
			R += (lr - R) * fa; G += (lg - G) * fa; B += (lb - B) * fa;
		}
		if (ra > 0) {
			let open = 0;
			for (let k = 1; k <= 4; k++) open = Math.max(open, (1 - alpha(x + dx * k / 4, y + dy * k / 4)) * (1 - (k - 1) * 0.2));
			const add = Math.min(1, open * ra);
			R = Math.min(1, R + r[0] * add); G = Math.min(1, G + r[1] * add); B = Math.min(1, B + r[2] * add);
		}
		o[i] = R * 255; o[i + 1] = G * 255; o[i + 2] = B * 255;
	}
	lit[e.key].getContext("2d").putImageData(out, 0, 0);
}
function prepare(e) {
	const img = imgs[e.figure]; if (!img) return;
	const c = document.createElement("canvas"); c.width = c.height = 512;
	const g = c.getContext("2d"); g.drawImage(img, 0, 0, 512, 512);
	base[e.key] = g.getImageData(0, 0, 512, 512);
	lit[e.key] = document.createElement("canvas"); lit[e.key].width = lit[e.key].height = 512;
	relight(e);
}
const imgs = {};

function load(src) {
	return new Promise(ok => { const i = new Image(); i.onload = () => ok(i); i.onerror = () => ok(null); i.src = src; });
}

// encounter_face.enemy_crop: the part of the art shown in the art area.
function crop(e, k) {
	const ratio = (PW * (1 - ART_X)) / PH;
	const w = ART * ratio;
	const back = DATA.setBack - shift[e.key] / 100;
	let c = { x: ART / 2 - w / 2 + w * back, y: 0, w, h: ART };
	if (k === 1) return c;
	const [bx, by, bw, bh] = e.bounds;
	const fx = bx + bw / 2, fy = by + bh;
	const ax = (fx - c.x) / c.w, ay = (fy - c.y) / c.h;
	const nw = c.w / k, nh = c.h / k;
	return { x: fx - ax * nw, y: fy - ay * nh, w: nw, h: nh };
}

// region_panel.cover_region: the part of the backdrop that covers the whole frame.
function cover(img, w, h) {
	const k = Math.max(w / img.width, h / img.height);
	const sw = w / k, sh = h / k;
	return [(img.width - sw) / 2, (img.height - sh) / 2, sw, sh];
}

function framePath(g, w, h) {
	const c = Math.min(w, h) * 0.07;
	g.beginPath();
	g.moveTo(0, 0); g.lineTo(w - c, 0); g.lineTo(w, c); g.lineTo(w, h - c); g.lineTo(w - c, h); g.lineTo(0, h); g.closePath();
}

function drawPanel(e) {
	const cv = document.getElementById("c-" + e.key), g = cv.getContext("2d");
	g.clearRect(0, 0, PW, PH);
	g.save(); framePath(g, PW, PH); g.clip();
	const bd = imgs[e.backdrop];
	if (bd) g.drawImage(bd, ...cover(bd, PW, PH), 0, 0, PW, PH);
	else { g.fillStyle = "#2b3a3c"; g.fillRect(0, 0, PW, PH); }
	const ax = PW * ART_X, aw = PW - ax;
	const k = size[e.key] / 100, c = crop(e, k);
	const z = PH / c.h;
	g.save(); g.beginPath(); g.rect(ax, 0, aw, PH); g.clip();
	const fig = lit[e.key] || imgs[e.figure];
	if (fig) g.drawImage(fig, ax - c.x * z, -c.y * z, ART * z, ART * z);
	g.restore();
	if (document.getElementById("badges").checked) {
		g.fillStyle = "rgba(10,16,18,0.55)"; g.fillRect(0, 0, ax, PH);
	}
	if (document.getElementById("ground").checked) {
		const gy = (e.bounds[1] + e.bounds[3] - c.y) * z;
		g.strokeStyle = "#8fc4a3"; g.setLineDash([8, 6]); g.lineWidth = 2;
		g.beginPath(); g.moveTo(0, gy); g.lineTo(PW, gy); g.stroke();
	}
	g.restore();
	g.lineWidth = 4; g.strokeStyle = "#64797a"; framePath(g, PW, PH); g.stroke();
	const cell = cv.closest(".cell");
	cell.classList.toggle("changed", size[e.key] !== start[e.key] || shift[e.key] !== startShift[e.key] || JSON.stringify(light[e.key]) !== startLight[e.key]);
	// The figure's top above the panel's: it is cut off. The largest size that fits
	// keeps its feet on the ground line and its top at the panel's edge.
	const cut = (e.bounds[1] - c.y) * z < -0.5;
	const fits = Math.floor(100 * (e.bounds[1] + e.bounds[3]) / e.bounds[3]);
	cell.classList.toggle("cut", cut);
	cell.querySelector(".warn").textContent = cut ? `Cut off at the top: ${fits}% is the largest that fits.` : "";
}

function drawLineup() {
	const cv = document.getElementById("lineup"), g = cv.getContext("2d");
	const H = 700, base = 600, scale = 1.0;
	const slots = DATA.enemies.map(e => {
		const k = size[e.key] / 100;
		return { e, k, w: e.bounds[2] * k * scale, h: e.bounds[3] * k * scale };
	});
	const gap = 24;
	const W = slots.reduce((a, s) => a + s.w + gap, gap);
	cv.width = W; cv.height = H;
	g.fillStyle = "#172225"; g.fillRect(0, 0, W, H);
	g.strokeStyle = "#2e3f40"; g.lineWidth = 2;
	for (let y = base; y > 0; y -= 100) { g.beginPath(); g.moveTo(0, y); g.lineTo(W, y); g.stroke(); }
	let x = gap;
	g.font = "600 30px Segoe UI, sans-serif"; g.textAlign = "center"; g.fillStyle = "#b4a894";
	for (const s of slots) {
		const [bx, by, bw, bh] = s.e.bounds, fig = lit[s.e.key] || imgs[s.e.figure];
		const k = s.k * scale;
		if (fig) g.drawImage(fig, bx * fig.width / ART, by * fig.height / ART, bw * fig.width / ART, bh * fig.height / ART,
			x, base - bh * k, bw * k, bh * k);
		g.fillText(s.e.name, x + s.w / 2, base + 34);
		g.fillText(size[s.e.key] + "%", x + s.w / 2, base + 70);
		x += s.w + gap;
	}
	g.strokeStyle = "#8fc4a3"; g.beginPath(); g.moveTo(0, base); g.lineTo(W, base); g.stroke();
}

function gdTable(name, values, plain) {
	const lines = DATA.enemies.filter(e => values[e.key] !== plain).map(e => `\t"${e.key}": ${values[e.key]},`);
	return `const ${name} := {\n` + lines.join("\n") + (lines.length ? "\n" : "") + "}";
}

const n2 = v => { const r = Math.round(v * 100) / 100; return Number.isInteger(r) ? r.toFixed(1) : String(r); };
function lightTable() {
	const lines = DATA.enemies.filter(e => light[e.key].fill_amount > 0 || light[e.key].rim_amount > 0).map(e => {
		const L = light[e.key];
		return `\t"${e.key}": {"fill": Color("${L.fill}"), "fill_amount": ${n2(L.fill_amount)}, "rim": Color("${L.rim}"), "rim_amount": ${n2(L.rim_amount)},\n` +
			`\t\t"rim_from": Vector2(${n2(L.rim_from[0])}, ${n2(L.rim_from[1])}), "rim_width": ${Math.round(L.rim_width * 1000) / 1000}},`;
	});
	return "const ENEMY_LIGHT := {\n" + lines.join("\n") + (lines.length ? "\n" : "") + "}";
}

function table() {
	return gdTable("ENEMY_SIZE", size, 100) + "\n\n" + gdTable("ENEMY_SHIFT", shift, 0) + "\n\n" + lightTable();
}

function redraw(e) {
	if (e) drawPanel(e); else DATA.enemies.forEach(drawPanel);
	drawLineup();
	document.getElementById("out").textContent = table();
	for (const en of DATA.enemies) {
		document.getElementById("n-" + en.key).value = size[en.key];
		document.getElementById("r-" + en.key).value = size[en.key];
		document.getElementById("xn-" + en.key).value = shift[en.key];
		document.getElementById("xr-" + en.key).value = shift[en.key];
		const L = light[en.key], cell = document.getElementById("c-" + en.key).closest(".cell");
		const angle = Math.round(Math.atan2(L.rim_from[1], L.rim_from[0]) * 180 / Math.PI);
		for (const el of cell.querySelectorAll("[data-l]")) {
			const k = el.dataset.l;
			el.value = k === "fill" || k === "rim" ? "#" + L[k] : k === "angle" ? angle : L[k];
		}
		for (const el of cell.querySelectorAll("[data-v]")) {
			const k = el.dataset.v;
			el.textContent = k === "angle" ? angle + "°" : k === "rim_width" ? L[k].toFixed(3) : L[k].toFixed(2);
		}
	}
}

function build() {
	const root = document.getElementById("regions");
	for (let r = 1; r <= 4; r++) {
		const sec = document.createElement("section");
		sec.innerHTML = `<h2>Region ${r}</h2><div class="grid"></div>`;
		const grid = sec.querySelector(".grid");
		for (const e of DATA.enemies.filter(e => e.region === r)) {
			const cell = document.createElement("div");
			cell.className = "cell";
			cell.innerHTML = `<canvas id="c-${e.key}" width="${PW}" height="${PH}" aria-label="${e.name} on its panel"></canvas>
				<div class="row"><b>${e.name}</b><small>${e.key}</small></div>
				<div class="warn" role="status"></div>
				<div class="row"><small class="lab">Size</small><input type="range" id="r-${e.key}" min="50" max="160" step="1" aria-label="${e.name} size slider">
				<input type="number" id="n-${e.key}" min="50" max="160" step="1" aria-label="${e.name} size, percent"> %</div>
				<div class="row"><small class="lab">Shift</small><input type="range" id="xr-${e.key}" min="-40" max="40" step="1" aria-label="${e.name} shift slider">
				<input type="number" id="xn-${e.key}" min="-40" max="40" step="1" aria-label="${e.name} shift, percent of the panel"> %</div>
				<details${e.light.fill_amount > 0 || e.light.rim_amount > 0 ? " open" : ""}><summary>Light</summary>
				<div class="row"><small class="lab">Fill</small><input type="color" data-l="fill" aria-label="${e.name} fill colour">
				<input type="range" data-l="fill_amount" min="0" max="1" step="0.05" aria-label="${e.name} fill strength"><span class="val" data-v="fill_amount"></span></div>
				<div class="row"><small class="lab">Rim</small><input type="color" data-l="rim" aria-label="${e.name} rim colour">
				<input type="range" data-l="rim_amount" min="0" max="1.5" step="0.05" aria-label="${e.name} rim strength"><span class="val" data-v="rim_amount"></span></div>
				<div class="row"><small class="lab">From</small><input type="range" data-l="angle" min="-180" max="180" step="5" aria-label="${e.name} rim light direction, degrees"><span class="val" data-v="angle"></span></div>
				<div class="row"><small class="lab">Width</small><input type="range" data-l="rim_width" min="0.005" max="0.08" step="0.005" aria-label="${e.name} rim width"><span class="val" data-v="rim_width"></span></div>
				</details>`;
			grid.append(cell);
			const set = v => { const n = Math.round(Number(v)); if (n >= 10 && n <= 300) { size[e.key] = n; redraw(e); } };
			const move = v => { const n = Math.round(Number(v)); if (n >= -80 && n <= 80) { shift[e.key] = n; redraw(e); } };
			cell.querySelector("#n-" + e.key).addEventListener("input", ev => set(ev.target.value));
			cell.querySelector("#r-" + e.key).addEventListener("input", ev => set(ev.target.value));
			cell.querySelector("#xn-" + e.key).addEventListener("input", ev => move(ev.target.value));
			cell.querySelector("#xr-" + e.key).addEventListener("input", ev => move(ev.target.value));
			let queued = false;
			cell.querySelectorAll("[data-l]").forEach(el => el.addEventListener("input", () => {
				const L = light[e.key], k = el.dataset.l;
				if (k === "fill" || k === "rim") L[k] = el.value.slice(1);
				else if (k === "angle") { const a = Number(el.value) * Math.PI / 180; L.rim_from = [Math.cos(a), Math.sin(a)]; }
				else L[k] = Number(el.value);
				if (!queued) { queued = true; setTimeout(() => { queued = false; relight(e); redraw(e); }, 16); }
			}));
		}
		root.append(sec);
	}
	document.getElementById("badges").addEventListener("change", () => redraw());
	document.getElementById("ground").addEventListener("change", () => redraw());
	document.getElementById("reset").addEventListener("click", () => {
		Object.assign(size, start); Object.assign(shift, startShift);
		for (const e of DATA.enemies) { light[e.key] = JSON.parse(startLight[e.key]); relight(e); }
		redraw();
	});
	document.getElementById("copy").addEventListener("click", async () => {
		const note = document.getElementById("note");
		try { await navigator.clipboard.writeText(table()); note.textContent = "Copied."; }
		catch { note.textContent = "Copy failed; select the table below instead."; }
	});
}

(async () => {
	const srcs = [...new Set(DATA.enemies.flatMap(e => [e.figure, e.backdrop]))];
	const loaded = await Promise.all(srcs.map(load));
	srcs.forEach((s, i) => imgs[s] = loaded[i]);
	DATA.enemies.forEach(prepare);
	build();
	redraw();
})();
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()

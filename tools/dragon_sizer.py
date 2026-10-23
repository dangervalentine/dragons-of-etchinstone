"""Writes build/dragon-sizer/index.html: each dragon in every place the game draws its
body, always from its whole picture (<id>-full), with a size, x and y input for each
place, to set Art.DRAGON_PLACE by eye.

The places, each drawn as the game lays it out:
  card    the Dragon Card (the Deck in the Final Battle, and the choice of dragon):
          ui/widgets/dragon_card.gd art_rect, with the dragon guide over it (the name
          band, the row of figures, the MP and HP ladders tier by tier with the card's
          own numbers, the head box and the feet line)
  battle  the Final Enemy face: ui/widgets/dragon_face.gd _place, the dragon in the
          square at the foot of its lair, the battle's figures over the top half
  ending  the ending screen: ui/screens/ending_screen.gd, the dragon as tall as the
          stage, its placings beside it
The card is drawn at its printed 5 by 7; the Final Enemy and the ending are drawn at a
typical shape of theirs, which changes with the window, so x and y are shares of the
place and carry over.

The page reads the art straight from art/painted/ (open it from the repository, as a
file) and gives back DRAGON_PLACE to paste into ui/model/art.gd.

Run:
  python tools/dragon_sizer.py           # then open build/dragon-sizer/index.html
"""
import json
import os
import re

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "dragon-sizer")
PLACES = ["card", "battle", "ending"]


def read(path):
	with open(os.path.join(ROOT, path), encoding="utf-8") as f:
		return f.read()


def gd_dict(text, name):
	m = re.search(r"const %s := \{(.*?)\n\}" % name, text, re.S)
	return m.group(1) if m else ""


def places(art):
	"""DRAGON_PLACE as {place: {id: [size, x, y]}}."""
	body = gd_dict(art, "DRAGON_PLACE")
	out = {}
	for place, inner in re.findall(r'"(\w+)": \{(.*?)\n\t\}', body, re.S):
		out[place] = {k: [int(a), int(b), int(c)] for k, a, b, c in
		              re.findall(r'"([a-z]+)": \[(-?\d+), (-?\d+), (-?\d+)\]', inner)}
	return out


def main():
	art = read("ui/model/art.gd")
	card = read("ui/widgets/dragon_card.gd")
	layout = {k: [float(v) for v in vals.split(",")] for k, vals in
	          re.findall(r'"(\w+)": Rect2\(([^)]*)\)', gd_dict(card, "LAYOUT"))}
	art_side = float(re.search(r"const ART_SIDE := ([0-9.]+)", card).group(1))
	art_gap = float(re.search(r"const ART_GAP := ([0-9.]+)", card).group(1))
	set_ = places(art)
	cards = json.loads(read("data/cards.json"))

	dragons = []
	for d in cards["dragons"]:
		key = d["id"]
		img = Image.open(os.path.join(ROOT, "art", "painted", key + "-full.png"))
		k = 512.0 / img.width
		box = img.getchannel("A").point(lambda a: 255 if a > 51 else 0).getbbox()
		used = img.getchannel("A").getbbox()     # the ending measures every drawn pixel
		head = None
		hp = os.path.join(ROOT, "art", "painted", key + "-head.png")
		dragons.append({
			"key": key, "name": d["name"], "title": d["title"],
			"element": d["mp_tiers"][0]["mp"]["element"],
			"bounds": [box[0] * k, box[1] * k, (box[2] - box[0]) * k, (box[3] - box[1]) * k],
			"drawn": [used[0] * k, used[1] * k, (used[2] - used[0]) * k, (used[3] - used[1]) * k],
			"mp": [[t["mp"]["value"], t["time_penalty"]] for t in d["mp_tiers"]],
			"hp": [[t["hp"], t["attack"]["value"]] for t in d["hp_tiers"]],
			"figures": 2 + len(d["armor"]),
			"place": {p: set_.get(p, {}).get(key, [100, 0, 0]) for p in PLACES},
			"figure": "../../art/painted/%s-full.png" % key,
			"lair": "../../art/painted/lairs/%s.png" % key,
		})

	os.makedirs(OUT, exist_ok=True)
	data = {"layout": layout, "artSide": art_side, "artGap": art_gap, "places": PLACES, "dragons": dragons}
	with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8", newline="\n") as f:
		f.write(PAGE.replace("__DATA__", json.dumps(data)))
	print("wrote", os.path.relpath(os.path.join(OUT, "index.html"), ROOT))


PAGE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dragon Places</title>
<style>
:root {
	color-scheme: dark;
	--ground: #0e1517; --stone: #172225; --raised: #213033; --line: #2e3f40; --edge: #64797a;
	--ink: #f1e3d1; --muted: #b4a894; --brass: #dcb35c; --jade: #8fc4a3; --danger: #ee7a62;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--ground); color: var(--ink); font: 500 15px/1.45 "Segoe UI", system-ui, sans-serif; }
main { max-width: 1600px; margin: 0 auto; padding: 24px 16px 64px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 24px; }
main > * { min-width: 0; }
h1 { margin: 0; font-size: 26px; }
h2 { margin: 0; font-size: 20px; }
h3 { margin: 0; font-size: 15px; color: var(--muted); font-weight: 600; }
p { margin: 0; color: var(--muted); max-width: 90ch; }
.bar { position: sticky; top: 0; z-index: 2; background: var(--ground); border-bottom: 2px solid var(--line);
	display: flex; flex-wrap: wrap; gap: 10px 18px; align-items: center; padding: 10px 0; }
.bar label { display: flex; gap: 6px; align-items: center; color: var(--muted); }
button { font: inherit; color: var(--ink); background: var(--raised); border: 2px solid var(--edge); padding: 6px 14px; border-radius: 4px; cursor: pointer; }
button:hover { border-color: var(--brass); }
button:focus-visible, input:focus-visible { outline: 3px solid var(--jade); outline-offset: 2px; }
.dragon { display: grid; gap: 10px; border-top: 2px solid var(--line); padding-top: 16px; }
.places { display: grid; grid-template-columns: minmax(0, 300px) minmax(0, 300px) minmax(0, 540px); gap: 14px; align-items: start; }
@media (max-width: 900px) { .places { grid-template-columns: minmax(0, 1fr); } }
.cell { display: grid; gap: 6px; align-content: start; min-width: 0; background: var(--stone); border: 2px solid var(--line); border-radius: 6px; padding: 8px; }
.cell.changed { border-color: var(--brass); }
.cell canvas { width: 100%; height: auto; display: block; }
.row { display: flex; align-items: center; gap: 8px; }
.lab { width: 2.6em; color: var(--muted); }
.info { color: var(--muted); font-size: 14px; }
.info:empty { display: none; }
input[type=number] { width: 64px; font: inherit; color: var(--ink); background: var(--ground); border: 2px solid var(--edge); border-radius: 4px; padding: 2px 6px; }
input[type=range] { flex: 1; min-width: 0; accent-color: var(--brass); }
.key { display: flex; flex-wrap: wrap; gap: 6px 18px; color: var(--muted); font-size: 14px; }
.key span::before { content: ""; display: inline-block; width: 12px; height: 12px; margin-right: 6px; vertical-align: -1px; border: 2px solid var(--c); background: color-mix(in srgb, var(--c) 30%, transparent); }
pre { margin: 0; background: #0a1012; border: 2px solid var(--line); border-radius: 4px; padding: 12px; overflow-x: auto; }
</style>
</head>
<body>
<main>
<header>
<h1>Dragon Places</h1>
<p>Every place the game draws a dragon's body, always from its whole picture. In each, the dragon is first fitted as the game fits it, then placed: size grows or shrinks it about its feet, x moves it right and y moves it up, as a percentage of the place's width and height. The card is drawn at its printed shape; the Final Enemy and the ending at a typical shape of theirs, which changes with the window.</p>
</header>
<div class="bar">
	<label><input type="checkbox" id="guide" checked> Guide</label>
	<label><input type="checkbox" id="tiers" checked> Tier numbers</label>
	<button id="reset">Reset to art.gd</button>
	<button id="copy">Copy DRAGON_PLACE</button>
	<span id="note" role="status"></span>
</div>
<div class="key">
	<span style="--c:#8fc4a3">MP ladder (Final Journey tiers) and feet line</span>
	<span style="--c:#ee7a62">HP ladder (Final Enemy tiers)</span>
	<span style="--c:#b4a894">Name band, figures, the battle's panel, the ending's placings</span>
</div>
<section id="dragons"></section>
<section><h2>DRAGON_PLACE for ui/model/art.gd</h2><pre id="out"></pre></section>
</main>
<script>
const DATA = __DATA__;
const L = DATA.layout, ART = 512;
const SIZES = { card: [500, 700], battle: [420, 525], ending: [760, 420] };
const TITLES = { card: "Dragon Card · Deck and choice of dragon", battle: "Final Enemy", ending: "Ending screen" };
const start = {}, set = {};
for (const d of DATA.dragons) for (const p of DATA.places) {
	start[d.key + ":" + p] = [...d.place[p]];
	set[d.key + ":" + p] = [...d.place[p]];
}
const imgs = {};
const load = src => new Promise(ok => { const i = new Image(); i.onload = () => ok(i); i.onerror = () => ok(null); i.src = src; });

// Art.placed: the square the art is drawn in, from where the place fits it.
function placed(fitted, feet, room, v) {
	const k = fitted.w / ART, k2 = k * v[0] / 100;
	return { x: fitted.x + feet.x * k - feet.x * k2 + room.w * v[1] / 100,
	         y: fitted.y + feet.y * k - feet.y * k2 - room.h * v[2] / 100, w: ART * k2 };
}
const feetOf = b => ({ x: b[0] + b[2] / 2, y: b[1] + b[3] });

function cover(g, img, r) {
	if (!img) { g.fillStyle = "#24302f"; g.fillRect(r.x, r.y, r.w, r.h); return; }
	const k = Math.max(r.w / img.width, r.h / img.height), sw = r.w / k, sh = r.h / k;
	g.drawImage(img, (img.width - sw) / 2, (img.height - sh) / 2, sw, sh, r.x, r.y, r.w, r.h);
}
function box(g, r, colour, fill = 0.18) {
	g.save(); g.fillStyle = colour; g.globalAlpha = fill; g.fillRect(r.x, r.y, r.w, r.h);
	g.globalAlpha = 1; g.strokeStyle = colour; g.lineWidth = 2; g.strokeRect(r.x, r.y, r.w, r.h); g.restore();
}
function feetLine(g, y, w) {
	g.save(); g.strokeStyle = "#8fc4a3"; g.setLineDash([8, 6]); g.lineWidth = 2;
	g.beginPath(); g.moveTo(0, y); g.lineTo(w, y); g.stroke(); g.restore();
}
function ladder(g, col, rows, colour, labels) {
	box(g, col, colour, 0.12);
	const h = col.h / rows.length, s = Math.min(h * 0.9, col.w / 2 - 2);
	g.font = `700 ${Math.round(s * 0.5)}px Segoe UI, sans-serif`; g.textAlign = "center"; g.textBaseline = "middle";
	rows.forEach((t, i) => {
		const y = col.y + i * h + (h - s) / 2;
		for (const [x, v] of [[col.x + col.w / 2 - s - 1, t[0]], [col.x + col.w / 2 + 1, t[1]]]) {
			g.fillStyle = "rgba(10,16,18,0.82)"; g.fillRect(x, y, s, s);
			g.strokeStyle = colour; g.lineWidth = 1.5; g.strokeRect(x, y, s, s);
			if (labels) { g.fillStyle = "#f1e3d1"; g.fillText(v, x + s / 2, y + s / 2 + 1); }
		}
	});
}

function drawCard(g, d, v, guide, labels) {
	const [W, H] = SIZES.card, R = r => ({ x: r[0] * W, y: r[1] * H, w: r[2] * W, h: r[3] * H });
	g.save(); g.beginPath(); g.roundRect(0, 0, W, H, 18); g.clip();
	const band = R(L.band);
	cover(g, imgs[d.lair], { x: 0, y: band.y + band.h, w: W, h: H - band.y - band.h });
	// dragon_card.art_rect
	const top = L.figures[1] + L.figures[3] + DATA.artGap;
	const room = { x: W * DATA.artSide, y: H * top, w: W * (1 - 2 * DATA.artSide), h: H * (1 - top - DATA.artSide) };
	const b = d.bounds, k = Math.min(room.w / b[2], room.h / b[3]), f = feetOf(b);
	const fitted = { x: room.x + room.w / 2 - f.x * k, y: room.y + room.h - f.y * k, w: ART * k };
	const a = placed(fitted, f, { w: W, h: H }, v);
	if (imgs[d.figure]) g.drawImage(imgs[d.figure], a.x, a.y, a.w, a.w);
	g.fillStyle = "#0a1012"; g.fillRect(band.x, band.y, band.w, band.h);
	g.fillStyle = "#f1e3d1"; g.font = "700 30px Georgia, serif"; g.textAlign = "center"; g.textBaseline = "middle";
	g.fillText(d.name, W / 2, band.y + band.h * 0.42);
	g.fillStyle = "#b4a894"; g.font = "600 16px Segoe UI, sans-serif"; g.fillText(d.title, W / 2, band.y + band.h * 0.8);
	const hp = R(L.hp);
	if (guide) {
		const fr = R(L.figures), side = fr.h, gap = side * 0.12, n = d.figures;
		let x = fr.x + fr.w / 2 - (n * side + (n - 1) * gap) / 2;
		for (let i = 0; i < n; i++) { box(g, { x, y: fr.y, w: side, h: side }, "#b4a894", 0.25); x += side + gap; }
		ladder(g, R(L.mp), d.mp, "#8fc4a3", labels);
		ladder(g, hp, d.hp, "#ee7a62", labels);
		feetLine(g, a.y + f.y * a.w / ART, W);
	}
	g.restore();
	g.strokeStyle = "#64797a"; g.lineWidth = 3; g.beginPath(); g.roundRect(1.5, 1.5, W - 3, H - 3, 18); g.stroke();
	// How much of the dragon's own shape lies under the HP ladder.
	const s = a.w / ART;
	const fx0 = a.x + b[0] * s, fx1 = a.x + (b[0] + b[2]) * s, fy0 = a.y + b[1] * s, fy1 = a.y + (b[1] + b[3]) * s;
	const ox = Math.max(0, Math.min(fx1, hp.x + hp.w) - Math.max(fx0, hp.x));
	const oy = Math.max(0, Math.min(fy1, hp.y + hp.h) - Math.max(fy0, hp.y));
	return `${Math.round(100 * ox * oy / (hp.w * hp.h))}% of the HP ladder lies over the dragon's box.`;
}

function drawBattle(g, d, v, guide) {
	const [W, H] = SIZES.battle, band = 54;
	g.fillStyle = "#0a1012"; g.fillRect(0, 0, W, H);
	const field = { x: 0, y: band, w: W, h: H - band };
	cover(g, imgs[d.lair], field);
	// dragon_face._place: the square in the bottom half of the stage
	const half = Math.floor(field.h / 2), side = Math.min(field.w, field.h - half);
	const fitted = { x: (field.w - side) / 2, y: band + half + (field.h - half - side) / 2, w: side };
	const f = feetOf(d.bounds), a = placed(fitted, f, { w: field.w, h: field.h }, v);
	g.save(); g.beginPath(); g.rect(field.x, field.y, field.w, field.h); g.clip();
	if (imgs[d.figure]) g.drawImage(imgs[d.figure], a.x, a.y, a.w, a.w);
	if (guide) {
		box(g, { x: 16, y: band + 8, w: field.w - 32, h: half - 16 }, "#0a1012", 0.55);
		g.fillStyle = "#f1e3d1"; g.font = "600 15px Segoe UI, sans-serif"; g.textAlign = "center";
		g.fillText("figures and the battle's ladder", W / 2, band + half / 2);
		feetLine(g, a.y + f.y * a.w / ART, W);
	}
	g.restore();
	g.fillStyle = "#f1e3d1"; g.font = "700 22px Georgia, serif"; g.textAlign = "center"; g.textBaseline = "middle";
	g.fillText(d.name, W / 2, band / 2);
	return "";
}

function drawEnding(g, d, v, guide) {
	const [W, H] = SIZES.ending;
	g.fillStyle = "#0e1517"; g.fillRect(0, 0, W, H);
	// ending_screen: the drawn box as tall as the stage, at the row's left
	const dr = d.drawn, k = H / dr[3];
	const fitted = { x: -dr[0] * k, y: -dr[1] * k, w: ART * k };
	const f = { x: dr[0] + dr[2] / 2, y: dr[1] + dr[3] };
	const a = placed(fitted, f, { w: W, h: H }, v);
	if (imgs[d.figure]) g.drawImage(imgs[d.figure], a.x, a.y, a.w, a.w);
	if (guide) {
		const px = dr[2] * k + 24;
		box(g, { x: px, y: 8, w: W - px - 8, h: 90 }, "#0a1012", 0.55);
		g.fillStyle = "#f1e3d1"; g.font = "600 15px Segoe UI, sans-serif"; g.textAlign = "left"; g.textBaseline = "middle";
		g.fillText("placings beside the dragon", px + 12, 53);
		feetLine(g, a.y + f.y * a.w / ART, W);
	}
	return "";
}

const DRAW = { card: drawCard, battle: drawBattle, ending: drawEnding };

function draw(d, p) {
	const cv = document.getElementById(`c-${d.key}-${p}`), g = cv.getContext("2d");
	g.clearRect(0, 0, cv.width, cv.height);
	const id = d.key + ":" + p, v = set[id];
	const info = DRAW[p](g, d, v, document.getElementById("guide").checked, document.getElementById("tiers").checked);
	const cell = cv.closest(".cell");
	cell.querySelector(".info").textContent = info;
	cell.classList.toggle("changed", v.some((x, i) => x !== start[id][i]));
}

function table() {
	const lines = ["const DRAGON_PLACE := {"];
	for (const p of DATA.places) {
		lines.push(`\t"${p}": {`);
		for (const d of DATA.dragons) {
			const v = set[d.key + ":" + p];
			if (v[0] !== 100 || v[1] !== 0 || v[2] !== 0) lines.push(`\t\t"${d.key}": [${v[0]}, ${v[1]}, ${v[2]}],`);
		}
		lines.push("\t},");
	}
	lines.push("}");
	return lines.join("\n");
}

function redraw(only) {
	for (const d of DATA.dragons) for (const p of DATA.places) {
		if (only && only !== d.key + ":" + p) continue;
		draw(d, p);
		const v = set[d.key + ":" + p];
		["s", "x", "y"].forEach((c, i) => {
			document.getElementById(`${c}n-${d.key}-${p}`).value = v[i];
			document.getElementById(`${c}r-${d.key}-${p}`).value = v[i];
		});
	}
	document.getElementById("out").textContent = table();
}

function build() {
	const root = document.getElementById("dragons");
	const RANGE = { s: [40, 200], x: [-60, 60], y: [-60, 60] }, NAME = { s: "Size", x: "X", y: "Y" };
	for (const d of DATA.dragons) {
		const sec = document.createElement("section");
		sec.className = "dragon";
		sec.innerHTML = `<h2>${d.name} <small style="color:var(--muted);font-weight:500">${d.title} · ${d.element}</small></h2><div class="places"></div>`;
		const row = sec.querySelector(".places");
		for (const p of DATA.places) {
			const [W, H] = SIZES[p];
			const cell = document.createElement("div");
			cell.className = "cell";
			let controls = "";
			for (const c of ["s", "x", "y"]) {
				const [lo, hi] = RANGE[c];
				controls += `<div class="row"><small class="lab">${NAME[c]}</small>
					<input type="range" id="${c}r-${d.key}-${p}" min="${lo}" max="${hi}" step="1" aria-label="${d.name}, ${TITLES[p]}, ${NAME[c]} slider">
					<input type="number" id="${c}n-${d.key}-${p}" min="${lo}" max="${hi}" step="1" aria-label="${d.name}, ${TITLES[p]}, ${NAME[c]}, percent"> %</div>`;
			}
			cell.innerHTML = `<h3>${TITLES[p]}</h3><canvas id="c-${d.key}-${p}" width="${W}" height="${H}" aria-label="${d.name}, ${TITLES[p]}"></canvas><div class="info"></div>${controls}`;
			row.append(cell);
			["s", "x", "y"].forEach((c, i) => {
				const lim = c === "s" ? [10, 300] : [-100, 100];
				const on = e => { const n = Math.round(Number(e.target.value)); if (n >= lim[0] && n <= lim[1]) { set[d.key + ":" + p][i] = n; redraw(d.key + ":" + p); } };
				cell.querySelector(`#${c}n-${d.key}-${p}`).addEventListener("input", on);
				cell.querySelector(`#${c}r-${d.key}-${p}`).addEventListener("input", on);
			});
		}
		root.append(sec);
	}
	for (const id of ["guide", "tiers"]) document.getElementById(id).addEventListener("change", () => redraw());
	document.getElementById("reset").addEventListener("click", () => { for (const k in set) set[k] = [...start[k]]; redraw(); });
	document.getElementById("copy").addEventListener("click", async () => {
		const note = document.getElementById("note");
		try { await navigator.clipboard.writeText(table()); note.textContent = "Copied."; }
		catch { note.textContent = "Copy failed; select the table below instead."; }
	});
}

(async () => {
	const srcs = [...new Set(DATA.dragons.flatMap(d => [d.figure, d.lair]))];
	const got = await Promise.all(srcs.map(load));
	srcs.forEach((s, i) => imgs[s] = got[i]);
	build();
	redraw();
})();
</script>
</body>
</html>
"""

if __name__ == "__main__":
	main()

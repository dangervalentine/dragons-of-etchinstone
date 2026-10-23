"""Writes build/bone-editor/index.html: each dragon's whole picture (<id>-full) moving
as the game moves it, with its soft bones (Art.BONES) drawn over it to drag and edit,
to calibrate the dragons' idle animation by eye.

The picture is drawn by a WebGL port of ui/fx/shaders/creature_idle.gdshader (the
breath and the bones; the dragons do not sway), fed the bones as ui/fx/creature.gd
feeds them, so what moves here moves the same in the game. Each bone is its joint and
tip (drag either), its reach (the art within three quarters of it moves fully, fading
to nothing at it), its motion (swing, rise or still), angle, period and phase, and its
chain: a bone carries the bones after it in its chain. At most 8 bones a picture.

The page reads the art straight from art/painted/ (open it from the repository, as a
file) and gives back each picture's BONES entry to paste into ui/model/art.gd.

Run:
  python tools/bone_editor.py            # then open build/bone-editor/index.html
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "build", "bone-editor")


def read(path):
	with open(os.path.join(ROOT, path), encoding="utf-8") as f:
		return f.read()


def bones_of(art, name):
	"""The bones listed for `name` in Art.BONES, as dictionaries."""
	m = re.search(r'\n\t"%s": \[\n(.*?)\n\t\],' % re.escape(name), art, re.S)
	if not m:
		return []
	out = []
	for line in m.group(1).splitlines():
		line = line.strip()
		if not line.startswith("{"):
			continue
		js = re.sub(r"Vector2\(([^,]+),\s*([^)]+)\)", r"[\1, \2]", line.rstrip(","))
		out.append(json.loads(js))
	return out


def main():
	art = read("ui/model/art.gd")
	speeds = {k: float(v) for k, v in re.findall(r'"([a-z-]+)":\s*([0-9.]+)', re.search(r"const SPEED := \{(.*?)\n\}", art, re.S).group(1))}
	cards = json.loads(read("data/cards.json"))
	dragons = []
	for d in cards["dragons"]:
		key = d["id"]
		dragons.append({
			"key": key, "name": d["name"], "art": key + "-full",
			"bones": bones_of(art, key + "-full"),
			"speed": speeds.get(key, 1.0),
			"figure": "../../art/painted/%s-full.png" % key,
		})
	os.makedirs(OUT, exist_ok=True)
	with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8", newline="\n") as f:
		f.write(PAGE.replace("__DATA__", json.dumps({"dragons": dragons})))
	print("wrote", os.path.relpath(os.path.join(OUT, "index.html"), ROOT))


PAGE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dragon Bones</title>
<style>
:root {
	color-scheme: dark;
	--ground: #0e1517; --stone: #172225; --raised: #213033; --line: #2e3f40; --edge: #64797a;
	--ink: #f1e3d1; --muted: #b4a894; --brass: #dcb35c; --jade: #8fc4a3; --danger: #ee7a62;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--ground); color: var(--ink); font: 500 14px/1.4 "Segoe UI", system-ui, sans-serif; }
main { max-width: 1600px; margin: 0 auto; padding: 20px 16px 64px; display: grid; grid-template-columns: minmax(0, 1fr); gap: 18px; }
main > * { min-width: 0; }
h1 { margin: 0; font-size: 26px; }
p { margin: 0; color: var(--muted); max-width: 95ch; }
.bar { position: sticky; top: 0; z-index: 5; background: var(--ground); border-bottom: 2px solid var(--line);
	display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; padding: 10px 0; }
.bar label { display: flex; gap: 6px; align-items: center; color: var(--muted); }
.tabs { display: flex; gap: 6px; }
button { font: inherit; color: var(--ink); background: var(--raised); border: 2px solid var(--edge); padding: 5px 12px; border-radius: 4px; cursor: pointer; }
button:hover { border-color: var(--brass); }
button[aria-pressed="true"] { border-color: var(--brass); background: var(--stone); }
button:focus-visible, input:focus-visible, select:focus-visible { outline: 3px solid var(--jade); outline-offset: 2px; }
.work { display: grid; grid-template-columns: minmax(0, 560px) minmax(0, 1fr); gap: 16px; align-items: start; }
@media (max-width: 1000px) { .work { grid-template-columns: minmax(0, 1fr); } }
.stage { position: relative; aspect-ratio: 1; background: #1a2326; border: 2px solid var(--line); border-radius: 6px; overflow: hidden;
	background-image: linear-gradient(45deg, #1d2729 25%, transparent 25%, transparent 75%, #1d2729 75%), linear-gradient(45deg, #1d2729 25%, transparent 25%, transparent 75%, #1d2729 75%);
	background-size: 32px 32px; background-position: 0 0, 16px 16px; }
.stage canvas { position: absolute; inset: 0; width: 100%; height: 100%; }
#over { cursor: crosshair; touch-action: none; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 3px 4px; text-align: left; border-bottom: 1px solid var(--line); white-space: nowrap; }
th { color: var(--muted); font-weight: 600; font-size: 13px; }
tr.sel td { background: #24302f; }
td input, td select { width: 62px; font: inherit; color: var(--ink); background: var(--ground); border: 1px solid var(--edge); border-radius: 3px; padding: 2px 4px; }
td input.chain { width: 64px; }
td .sw { display: inline-block; width: 12px; height: 12px; border-radius: 50%; vertical-align: -1px; }
.side { display: grid; gap: 10px; min-width: 0; }
.tablewrap { overflow-x: auto; background: var(--stone); border: 2px solid var(--line); border-radius: 6px; padding: 6px; }
pre { margin: 0; background: #0a1012; border: 2px solid var(--line); border-radius: 4px; padding: 10px; overflow-x: auto; font-size: 13px; }
.note { color: var(--muted); font-size: 13px; }
</style>
</head>
<body>
<main>
<header>
<h1>Dragon Bones</h1>
<p>Each dragon's whole picture, moving as the game moves it, with its bones over it. Drag a bone's joint (round) or tip (square) to move it; pick a row to edit it. The art within three quarters of a bone's reach turns fully with it (inner ring), fading to nothing at its reach (outer ring). A bone carries the bones after it in its chain. Exaggerate multiplies every angle so a small motion is easy to judge; it is not saved.</p>
</header>
<div class="bar">
	<div class="tabs" id="tabs" role="group" aria-label="Dragon"></div>
	<button id="play" aria-pressed="true">Pause</button>
	<label>Exaggerate <input type="range" id="amp" min="1" max="6" step="0.5" value="1"> <span id="ampv">1×</span></label>
	<label><input type="checkbox" id="breath" checked> Breath</label>
	<label><input type="checkbox" id="show" checked> Bones</label>
	<label><input type="checkbox" id="reach" checked> Reach</label>
	<button id="add">Add bone</button>
	<button id="del">Remove bone</button>
	<button id="reset">Reset to art.gd</button>
	<button id="copy">Copy BONES entry</button>
	<span id="note" role="status"></span>
</div>
<div class="work">
	<div class="stage"><canvas id="gl" width="1024" height="1024"></canvas><canvas id="over" width="1024" height="1024" aria-label="Bones over the dragon: drag a joint or a tip"></canvas></div>
	<div class="side">
		<div class="tablewrap"><table>
			<thead><tr><th></th><th>#</th><th>Chain</th><th>Joint x</th><th>y</th><th>Tip x</th><th>y</th><th>Reach</th><th>Motion</th><th>Angle °</th><th>Period</th><th>Phase</th></tr></thead>
			<tbody id="rows"></tbody>
		</table></div>
		<p class="note" id="limit"></p>
		<pre id="out"></pre>
	</div>
</div>
</main>
<script>
const DATA = __DATA__;
const MAX = 8, MOVES = { still: 0, swing: 1, rise: 2 };
const COLOURS = ["#ee7a62", "#8fc4a3", "#dcb35c", "#7fb2e5", "#c59be8", "#f2a65a", "#6fd3c7", "#e8e17a"];
const start = Object.fromEntries(DATA.dragons.map(d => [d.key, JSON.parse(JSON.stringify(d.bones))]));
const state = Object.fromEntries(DATA.dragons.map(d => [d.key, JSON.parse(JSON.stringify(d.bones))]));
let cur = DATA.dragons[0].key, sel = 0, playing = true, t0 = performance.now(), held = 0;

// ---- WebGL: creature_idle.gdshader, painted, breathe, bones -----------------------
const gl = document.getElementById("gl").getContext("webgl", { premultipliedAlpha: false, preserveDrawingBuffer: true });
const VS = `attribute vec2 p; varying vec2 uv; void main(){ uv = vec2(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5); gl_Position = vec4(p, 0.0, 1.0); }`;
const FS = `precision highp float;
varying vec2 uv;
uniform sampler2D tex;
uniform float time, amount, speed;
uniform int breathe, bones;
uniform vec4 bone_lines[8];
uniform vec4 bone_moves[8];
uniform float bone_reach[8];
uniform int bone_last[8];
float inside(vec2 u){ return (u.x < 0.0 || u.x > 1.0 || u.y < 0.0 || u.y > 1.0) ? 0.0 : 1.0; }
vec2 turn(vec2 u, vec2 p, float r){ vec2 c = u - p; return vec2(c.x * cos(r) + c.y * sin(r), c.y * cos(r) - c.x * sin(r)) + p; }
float turned(vec4 m, float t){
	if (m.x < 0.5) return 0.0;
	float p = fract(t / m.z + m.w);
	if (m.x < 1.5) return radians(m.y) * sin(6.2831853 * p);
	return radians(m.y) * (0.5 - 0.5 * cos(6.2831853 * p));
}
float line_distance(vec2 p, vec2 a, vec2 b){ vec2 ab = b - a; float k = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0); return length(p - a - ab * k); }
vec2 moved(int i, vec2 p, float t, float a){
	float w = 0.0; vec4 li = vec4(0.0); vec4 mi = vec4(0.0); int last = 0;
	for (int k = 0; k < 8; k++) { if (k == i) { li = bone_lines[k]; mi = bone_moves[k]; last = bone_last[k]; } }
	for (int j = 0; j < 8; j++) {
		if (j < i || j > last) continue;
		w = max(w, 1.0 - smoothstep(bone_reach[j] * 0.75, bone_reach[j], line_distance(p, bone_lines[j].xy, bone_lines[j].zw)));
	}
	return (turn(p, li.xy, -turned(mi, t) * a) - p) * w;
}
void main(){
	float t = time * speed;
	vec2 u = uv;
	if (breathe == 1) {
		float s = 1.0 + 0.008 * amount * sin(t * 1.5);
		vec2 feet = vec2(0.5, 0.95);
		u = (u - feet) / vec2(1.0 + (s - 1.0) * 0.75, s) + feet;
	}
	for (int i = 0; i < 8; i++) {
		if (i >= bones) break;
		vec2 p = u;
		for (int k = 0; k < 4; k++) p = u - moved(i, p, t, amount);
		u = p;
	}
	vec4 c = texture2D(tex, u) * inside(u);
	gl_FragColor = c;
}`;
function compile(type, src) { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s);
	if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s)); return s; }
const prog = gl.createProgram();
gl.attachShader(prog, compile(gl.VERTEX_SHADER, VS)); gl.attachShader(prog, compile(gl.FRAGMENT_SHADER, FS));
gl.linkProgram(prog); gl.useProgram(prog);
const buf = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, buf);
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
const loc = gl.getAttribLocation(prog, "p"); gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
const U = n => gl.getUniformLocation(prog, n);
gl.enable(gl.BLEND); gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
const textures = {};
function texture(img) {
	const t = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, t);
	gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
	gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
	return t;
}

// Art.bones: each bone's last, the end of its chain.
function withLast(list) {
	return list.map((b, i) => {
		let last = i;
		const chain = b.chain || "";
		while (chain && last + 1 < list.length && (list[last + 1].chain || "") === chain) last++;
		return last;
	});
}

function render(time) {
	const d = DATA.dragons.find(x => x.key === cur), list = state[cur], last = withLast(list);
	gl.viewport(0, 0, 1024, 1024); gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT);
	gl.bindTexture(gl.TEXTURE_2D, textures[cur]);
	const lines = [], moves = [], reach = [], lasts = [];
	for (let i = 0; i < MAX; i++) {
		const b = list[i] || {};
		const j = b.joint || [0, 0], t = b.tip || [0, 0];
		lines.push(j[0] / 512, j[1] / 512, t[0] / 512, t[1] / 512);
		moves.push(MOVES[b.motion || "still"], b.angle || 0, b.period || 1, b.phase || 0);
		reach.push((b.reach || 0) / 512);
		lasts.push(i < list.length ? last[i] : i);
	}
	gl.uniform4fv(U("bone_lines"), lines); gl.uniform4fv(U("bone_moves"), moves);
	gl.uniform1fv(U("bone_reach"), reach); gl.uniform1iv(U("bone_last"), lasts);
	gl.uniform1i(U("bones"), list.length);
	gl.uniform1f(U("time"), time); gl.uniform1f(U("speed"), d.speed);
	gl.uniform1f(U("amount"), Number(document.getElementById("amp").value));
	gl.uniform1i(U("breathe"), document.getElementById("breath").checked ? 1 : 0);
	gl.uniform1i(U("tex"), 0);
	gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
}

// ---- overlay: bones, reach, handles, dragging -----------------------------------
const over = document.getElementById("over"), og = over.getContext("2d"), S = 1024 / 512;
function drawOver() {
	og.clearRect(0, 0, 1024, 1024);
	if (!document.getElementById("show").checked) return;
	const list = state[cur];
	list.forEach((b, i) => {
		const c = COLOURS[i % COLOURS.length], j = b.joint, t = b.tip, on = i === sel;
		if (document.getElementById("reach").checked) {
			for (const [r, dash] of [[b.reach * 0.75, []], [b.reach, [10, 8]]]) {
				og.save(); og.strokeStyle = c; og.globalAlpha = on ? 0.9 : 0.35; og.lineWidth = on ? 3 : 2; og.setLineDash(dash);
				capsule(j, t, r); og.stroke(); og.restore();
			}
		}
		og.save(); og.strokeStyle = c; og.lineWidth = on ? 6 : 4; og.globalAlpha = on ? 1 : 0.8;
		og.beginPath(); og.moveTo(j[0] * S, j[1] * S); og.lineTo(t[0] * S, t[1] * S); og.stroke();
		og.fillStyle = c; og.beginPath(); og.arc(j[0] * S, j[1] * S, on ? 12 : 9, 0, Math.PI * 2); og.fill();
		const h = on ? 11 : 8; og.fillRect(t[0] * S - h, t[1] * S - h, h * 2, h * 2);
		og.fillStyle = "#0a1012"; og.font = "700 20px Segoe UI, sans-serif"; og.textAlign = "center"; og.textBaseline = "middle";
		og.fillText(i + 1, j[0] * S, j[1] * S + 1);
		og.restore();
	});
}
function capsule(j, t, r) {
	const ax = j[0] * S, ay = j[1] * S, bx = t[0] * S, by = t[1] * S, rr = r * S;
	const ang = Math.atan2(by - ay, bx - ax);
	og.beginPath();
	og.arc(bx, by, rr, ang - Math.PI / 2, ang + Math.PI / 2);
	og.arc(ax, ay, rr, ang + Math.PI / 2, ang + Math.PI * 1.5);
	og.closePath();
}
let drag = null;
function at(e) { const r = over.getBoundingClientRect(); return [(e.clientX - r.left) / r.width * 512, (e.clientY - r.top) / r.height * 512]; }
over.addEventListener("pointerdown", e => {
	const [x, y] = at(e), list = state[cur];
	let best = null, bd = 14;
	list.forEach((b, i) => {
		for (const end of ["joint", "tip"]) {
			const dd = Math.hypot(b[end][0] - x, b[end][1] - y);
			if (dd < bd) { bd = dd; best = { i, end }; }
		}
	});
	if (best) { drag = best; sel = best.i; over.setPointerCapture(e.pointerId); table(); drawOver(); }
});
over.addEventListener("pointermove", e => {
	if (!drag) return;
	const [x, y] = at(e);
	state[cur][drag.i][drag.end] = [Math.round(Math.max(0, Math.min(512, x))), Math.round(Math.max(0, Math.min(512, y)))];
	table(); out(); drawOver(); if (!playing) render(held);
});
over.addEventListener("pointerup", () => { drag = null; });

// ---- the table and the output ---------------------------------------------------
function table() {
	const rows = document.getElementById("rows"), list = state[cur];
	rows.innerHTML = "";
	list.forEach((b, i) => {
		const tr = document.createElement("tr");
		if (i === sel) tr.className = "sel";
		const num = (k, v, step = 1) => `<input type="number" step="${step}" data-k="${k}" value="${v}" aria-label="Bone ${i + 1} ${k}">`;
		tr.innerHTML = `<td><span class="sw" style="background:${COLOURS[i % COLOURS.length]}"></span></td><td>${i + 1}</td>
			<td><input class="chain" data-k="chain" value="${b.chain || ""}" aria-label="Bone ${i + 1} chain"></td>
			<td>${num("jx", b.joint[0])}</td><td>${num("jy", b.joint[1])}</td><td>${num("tx", b.tip[0])}</td><td>${num("ty", b.tip[1])}</td>
			<td>${num("reach", b.reach)}</td>
			<td><select data-k="motion" aria-label="Bone ${i + 1} motion">${["swing", "rise", "still"].map(m => `<option${m === b.motion ? " selected" : ""}>${m}</option>`).join("")}</select></td>
			<td>${num("angle", b.angle ?? 0, 0.5)}</td><td>${num("period", b.period ?? 1, 0.01)}</td><td>${num("phase", b.phase ?? 0, 0.01)}</td>`;
		tr.addEventListener("pointerdown", () => { if (sel !== i) { sel = i; [...rows.children].forEach((r, k) => r.classList.toggle("sel", k === i)); drawOver(); } });
		tr.querySelectorAll("input, select").forEach(el => el.addEventListener("input", () => {
			const k = el.dataset.k, v = el.tagName === "SELECT" || k === "chain" ? el.value : Number(el.value);
			if (k === "jx") b.joint[0] = v; else if (k === "jy") b.joint[1] = v;
			else if (k === "tx") b.tip[0] = v; else if (k === "ty") b.tip[1] = v;
			else if (k === "chain") { if (v) b.chain = v; else delete b.chain; }
			else b[k] = v;
			out(); drawOver(); if (!playing) render(held);
		}));
		rows.append(tr);
	});
	document.getElementById("limit").textContent = `${list.length} of ${MAX} bones. Bones apply in order: one listed after another rides on it; a chain's bones must sit together, root first.`;
}
const num = v => (Math.round(v * 100) / 100).toString().replace(/^(-?\d+)$/, "$1.0");
function bone(b) {
	const parts = [];
	if (b.chain) parts.push(`"chain": "${b.chain}"`);
	parts.push(`"joint": Vector2(${Math.round(b.joint[0])}, ${Math.round(b.joint[1])})`, `"tip": Vector2(${Math.round(b.tip[0])}, ${Math.round(b.tip[1])})`);
	parts.push(`"reach": ${num(b.reach)}`, `"motion": "${b.motion}"`);
	if (b.motion !== "still") {
		parts.push(`"angle": ${num(b.angle ?? 0)}`, `"period": ${num(b.period ?? 1)}`);
		if (b.phase) parts.push(`"phase": ${Math.round(b.phase * 100) / 100}`);
	}
	return `\t\t{${parts.join(", ")}},`;
}
function entry() {
	const d = DATA.dragons.find(x => x.key === cur);
	return `\t"${d.art}": [\n` + state[cur].map(bone).join("\n") + "\n\t],";
}
function out() { document.getElementById("out").textContent = entry(); }

// ---- controls ---------------------------------------------------------------------
function choose(key) {
	cur = key; sel = 0;
	document.querySelectorAll("#tabs button").forEach(b => b.setAttribute("aria-pressed", String(b.dataset.key === key)));
	table(); out(); drawOver(); if (!playing) render(held);
}
function build() {
	const tabs = document.getElementById("tabs");
	for (const d of DATA.dragons) {
		const b = document.createElement("button");
		b.textContent = d.name; b.dataset.key = d.key;
		b.addEventListener("click", () => choose(d.key));
		tabs.append(b);
	}
	document.getElementById("play").addEventListener("click", e => {
		playing = !playing; e.target.textContent = playing ? "Pause" : "Play"; e.target.setAttribute("aria-pressed", String(playing));
		if (playing) t0 = performance.now() - held * 1000;
	});
	const amp = document.getElementById("amp");
	amp.addEventListener("input", () => { document.getElementById("ampv").textContent = amp.value + "×"; if (!playing) render(held); });
	for (const id of ["breath"]) document.getElementById(id).addEventListener("change", () => { if (!playing) render(held); });
	for (const id of ["show", "reach"]) document.getElementById(id).addEventListener("change", drawOver);
	document.getElementById("add").addEventListener("click", () => {
		const list = state[cur];
		if (list.length >= MAX) { document.getElementById("note").textContent = "The shader bends at most 8 bones."; return; }
		const b = list[sel] || { joint: [256, 256], tip: [320, 256] };
		list.splice(sel + 1, 0, { chain: b.chain, joint: [...b.tip], tip: [b.tip[0] + 40, b.tip[1]], reach: 30, motion: "swing", angle: 2.5, period: 7, phase: 0 });
		if (!b.chain) delete list[sel + 1].chain;
		sel = Math.min(sel + 1, list.length - 1); table(); out(); drawOver();
	});
	document.getElementById("del").addEventListener("click", () => {
		const list = state[cur]; if (!list.length) return;
		list.splice(sel, 1); sel = Math.max(0, sel - 1); table(); out(); drawOver();
	});
	document.getElementById("reset").addEventListener("click", () => { state[cur] = JSON.parse(JSON.stringify(start[cur])); sel = 0; table(); out(); drawOver(); });
	document.getElementById("copy").addEventListener("click", async () => {
		const note = document.getElementById("note");
		try { await navigator.clipboard.writeText(entry()); note.textContent = "Copied."; }
		catch { note.textContent = "Copy failed; select the entry below instead."; }
	});
}

function frame(now) {
	if (playing) held = (now - t0) / 1000;
	render(held);
	requestAnimationFrame(frame);
}

(async () => {
	for (const d of DATA.dragons) {
		const img = await new Promise(ok => { const i = new Image(); i.onload = () => ok(i); i.onerror = () => ok(null); i.src = d.figure; });
		if (img) textures[d.key] = texture(img);
	}
	build();
	choose(cur);
	requestAnimationFrame(frame);
})();
</script>
</body>
</html>
"""

if __name__ == "__main__":
	main()

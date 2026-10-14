import json, sys
out = sys.argv[1]
A, M, F = "attack", "move", "flex"
N = None
# level row: (encounter, hardship, init, basic_type, basic, enh_type, enh, boost, armor, armor_colored, cost)
# encounter: "E3" = enemy 3, "J4" = journey (route) 4
MAGES = [
 ("blue-1", "blue", "red", "c-000/c-010", [
  ("E3","hazards",2,A,3,A,6,1,2,0,1), ("E2",N,3,A,5,A,8,1,2,0,3), ("E4",N,3,A,6,A,11,2,3,0,4), ("E4",N,4,A,7,A,14,3,5,0,N)]),
 ("blue-2", "blue", "purple", "c-001/c-011", [
  ("J4",N,5,M,2,M,4,1,2,0,2), ("J1",N,6,M,3,M,6,2,2,0,4), ("J2",N,8,M,5,M,9,3,5,0,5), ("J4","storm",9,M,8,M,12,5,5,1,N)]),
 ("blue-3", "blue", "yellow", "c-002/c-012", [
  ("E3",N,2,F,2,F,3,2,1,0,2), ("E4",N,3,F,3,F,5,3,2,0,3), ("E2",N,4,F,4,F,7,4,3,0,4), ("E2","hazards",4,F,6,F,9,5,3,1,N)]),
 ("blue-4", "blue", "blue", "c-003/c-013", [
  ("J4",N,5,M,3,M,5,1,2,0,2), ("J3","night_travel",5,M,5,M,9,2,3,0,4), ("J4",N,6,M,6,M,11,4,3,1,6), ("J2",N,7,M,8,M,14,5,4,1,N)]),
 ("purple-1", "purple", "red", "c-004/c-014", [
  ("E1","hazards",1,A,2,A,6,1,1,0,2), ("E1",N,1,A,3,A,8,2,1,0,4), ("E3",N,2,A,5,A,10,2,2,1,5), ("E4",N,3,A,6,A,13,3,3,1,N)]),
 ("purple-2", "purple", "blue", "c-005/c-015", [
  ("J2",N,4,A,2,A,4,2,1,0,2), ("J1","night_travel",6,A,3,A,6,2,2,0,3), ("J3",N,8,A,4,A,7,3,3,0,4), ("J1",N,10,A,6,A,10,4,4,0,N)]),
 ("purple-3", "purple", "purple", "c-006/c-016", [
  ("J2",N,4,A,2,A,3,1,2,0,1), ("J2","storm",5,A,3,A,5,2,2,1,3), ("J1",N,6,A,4,A,7,4,4,1,4), ("J3",N,7,A,6,A,10,5,6,1,N)]),
 ("purple-4", "purple", "yellow", "c-007/c-017", [
  ("E1","ambush",1,M,2,A,4,2,1,0,1), ("E3",N,1,M,3,A,5,3,2,0,3), ("E1",N,2,M,5,A,9,4,2,1,4), ("E2",N,3,M,6,A,11,5,3,1,N)]),
 ("red-1", "red", "yellow", "c-020/c-030", [
  ("E2","ambush",2,F,2,F,3,2,1,0,2), ("E3",N,3,F,3,F,5,3,2,0,3), ("E1",N,4,F,4,F,7,4,3,0,4), ("E2",N,4,F,6,F,9,5,3,1,N)]),
 ("red-2", "red", "blue", "c-021/c-031", [
  ("J3",N,4,M,2,M,4,1,2,0,1), ("J3",N,5,M,4,M,8,2,2,1,3), ("J4","night_travel",7,M,5,M,10,3,3,1,4), ("J1",N,9,M,6,M,12,5,5,1,N)]),
 ("red-3", "red", "purple", "c-022/c-032", [
  ("J3","storm",4,A,2,A,3,1,2,0,1), ("J4",N,5,A,3,A,5,2,2,1,3), ("J2",N,6,A,4,A,7,4,4,1,4), ("J3",N,7,A,6,A,10,5,6,1,N)]),
 ("red-4", "red", "red", "c-023/c-033", [
  ("E2","hazards",1,M,2,M,4,1,1,0,2), ("E1",N,1,M,3,M,5,2,1,0,4), ("E3",N,2,M,4,M,7,2,2,1,5), ("E4",N,3,M,5,M,9,3,3,1,N)]),
 ("yellow-1", "yellow", "purple", "c-024/c-034", [
  ("J1",N,5,M,2,M,4,1,2,0,2), ("J2",N,6,M,3,M,6,2,2,0,4), ("J3","storm",8,M,5,M,9,3,5,0,5), ("J4",N,9,M,8,M,12,5,5,1,N)]),
 ("yellow-2", "yellow", "blue", "c-025/c-035", [
  ("J1",N,5,M,3,M,5,1,2,0,2), ("J4",N,5,M,5,M,9,2,3,0,4), ("J1",N,6,M,6,M,11,4,3,1,6), ("J2","night_travel",7,M,8,M,14,5,4,1,N)]),
 ("yellow-3", "yellow", "yellow", "c-026/c-036", [
  ("E4",N,2,A,3,M,5,2,2,0,2), ("E4",N,3,A,4,M,7,3,3,0,3), ("E2","ambush",4,A,5,M,9,5,3,0,5), ("E2",N,5,A,5,M,12,6,4,1,N)]),
 ("yellow-4", "yellow", "red", "c-027/c-037", [
  ("E4",N,2,A,3,A,6,1,2,0,1), ("E2",N,3,A,5,A,8,1,2,0,3), ("E4","ambush",3,A,6,A,11,2,3,0,4), ("E1",N,4,A,7,A,14,3,5,0,N)]),
]
NAMES = {"blue-1": "Rain of Blood", "blue-2": "River Swiftness", "blue-3": "Adapt", "blue-4": "Fleet Footed",
 "purple-1": "Destruction", "purple-2": "Sword of Light", "purple-3": "Frostfire Wall", "purple-4": "Brute Force",
 "red-1": "Adapt", "red-2": "Motivated Flight", "red-3": "Frostfire Wall", "red-4": "Burning Bridges",
 "yellow-1": "River Swiftness", "yellow-2": "Fleet Footed", "yellow-3": "Determined March", "yellow-4": "Rain of Blood"}
ELEMENTS = {"red": "fire", "purple": "water", "blue": "lightning", "yellow": "shadow"}
DRAGON_NAMES = {"red": "Red Dragon", "violet": "Blue Dragon", "blue": "Yellow Dragon", "yellow": "Gray Dragon"}
REGION_NAMES = {1: "Jade Mountains", 2: "Living Marshes", 3: "Burning Basin", 4: "Forest of Gath"}
mages = []
for cid, color, ecolor, src, rows in MAGES:
    levels = []
    for i, (enc, hard, init, bt, bv, et, ev, boost, arm, armc, cost) in enumerate(rows):
        levels.append({
            "level": i + 1,
            "encounter": {"type": "enemy" if enc[0] == "E" else "journey", "index": int(enc[1])},
            "hardship": hard, "initiative": init,
            "basic": {"type": bt, "value": bv},
            "enhanced": {"type": et, "value": ev, "color": ecolor},
            "boost": boost,
            "armor": {"value": arm, "color": ecolor if armc else None},
            "upgrade_cost": cost})
    mages.append({"id": cid, "name": NAMES[cid], "color": color, "element": ELEMENTS[color], "source": src, "levels": levels})

def en(hp, init, atk, acolor, armor, xp, ability=None):
    return {"hp": hp, "initiative": init, "attack": {"value": atk, "color": acolor},
            "armor": [{"color": c, "value": v} for c, v in armor], "ability": ability, "xp": xp}
def jo(mp, color, tp, xp, peril=None):
    return {"mp": {"value": mp, "color": color}, "time_penalty": tp, "peril": peril, "xp": xp}
regions = [
 {"region": 1, "source": "c-040", "enemies": [
   en(7,8,1,"blue",[("blue",1)],4), en(11,4,2,"red",[("red",1)],7),
   en(9,6,2,"purple",[("purple",2)],5), en(13,2,3,"yellow",[("yellow",3)],8)],
  "journeys": [jo(12,"blue",2,5), jo(8,"purple",1,3), jo(11,"red",2,4), jo(10,"yellow",1,3)]},
 {"region": 2, "source": "c-048", "enemies": [
   en(9,6,2,"yellow",[("yellow",1)],5,"ranged"), en(10,8,2,"blue",[("blue",1)],4),
   en(15,2,4,"red",[("red",3)],8,"slow"), en(13,5,3,"purple",[("purple",2)],7,"freeze")],
  "journeys": [jo(10,"red",2,4,"treacherous"), jo(13,"purple",2,7), jo(11,"blue",3,5), jo(9,"yellow",2,4,"steep")]},
 {"region": 3, "source": "c-041", "enemies": [
   en(17,5,3,"yellow",[("yellow",3)],9), en(14,4,3,"purple",[("purple",3)],8,"slow"),
   en(11,9,2,"red",[("red",2)],7,"poison"), en(9,7,2,"blue",[("blue",2)],5,"ranged")],
  "journeys": [jo(14,"purple",2,7,"steep"), jo(12,"blue",3,6), jo(10,"red",3,5,"treacherous"), jo(11,"yellow",2,5)]},
 {"region": 4, "source": "c-049", "enemies": [
   en(13,6,2,"yellow",[("yellow",3),("purple",2)],7,"poison"), en(9,10,3,"red",[("red",1)],5,"ranged"),
   en(14,8,4,"blue",[("blue",2),("red",2)],8,"freeze"), en(17,7,5,"purple",[("purple",3),("yellow",2)],9)],
  "journeys": [jo(14,"purple",2,7,"treacherous"), jo(13,"yellow",3,6), jo(12,"red",2,5), jo(11,"blue",3,5,"steep")]},
]
def dr(did, src, init, early, ecolor, armor, mp, hp):
    return {"id": did, "name": DRAGON_NAMES.get(did, ""), "in_pnp_2_0": did in DRAGON_NAMES, "source": src, "initiative": init,
            "early_damage": {"value": early, "color": ecolor},
            "armor": [{"color": c, "value": v} for c, v in armor],
            "mp_tiers": [{"mp": {"value": v, "color": c}, "time_penalty": t} for v, c, t in mp],
            "hp_tiers": [{"hp": h, "attack": {"value": a, "color": c}} for h, a, c in hp]}
dragons = [
 dr("blue","c-042",13,8,"blue",[("blue",4),("red",1)],
    [(17,"blue",4),(21,"blue",3),(25,"blue",2)], [(16,23,"blue"),(21,20,"blue"),(29,13,"blue")]),
 dr("red","c-043",9,9,"red",[("red",4)],
    [(20,"red",3),(23,"red",2),(28,"red",1)], [(22,27,"red"),(27,24,"red"),(32,15,"red")]),
 dr("magenta","c-045",14,6,"purple",[("purple",3),("yellow",2),("blue",1)],
    [(20,"purple",4),(25,"purple",3),(30,"purple",2)], [(20,20,"purple"),(23,16,"purple"),(26,10,"purple")]),
 dr("violet","c-050",10,4,"purple",[("purple",5),("blue",3),("yellow",2)],
    [(15,"purple",4),(21,"purple",3),(27,"purple",1)], [(22,26,"purple"),(25,20,"purple"),(31,11,"purple")]),
 dr("white","c-052",12,6,"purple",[("red",4),("blue",3),("yellow",2)],
    [(19,"yellow",2),(23,"purple",1),(29,"red",3)], [(21,26,"blue"),(26,20,"purple"),(30,12,"yellow")]),
 dr("yellow","c-053",12,6,"yellow",[("yellow",4),("purple",3)],
    [(19,"yellow",3),(23,"yellow",2),(29,"yellow",1)], [(21,26,"yellow"),(26,20,"yellow"),(30,12,"yellow")]),
]
for r in regions: r["name"] = REGION_NAMES.get(r["region"], "")
doc = {"version": 2, "source": "pixel-card-variant-v1.0.pdf", "cross_checked_against": "Dragons of Etchinstone PNP - Gutter Fold - 2.0 (mage cards only)",
       "color_elements": ELEMENTS,
       "colors": ["blue", "purple", "red", "yellow"],
       "level_labels": ["INJ", "BASIC", "HIGH", "MAX"],
       "mage_cards": mages, "regions": regions, "dragons": dragons}
CODES = {"purple-4": "DOE-A01", "purple-2": "DOE-A02", "purple-1": "DOE-A03", "purple-3": "DOE-A04",
 "blue-1": "DOE-A05", "blue-4": "DOE-A06", "blue-3": "DOE-A07", "blue-2": "DOE-A08",
 "yellow-1": "DOE-A09", "yellow-4": "DOE-A10", "yellow-3": "DOE-A11", "yellow-2": "DOE-A12",
 "red-1": "DOE-A13", "red-3": "DOE-A14", "red-4": "DOE-A15", "red-2": "DOE-A16"}
DRAGONS = {"red": ("rodving", "Rodving", "The Last Breath", "DOE-D01"), "blue": ("vuurhast", "Vuurhast", "Death and Darkness", "DOE-D01"),
 "yellow": ("helsang", "Helsang", "The Undying", "DOE-D02"), "violet": ("grimroch", "Grimroch", "Scales of Stone", "DOE-D02")}
REGION_CARDS = {1: "DOE-R01", 2: "DOE-R01", 3: "DOE-R02", 4: "DOE-R02"}
def conv(x):
    if isinstance(x, dict):
        return {("element" if k == "color" else k): (ELEMENTS.get(v, v) if k == "color" else conv(v)) for k, v in x.items()}
    if isinstance(x, list):
        return [conv(i) for i in x]
    return x
om = []
for m in mages:
    c = conv(m)
    om.append({"id": CODES[m["id"]], "name": c["name"], "element": c["element"], "pixel_variant_id": m["id"], "levels": c["levels"]})
om.sort(key=lambda m: m["id"])
orr = [{"region": r["region"], "name": r["name"], "card": REGION_CARDS[r["region"]], "enemies": conv(r["enemies"]), "journeys": conv(r["journeys"])} for r in regions]
od, vd = [], []
for d in dragons:
    c = conv(d); c.pop("in_pnp_2_0"); c.pop("source"); c.pop("name"); pid = c.pop("id")
    if pid in DRAGONS:
        i, n, t, card = DRAGONS[pid]
        od.append({"id": i, "name": n, "title": t, "card": card, **c})
    else:
        vd.append({"id": "pixel-" + pid, "name": "", **c})
od.sort(key=lambda d: d["id"])
doc = {"version": 3,
       "source": "Chip Theory Games retail cards (scan 2026-10-13); cross-checked against PNP Gutter Fold 2.0 and pixel-card-variant v1.0",
       "elements": ["fire", "water", "lightning", "shadow"],
       "mage_cards": om, "regions": orr, "dragons": od, "variant_dragons": vd}
json.dump(doc, open(out, "w"), indent=2); open(out, "a").write("\n")
# sanity checks
for m in mages:
    L = m["levels"]
    assert len(L) == 4 and L[3]["upgrade_cost"] is None and all(l["upgrade_cost"] for l in L[:3]), m["id"]
    for k in ("initiative", "boost"):
        v = [l[k] for l in L]; assert v == sorted(v), (m["id"], k, v)
    for k in ("basic", "enhanced", "armor"):
        v = [l[k]["value"] for l in L]; assert v == sorted(v), (m["id"], k, v)
    assert all(l["enhanced"]["value"] > l["basic"]["value"] for l in L), m["id"]
from collections import Counter
for lv in range(4):
    c = Counter((m["levels"][lv]["encounter"]["type"], m["levels"][lv]["encounter"]["index"]) for m in mages)
    print("level", lv + 1, "encounters:", dict(sorted(c.items())))
print("cards", len(mages), "regions", len(regions), "dragons", len(dragons))

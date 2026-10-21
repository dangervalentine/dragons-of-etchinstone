// Gives every creature in an Illustrator folder the common 512 x 512 artboard and
// the framing guides of tools/frame_art.py, at 512 units: sides at 32 and 480, top
// at 24, feet on 490. No art is moved. An artboard already 512 x 512 is kept as it
// is; any other is replaced by one centred across the art, its lowest point on the
// floor line, ready to be fine-tuned by hand. The guides go on a locked layer named
// "guides", remade on every run. Each file is saved in place, and a report written
// to frame-log.txt beside them.
//
// Run: Illustrator > File > Scripts > Other Script... > this file. Asks for the
// folder; every .ai in it is done (not .ait templates).

#target illustrator

var SIZE = 512;
var LEFT = 32, RIGHT = 480, TOP = 24, FLOOR = 490;

function artBounds(doc) {
	// The box round all visible art, guides and invisible paths left out.
	var b = null;
	for (var i = 0; i < doc.layers.length; i++) {
		var layer = doc.layers[i];
		if (!layer.visible || layer.name == "guides") continue;
		for (var j = 0; j < layer.pageItems.length; j++) {
			var item = layer.pageItems[j];
			if (item.hidden) continue;
			if (item.typename == "PathItem" && (item.guides || (!item.filled && !item.stroked && !item.clipping))) continue;
			var v = item.visibleBounds;
			b = b == null ? v : [Math.min(b[0], v[0]), Math.max(b[1], v[1]), Math.max(b[2], v[2]), Math.min(b[3], v[3])];
		}
	}
	return b;
}

function guide(layer, a, z) {
	var p = layer.pathItems.add();
	p.setEntirePath([a, z]);
	p.guides = true;
}

function frame(doc) {
	var board = doc.artboards[0];
	var r = board.artboardRect;
	var note = "";
	if (Math.round(r[2] - r[0]) != SIZE || Math.round(r[1] - r[3]) != SIZE) {
		var b = artBounds(doc);
		if (b == null) return "no art found, left alone";
		var left = Math.round((b[0] + b[2]) / 2 - SIZE / 2);
		var top = Math.round(b[3] + FLOOR);
		board.artboardRect = [left, top, left + SIZE, top - SIZE];
		r = board.artboardRect;
		note = "artboard set";
		if (b[2] - b[0] > SIZE || b[1] - b[3] > FLOOR) note += ", ART LARGER THAN THE FRAME (scale it down)";
	} else {
		note = "artboard already 512, kept";
	}
	if (doc.artboards.length > 1) note += ", has " + doc.artboards.length + " artboards (only the first done)";

	var layer;
	try {
		layer = doc.layers.getByName("guides");
		layer.locked = false;
		layer.visible = true;
		while (layer.pageItems.length > 0) layer.pageItems[0].remove();
	} catch (e) {
		layer = doc.layers.add();
		layer.name = "guides";
	}
	layer.zOrder(ZOrderMethod.BRINGTOFRONT);
	var x0 = r[0], y0 = r[1];
	guide(layer, [x0 - 20, y0 - FLOOR], [x0 + SIZE + 20, y0 - FLOOR]);
	guide(layer, [x0 - 20, y0 - TOP], [x0 + SIZE + 20, y0 - TOP]);
	guide(layer, [x0 + LEFT, y0 + 20], [x0 + LEFT, y0 - SIZE - 20]);
	guide(layer, [x0 + RIGHT, y0 + 20], [x0 + RIGHT, y0 - SIZE - 20]);
	layer.locked = true;
	return note;
}

function main() {
	var folder = Folder.selectDialog("The folder of creature .ai files");
	if (folder == null) return;
	var files = folder.getFiles(function (f) { return f instanceof File && /\.ai$/i.test(f.name); });
	var log = [];
	var was = app.userInteractionLevel;
	app.userInteractionLevel = UserInteractionLevel.DONTDISPLAYALERTS;
	app.coordinateSystem = CoordinateSystem.DOCUMENTCOORDINATESYSTEM;
	try {
		for (var i = 0; i < files.length; i++) {
			var name = decodeURI(files[i].name);
			try {
				var doc = app.open(files[i]);
				var note = frame(doc);
				doc.save();
				doc.close(SaveOptions.DONOTSAVECHANGES);
				log.push(name + ": " + note);
			} catch (e) {
				log.push(name + ": FAILED, " + e);
			}
		}
	} finally {
		app.userInteractionLevel = was;
	}
	var out = new File(folder.fsName + "/frame-log.txt");
	out.open("w");
	out.write(log.join("\n"));
	out.close();
	alert(files.length + " files done; see frame-log.txt\n\n" + log.join("\n"));
}

main();

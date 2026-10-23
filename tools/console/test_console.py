"""The console's own tests (specs/018): the parts that decide things, without Godot,
the stores or a terminal. Run: scripts/etch selftest"""
import sys
from pathlib import Path

import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import art_import  # noqa: E402
import cfg  # noqa: E402
import preflight  # noqa: E402
from env import parse  # noqa: E402
from version import Files, Version  # noqa: E402

SLOTS = {"enemies": ["naga", "antler-horror"], "journeys": ["peaks"], "dragons": ["grimroch", "helsang"]}

PRESETS = """[preset.0]

name="Android"
platform="Android"

[preset.0.options]

package/name="Dragons of Etchinstone"
version/code=7

[preset.1]

name="iOS"
platform="iOS"

[preset.1.options]

application/bundle_identifier="com.example"

[preset.2]

name="Android Release"
platform="Android"

[preset.2.options]

gradle_build/export_format=1
"""

PROJECT = """config_version=5

[application]

config/name="Dragons of Etchinstone"
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1280
"""


# --- .env -------------------------------------------------------------------------------

def test_env_parse_skips_comments_quotes_and_empty_values():
    text = '# a comment\nA=1\nexport B="two words"\nC=\'x\'\nEMPTY=\n\nNOEQUALS\n'
    assert parse(text) == {"A": "1", "B": "two words", "C": "x"}


# --- cfg ----------------------------------------------------------------------------------

def test_cfg_replaces_a_key_in_place():
    out = cfg.set(PRESETS, "preset.0.options", "version/code", "8")
    assert cfg.get(out, "preset.0.options", "version/code") == "8"
    assert out.count("version/code") == 1


def test_cfg_adds_a_missing_key_after_the_sections_last_key():
    out = cfg.set(PROJECT, "application", "config/version", '"1.0.0"')
    assert 'config/icon="res://icon.svg"\nconfig/version="1.0.0"\n\n[display]' in out


def test_cfg_adds_a_missing_section():
    out = cfg.set(PROJECT, "audio", "x", "1")
    assert out.endswith("[audio]\n\nx=1\n")


def test_cfg_finds_a_preset_by_name_not_by_number():
    assert cfg.preset_options(PRESETS, "Android Release") == "preset.2.options"
    assert cfg.preset_options(PRESETS, "Android") == "preset.0.options"
    assert cfg.preset_options(PRESETS, "Windows") is None


# --- version ------------------------------------------------------------------------------

@pytest.mark.parametrize("step,expected", [
    ("build", "1.4.2"), ("patch", "1.4.3"), ("minor", "1.5.0"), ("major", "2.0.0")])
def test_every_step_raises_the_build_number(step, expected):
    assert Version("1.4.2", 9).next(step) == Version(expected, 10)


@pytest.fixture
def project(tmp_path):
    (tmp_path / "project.godot").write_text(PROJECT, encoding="utf-8")
    (tmp_path / "export_presets.cfg").write_text(PRESETS, encoding="utf-8")
    return tmp_path


def test_a_project_with_no_version_reads_as_0_0_0_and_the_highest_build(project):
    assert Files(project).read() == Version("0.0.0", 7)


def test_write_sets_every_preset_and_restore_puts_back_the_exact_text(project):
    files = Files(project)
    files.write(Version("1.0.0", 8))
    presets = (project / "export_presets.cfg").read_text(encoding="utf-8")
    assert cfg.get(presets, "preset.0.options", "version/code") == "8"
    assert cfg.get(presets, "preset.2.options", "version/code") == "8"
    assert cfg.get(presets, "preset.1.options", "application/version") == '"8"'
    assert Files(project).read() == Version("1.0.0", 8)
    files.restore()
    assert (project / "export_presets.cfg").read_text(encoding="utf-8") == PRESETS
    assert (project / "project.godot").read_text(encoding="utf-8") == PROJECT


# --- art import -----------------------------------------------------------------------------

@pytest.mark.parametrize("stem,name", [
    ("antler-horror-126-01", "antler-horror"),
    ("grimroch-140-full-01", "grimroch-full"),
    ("Antler Horror_1_", "antler-horror"),
    ("naga", "naga"),
])
def test_clean_name_drops_illustrators_numbers(stem, name):
    assert art_import.clean_name(stem) == name


@pytest.fixture
def staging(tmp_path, monkeypatch):
    monkeypatch.setattr(art_import, "PAINTED", tmp_path / "painted")
    monkeypatch.setattr(art_import, "CREATURES", tmp_path / "creatures")
    (tmp_path / "staging").mkdir()
    return tmp_path / "staging"


def _image(path: Path, size, mode="RGBA", clear=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    im = Image.new(mode, size, (0, 0, 0, 0) if mode == "RGBA" and clear else "white")
    im.save(path)


def _scan(staging):
    items = art_import.scan(SLOTS, staging)
    for i in items:
        art_import.check(i)
    return {i.src.name: i for i in items}


def test_a_staged_file_fills_the_slot_its_folder_and_name_say(staging, tmp_path):
    _image(staging / "enemies" / "naga-122-01.png", (1024, 1024))
    _image(staging / "dragons" / "helsang-122-head-01.png", (1024, 1024))
    _image(staging / "backdrops" / "naga.png", (1216, 896), "RGB")
    items = _scan(staging)
    assert items["naga-122-01.png"].dest == tmp_path / "painted" / "naga.png"
    assert items["helsang-122-head-01.png"].dest == tmp_path / "painted" / "helsang-head.png"
    assert items["naga.png"].dest == tmp_path / "painted" / "backdrops" / "naga.png"
    assert all(not i.errors and not i.warnings for i in items.values())


def test_an_unknown_name_is_an_error_with_the_nearest_slot(staging):
    _image(staging / "enemies" / "nagaa.png", (1024, 1024))
    error = _scan(staging)["nagaa.png"].errors[0]
    assert "Did you mean naga?" in error and "antler-horror" in error


def test_files_outside_a_kind_folder_or_of_the_wrong_type_are_errors(staging):
    _image(staging / "naga.png", (1024, 1024))
    _image(staging / "monsters" / "naga.png", (1024, 1024))
    _image(staging / "rigs" / "grimroch-parts.png", (1024, 1024))
    items = art_import.scan(SLOTS, staging)
    assert len(items) == 3 and all(i.errors for i in items)


def test_illustrator_files_beside_their_exports_are_skipped(staging):
    _image(staging / "lairs" / "vuurhast.png", (832, 1152), "RGB")
    (staging / "lairs" / "vuurhast.ai").write_bytes(b"%PDF")
    items = art_import.scan(SLOTS | {"dragons": ["vuurhast"]}, staging)
    assert [i.src.name for i in items] == ["vuurhast.png"] and not items[0].errors


def test_two_files_for_one_slot_are_both_errors(staging):
    _image(staging / "enemies" / "naga-1-01.png", (1024, 1024))
    _image(staging / "enemies" / "naga-2-01.png", (1024, 1024))
    assert all("two staged files" in i.errors[0] for i in _scan(staging).values())


def test_a_figure_must_be_square_large_and_transparent(staging):
    _image(staging / "enemies" / "naga.png", (1024, 900))
    _image(staging / "enemies" / "antler-horror.png", (1024, 1024), "RGB")
    items = _scan(staging)
    assert "square" in items["naga.png"].errors[0]
    assert "transparency" in items["antler-horror.png"].errors[0]
    _image(staging / "dragons" / "grimroch.png", (512, 512))
    assert "1024" in _scan(staging)["grimroch.png"].errors[0]


def test_a_scene_of_another_shape_than_the_one_it_replaces_is_a_warning(staging, tmp_path):
    _image(tmp_path / "painted" / "journeys" / "peaks.png", (768, 1344), "RGB")
    _image(staging / "journeys" / "peaks.png", (1344, 768), "RGB")
    item = _scan(staging)["peaks.png"]
    assert not item.errors and "shape" in item.warnings[0]
    assert item.old == (768, 1344) and item.new == (1344, 768)


def test_a_rig_needs_the_512_artboard_and_a_head_layer(staging):
    rigs = staging / "rigs"
    rigs.mkdir()
    ok = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><g id="body"/><g id="head_1_"/></svg>'
    (rigs / "grimroch-parts.svg").write_text(ok)
    (rigs / "helsang-parts.svg").write_text(ok.replace("head_1_", "neck").replace("512 512", "600 600"))
    items = _scan(staging)
    assert not items["grimroch-parts.svg"].errors
    errors = " ".join(items["helsang-parts.svg"].errors)
    assert "512 x 512" in errors and "head" in errors


def test_preview_lists_errors_and_sizes(staging, tmp_path):
    _image(tmp_path / "painted" / "naga.png", (1024, 1024))
    _image(staging / "enemies" / "naga.png", (2048, 2048))
    _image(staging / "enemies" / "nobody.png", (1024, 1024))
    text = art_import.preview(list(_scan(staging).values()))
    assert "1024x1024 -> 2048x2048" in text and "ERROR enemies/nobody.png" in text


# --- preflight ------------------------------------------------------------------------------

def test_a_missing_keystore_says_how_to_make_one():
    check = preflight.check_keystore({})
    assert not check.ok
    assert "ANDROID_KEYSTORE_PATH" in check.detail and "keytool -genkeypair" in check.detail


def test_a_keystore_path_that_does_not_exist_is_named(tmp_path):
    check = preflight.check_keystore({"ANDROID_KEYSTORE_PATH": str(tmp_path / "nope.keystore"),
        "ANDROID_KEYSTORE_ALIAS": "a", "ANDROID_KEYSTORE_PASSWORD": "p"})
    assert not check.ok and "nope.keystore" in check.detail


def test_an_app_store_key_must_be_named_as_altool_looks_for_it(tmp_path):
    key = tmp_path / "key.p8"
    key.write_text("x")
    checks = preflight.check_asc({"ASC_KEY_ID": "ABC123", "ASC_ISSUER_ID": "i", "ASC_KEY_PATH": str(key)})
    assert not checks[0].ok and "AuthKey_ABC123.p8" in checks[0].detail


def test_only_the_chosen_platforms_are_checked(monkeypatch):
    monkeypatch.setattr(preflight, "check_godot", lambda: [])
    monkeypatch.setattr(preflight, "check_android", lambda env: [preflight.Check(False, "android")])
    monkeypatch.setattr(preflight, "check_ios", lambda env: [preflight.Check(False, "ios")])
    monkeypatch.setattr(preflight, "check_play", lambda env: [preflight.Check(False, "play")])
    titles = [c.title for c in preflight.checks_for(["web"], ["web"], {})]
    assert titles == []
    titles = [c.title for c in preflight.checks_for(["android"], [], {})]
    assert titles == ["android"]
    titles = [c.title for c in preflight.checks_for(["android", "ios"], ["android"], {})]
    assert titles == ["android", "play", "ios"]


def test_the_report_lists_every_failure_and_says_nothing_changed(capsys):
    ok = preflight.report([preflight.Check(True, "Godot", "4.7.2"),
        preflight.Check(False, "Keystore", "not set\nmake one")])
    out = capsys.readouterr().out
    assert not ok
    assert "FAIL  Keystore" in out and "      make one" in out and "nothing was built or changed" in out

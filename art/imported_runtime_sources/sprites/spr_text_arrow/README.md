# spr_text_arrow Krita master

Exact eight-frame migration from `thpj3/sprites/spr_text_arrow`.

- `spr_text_arrow_frames.kra` is the sole canonical editable master. Edit it in Krita.
- The eight GameMaker root-frame PNGs and required editor-layer PNGs are runtime derivatives rendered directly from the KRA's named layers.
- The production source tree does not keep an ORA, per-frame source exports, or preview mirrors beside the KRA.
- Frames retain the source sequence and its authored 3 fps playback.
- The 64x64 source is drawn at 50% in Selkie's Moon for its 640x360 UI.

Export every declared GameMaker PNG, then verify that the checked-in derivatives
match a fresh Krita render, with:

```sh
python3 tools/export_krita_runtime.py --family text
python3 tools/export_krita_runtime.py --family text --check
```

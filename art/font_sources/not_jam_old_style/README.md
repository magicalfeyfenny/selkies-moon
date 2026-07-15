# Not Jam Old Style runtime serif

The plain menu and dialogue roles use the visibly serifed Not Jam Old Style family:

- `NotJamOldStyle14.ttf` is embedded by `fn_menu` at its native 14-pixel size.
- `NotJamOldStyle11.ttf` is embedded by `fn_dialogue_speech` at its native 11-pixel size.
- `NotJamOldStyleGlyphs.ora` is the layered Krita/OpenRaster source sheet. Its menu and body glyph layers remain separate and exposed.
- `NotJamOldStyleGlyphs.png` is the flattened reference atlas.
- `Licence.txt` is the font author's included CC0 licence notice.

Rebuild the editable sheets, GameMaker glyph atlases, and stored glyph metrics with the bundled workspace Python runtime:

```sh
/Users/magicalfeyfenny/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tools/build_font_source_sheets.py
```

GameMaker font resources keep antialiasing disabled and render on the authored 640x360 pixel grid.

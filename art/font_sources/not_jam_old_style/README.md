# Not Jam Old Style runtime serif

The plain menu and dialogue roles use the visibly serifed Not Jam Old Style family:

- `NotJamOldStyle14.ttf` is the licensed input embedded by `fn_menu` at its native 14-pixel size.
- `NotJamOldStyle11.ttf` is the licensed input embedded by `fn_dialogue_speech` at its native 11-pixel size.
- `NotJamOldStyleGlyphs.kra` is the sole canonical editable glyph-sheet master. Its menu and body glyph layers remain separate and exposed in Krita.
- `Licence.txt` is the font author's included CC0 licence notice.

The production source tree does not maintain an ORA, flattened source PNG, or
preview mirror beside the KRA. The glyph-sheet master is registered as
source-only; the shipped font atlas pixels have separate KRA masters under
`../runtime_atlases/`.

Render all KRA-owned runtime art and verify it against the checked-in PNGs with:

```sh
python3 tools/export_krita_runtime.py --family standalone
python3 tools/export_krita_runtime.py --family standalone --check
```

GameMaker `.yy` files retain their metrics and packing contract; the normal
exporter never rewrites them.

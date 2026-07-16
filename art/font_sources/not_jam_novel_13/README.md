# Not Jam Novel 13 licensed source

Not Jam Novel 13 is retained as licensed source material and an editable glyph
study. It is not the current runtime serif face; menu and dialogue text use the
Not Jam Old Style family documented in `../not_jam_old_style/README.md`.

Source: <https://not-jam.itch.io/not-jam-novel-13>

Not Jam released the font under CC0. `Licence.txt` is the bundled licence copy.
The licensed source pack and its editable study are kept here:

- `Not Jam Novel 13.ttf` is the licensed 13-pixel font input.
- `NotJamNovel13.kra` is the sole canonical editable pixel glyph-sheet master
  and is registered as source-only art.
- `Not Jam Novel 13.json` imports the sheet into YellowAfterlife's Pixel Font
  Converter for inspecting the licensed source metrics and TTF conversion.
- The matching 16-pixel TTF and JSON are retained as an alternate working size.

No ORA, flattened source PNG, or preview mirror is maintained beside the KRA.
Shipped font atlas pixels have separate KRA masters under
`../runtime_atlases/`; their GameMaker `.yy` files retain the glyph metrics and
packing contract. Validate this source-only registration and all declared
standalone font outputs with:

```sh
python3 tools/export_krita_runtime.py --family standalone --check
```

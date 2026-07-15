# Not Jam Novel 13 source

The plain serif UI and dialogue text use **Not Jam Novel 13 Regular** at its
native 13-pixel size with anti-aliasing disabled. The title, subtitle, and
dialogue-name calligraphy remain separate display faces.

Source: <https://not-jam.itch.io/not-jam-novel-13>

Not Jam released the font under CC0. `Licence.txt` is the bundled licence copy.
The source pack is kept intact here:

- `Not Jam Novel 13.ttf` is the runtime face.
- `NotJamNovel13.png` is the editable pixel glyph sheet.
- `NotJamNovel13.ora` imports that sheet as an exposed `Editable Pixel Glyphs`
  layer and opens directly in Krita.
- `Not Jam Novel 13.json` imports the sheet into YellowAfterlife's Pixel Font
  Converter for editing and TTF re-export.
- The matching 16-pixel TTF and JSON are retained as an alternate working size.

The runtime TTF is copied into both GameMaker font resource folders so the
project remains buildable without relying on a user-installed font. After
editing or replacing it, regenerate `fn_menu` and `fn_dialogue_speech` in
GameMaker with anti-aliasing disabled.

# Runtime font atlas masters

Each `.kra` in this directory is the canonical raster master for the matching
GameMaker font texture. The corresponding font `.yy` file remains the
authoritative metrics and packing contract: glyph artwork may be edited in
Krita, but it must stay inside the declared glyph rectangles unless the metrics
are deliberately updated too.

Run `tools/export_krita_runtime.py --family standalone` to render the atlas PNGs
from these masters. The licensed TTF files remain provenance and embedding
inputs; they do not overwrite the KRA masters during a normal build.

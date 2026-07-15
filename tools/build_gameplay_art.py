#!/usr/bin/env python3
"""Build deterministic gameplay sprites and portrait-derived menu silhouettes."""

from __future__ import annotations

import json
import uuid
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Selkie's Moon ~ until we meet again ~"
SPRITES = PROJECT / "sprites"
PORTRAITS = PROJECT / "art" / "character_portraits"
SCALE = 4
RESAMPLE = Image.Resampling.LANCZOS


def stable_uuid(label: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"selkies-moon/gameplay-art/{label}"))


def sprite_metadata(name: str, width: int, height: int, frame: str, layer: str) -> dict:
    sprite_path = f"sprites/{name}/{name}.yy"
    return {
        "$GMSprite": "v2",
        "%Name": name,
        "bboxMode": 0,
        "bbox_bottom": height - 1,
        "bbox_left": 0,
        "bbox_right": width - 1,
        "bbox_top": 0,
        "collisionKind": 1,
        "collisionTolerance": 0,
        "DynamicTexturePage": False,
        "edgeFiltering": False,
        "For3D": False,
        "frames": [{
            "$GMSpriteFrame": "v1",
            "%Name": frame,
            "name": frame,
            "resourceType": "GMSpriteFrame",
            "resourceVersion": "2.0",
        }],
        "gridX": 0,
        "gridY": 0,
        "height": height,
        "HTile": False,
        "layers": [{
            "$GMImageLayer": "",
            "%Name": layer,
            "blendMode": 0,
            "displayName": "default",
            "isLocked": False,
            "name": layer,
            "opacity": 100.0,
            "resourceType": "GMImageLayer",
            "resourceVersion": "2.0",
            "visible": True,
        }],
        "name": name,
        "nineSlice": None,
        "origin": 4,
        "parent": {"name": "Selkies Moon", "path": "Selkies Moon.yyp"},
        "preMultiplyAlpha": False,
        "resourceType": "GMSprite",
        "resourceVersion": "2.0",
        "sequence": {
            "$GMSequence": "v1",
            "%Name": name,
            "autoRecord": True,
            "backdropHeight": 768,
            "backdropImageOpacity": 0.5,
            "backdropImagePath": "",
            "backdropWidth": 1366,
            "backdropXOffset": 0.0,
            "backdropYOffset": 0.0,
            "events": {
                "$KeyframeStore<MessageEventKeyframe>": "",
                "Keyframes": [],
                "resourceType": "KeyframeStore<MessageEventKeyframe>",
                "resourceVersion": "2.0",
            },
            "eventStubScript": None,
            "eventToFunction": {},
            "length": 1.0,
            "lockOrigin": False,
            "moments": {
                "$KeyframeStore<MomentsEventKeyframe>": "",
                "Keyframes": [],
                "resourceType": "KeyframeStore<MomentsEventKeyframe>",
                "resourceVersion": "2.0",
            },
            "name": name,
            "playback": 1,
            "playbackSpeed": 30.0,
            "playbackSpeedType": 0,
            "resourceType": "GMSequence",
            "resourceVersion": "2.0",
            "showBackdrop": True,
            "showBackdropImage": False,
            "timeUnits": 1,
            "tracks": [{
                "$GMSpriteFramesTrack": "",
                "builtinName": 0,
                "events": [],
                "inheritsTrackColour": True,
                "interpolation": 1,
                "isCreationTrack": False,
                "keyframes": {
                    "$KeyframeStore<SpriteFrameKeyframe>": "",
                    "Keyframes": [{
                        "$Keyframe<SpriteFrameKeyframe>": "",
                        "Channels": {"0": {
                            "$SpriteFrameKeyframe": "",
                            "Id": {"name": frame, "path": sprite_path},
                            "resourceType": "SpriteFrameKeyframe",
                            "resourceVersion": "2.0",
                        }},
                        "Disabled": False,
                        "id": stable_uuid(f"{name}/keyframe"),
                        "IsCreationKey": False,
                        "Key": 0.0,
                        "Length": 1.0,
                        "resourceType": "Keyframe<SpriteFrameKeyframe>",
                        "resourceVersion": "2.0",
                        "Stretch": False,
                    }],
                    "resourceType": "KeyframeStore<SpriteFrameKeyframe>",
                    "resourceVersion": "2.0",
                },
                "modifiers": [],
                "name": "frames",
                "resourceType": "GMSpriteFramesTrack",
                "resourceVersion": "2.0",
                "spriteId": None,
                "trackColour": 0,
                "tracks": [],
                "traits": 0,
            }],
            "visibleRange": None,
            "volume": 1.0,
            "xorigin": width // 2,
            "yorigin": height // 2,
        },
        "swatchColours": None,
        "swfPrecision": 2.525,
        "textureGroupId": {"name": "Default", "path": "texturegroups/Default"},
        "type": 0,
        "VTile": False,
        "width": width,
    }


def install_sprite(name: str, image: Image.Image) -> None:
    image = image.convert("RGBA")
    width, height = image.size
    directory = SPRITES / name
    directory.mkdir(parents=True, exist_ok=True)
    frame = stable_uuid(f"{name}/frame")
    layer = stable_uuid(f"{name}/layer")
    image.save(directory / f"{frame}.png")
    (directory / f"{name}.yy").write_text(
        json.dumps(sprite_metadata(name, width, height, frame, layer), indent=2) + "\n",
        encoding="utf-8",
    )


def hi_res_canvas(size: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (size * SCALE, size * SCALE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def glow_composite(base: Image.Image, glow_color: tuple[int, int, int], radius: int) -> Image.Image:
    alpha = base.getchannel("A")
    blurred = alpha.filter(ImageFilter.GaussianBlur(radius * SCALE))
    glow = Image.new("RGBA", base.size, (*glow_color, 0))
    glow.putalpha(blurred.point(lambda value: int(value * 0.48)))
    return Image.alpha_composite(glow, base)


def violet_bee() -> Image.Image:
    image, draw = hi_res_canvas(64)
    s = SCALE
    # Stained-glass wings and their hard brass leading edges.
    draw.ellipse((5*s, 17*s, 31*s, 38*s), fill=(116, 224, 255, 150), outline=(224, 244, 255, 240), width=2*s)
    draw.ellipse((33*s, 17*s, 59*s, 38*s), fill=(218, 132, 255, 150), outline=(255, 224, 250, 240), width=2*s)
    draw.line((13*s, 22*s, 27*s, 33*s), fill=(58, 34, 92, 230), width=2*s)
    draw.line((51*s, 22*s, 37*s, 33*s), fill=(58, 34, 92, 230), width=2*s)
    # Gothic abdomen, violet velvet with gold filigree bands.
    draw.ellipse((23*s, 14*s, 41*s, 31*s), fill=(248, 190, 72, 255), outline=(255, 238, 174, 255), width=2*s)
    draw.polygon([(22*s, 27*s), (42*s, 27*s), (39*s, 49*s), (32*s, 58*s), (25*s, 49*s)],
                 fill=(99, 38, 139, 255), outline=(238, 174, 255, 255))
    draw.line((24*s, 35*s, 40*s, 35*s), fill=(255, 206, 84, 255), width=3*s)
    draw.line((25*s, 43*s, 39*s, 43*s), fill=(255, 206, 84, 255), width=3*s)
    draw.polygon([(28*s, 13*s), (32*s, 6*s), (36*s, 13*s), (40*s, 9*s), (39*s, 18*s), (25*s, 18*s), (24*s, 9*s)],
                 fill=(250, 205, 91, 255), outline=(255, 244, 190, 255))
    draw.ellipse((27*s, 18*s, 31*s, 22*s), fill=(24, 10, 39, 255))
    draw.ellipse((33*s, 18*s, 37*s, 22*s), fill=(24, 10, 39, 255))
    draw.line((27*s, 16*s, 20*s, 9*s), fill=(255, 219, 128, 255), width=2*s)
    draw.line((37*s, 16*s, 44*s, 9*s), fill=(255, 219, 128, 255), width=2*s)
    image = glow_composite(image, (171, 80, 255), 2)
    return image.resize((64, 64), RESAMPLE)


def twilight_mayfly() -> Image.Image:
    image, draw = hi_res_canvas(64)
    s = SCALE
    # Four long glass wings, sunset on one side and moonlight on the other.
    draw.ellipse((5*s, 10*s, 31*s, 35*s), fill=(100, 222, 255, 150), outline=(222, 248, 255, 245), width=2*s)
    draw.ellipse((33*s, 10*s, 59*s, 35*s), fill=(255, 132, 116, 150), outline=(255, 226, 196, 245), width=2*s)
    draw.ellipse((10*s, 29*s, 31*s, 50*s), fill=(168, 126, 255, 140), outline=(228, 210, 255, 235), width=2*s)
    draw.ellipse((33*s, 29*s, 54*s, 50*s), fill=(255, 122, 202, 140), outline=(255, 214, 242, 235), width=2*s)
    draw.line((12*s, 16*s, 28*s, 31*s), fill=(52, 42, 104, 220), width=2*s)
    draw.line((52*s, 16*s, 36*s, 31*s), fill=(104, 42, 82, 220), width=2*s)
    # A needle body with a small rose-window thorax.
    draw.ellipse((25*s, 12*s, 39*s, 27*s), fill=(250, 216, 124, 255), outline=(255, 246, 198, 255), width=2*s)
    draw.polygon([(27*s, 24*s), (37*s, 24*s), (35*s, 51*s), (32*s, 57*s), (29*s, 51*s)],
                 fill=(55, 50, 128, 255), outline=(148, 230, 255, 255))
    draw.ellipse((28*s, 16*s, 36*s, 24*s), fill=(255, 102, 186, 255), outline=(255, 228, 244, 255), width=s)
    draw.line((29*s, 54*s, 23*s, 62*s), fill=(142, 224, 255, 245), width=s)
    draw.line((32*s, 55*s, 32*s, 63*s), fill=(255, 188, 222, 245), width=s)
    draw.line((35*s, 54*s, 41*s, 62*s), fill=(255, 157, 130, 245), width=s)
    image = glow_composite(image, (106, 188, 255), 2)
    return image.resize((64, 64), RESAMPLE)


def bee_bullet() -> Image.Image:
    image, draw = hi_res_canvas(16)
    s = SCALE
    draw.polygon([(1*s, 8*s), (7*s, 3*s), (14*s, 8*s), (7*s, 13*s)],
                 fill=(101, 42, 154, 255), outline=(255, 231, 142, 255))
    draw.polygon([(8*s, 5*s), (15*s, 8*s), (8*s, 10*s)], fill=(255, 206, 82, 255))
    draw.ellipse((4*s, 5*s, 8*s, 10*s), fill=(240, 176, 255, 255))
    return glow_composite(image, (192, 98, 255), 1).resize((16, 16), RESAMPLE)


def mayfly_bullet() -> Image.Image:
    image, draw = hi_res_canvas(16)
    s = SCALE
    draw.ellipse((2*s, 2*s, 12*s, 8*s), fill=(112, 224, 255, 230), outline=(234, 250, 255, 255), width=s)
    draw.ellipse((2*s, 8*s, 12*s, 14*s), fill=(255, 132, 198, 230), outline=(255, 230, 244, 255), width=s)
    draw.polygon([(6*s, 5*s), (15*s, 8*s), (6*s, 11*s)], fill=(255, 189, 108, 255))
    return glow_composite(image, (124, 198, 255), 1).resize((16, 16), RESAMPLE)


def portrait_silhouette(name: str) -> Image.Image:
    source = Image.open(PORTRAITS / f"{name}_full.png").convert("RGBA")
    alpha = source.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"Portrait has no visible alpha: {name}")
    alpha = alpha.crop(bbox)
    alpha.thumbnail((384, 500), RESAMPLE)
    canvas = Image.new("L", (384, 512), 0)
    canvas.paste(alpha, ((384 - alpha.width) // 2, 512 - alpha.height))
    rim = canvas.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(2))
    result = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    rim_layer = Image.new("RGBA", canvas.size, (248, 224, 255, 0))
    rim_layer.putalpha(rim.point(lambda value: int(value * 0.72)))
    result = Image.alpha_composite(result, rim_layer)
    # Keep the source light enough for GameMaker's multiplicative tinting;
    # menu drawing supplies the final violet/cyan color and low opacity.
    body = Image.new("RGBA", canvas.size, (190, 158, 224, 0))
    body.putalpha(canvas)
    return Image.alpha_composite(result, body)


def main() -> None:
    install_sprite("spr_violet_bee", violet_bee())
    install_sprite("spr_twilight_mayfly", twilight_mayfly())
    install_sprite("spr_violet_bee_bullet", bee_bullet())
    install_sprite("spr_twilight_mayfly_bullet", mayfly_bullet())
    for character in ("moon", "selkie", "mira", "shalmii", "aisha", "aster", "caelia"):
        install_sprite(f"spr_silhouette_{character}", portrait_silhouette(character))
    print("Built 4 final-stage sprites and 7 portrait-authority silhouettes.")


if __name__ == "__main__":
    main()

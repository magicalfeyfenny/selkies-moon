"""Run inside Blender to author and export Selkie's Moon's five 3D stage loops."""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path("/Users/magicalfeyfenny/GameMakerProjects/selkies-moon")
SOURCE = ROOT / "art" / "3d_stage_sources"
DATAFILES = ROOT / "Selkie's Moon ~ until we meet again ~" / "datafiles"
LOOP_LENGTH = 64.0
TEXTURE_SLUGS = {
    1: "forge",
    2: "saltwind",
    3: "wishcourt",
    4: "orrery",
    5: "violet_garden",
}


STAGES = {
    1: {
        "slug": "shalmii_forge_procession",
        "location": "Shalmii's Blacksmith Citadel",
        "palette": ((0.055, 0.025, 0.07, 1), (0.27, 0.09, 0.10, 1), (0.90, 0.25, 0.055, 1), (1.0, 0.62, 0.16, 1), (0.24, 0.19, 0.30, 1)),
        "camera": [(-1.0, 0.0, 10.0), (1.5, 16.0, 9.2), (-1.5, 32.0, 10.4), (0.8, 48.0, 8.8), (-1.0, 64.0, 10.0)],
        "boss_camera": [(-1.0, 0.0, 10.0), (3.2, 16.0, 7.8), (-3.0, 32.0, 8.7), (2.4, 48.0, 7.4), (-1.0, 64.0, 10.0)],
        "target_z": 1.2,
        "speed": 0.028,
        "world": (0.018, 0.006, 0.020),
        "sun_color": (1.0, 0.35, 0.12),
        "sun_energy": 2.6,
        "fog": {"color": [0.12, 0.035, 0.045], "start": 20.0, "end": 78.0, "density": 0.42, "effect": "embers"},
    },
    2: {
        "slug": "aster_saltwind_ribbon_coast",
        "location": "Aster's Moonrabbit Forest",
        "palette": ((0.035, 0.075, 0.065, 1), (0.14, 0.29, 0.19, 1), (0.84, 0.39, 0.69, 1), (0.24, 0.69, 0.42, 1), (0.88, 0.78, 0.48, 1)),
        "camera": [(-4.0, 0.0, 11.0), (-1.0, 15.0, 12.0), (4.0, 31.0, 9.4), (1.0, 48.0, 10.5), (-4.0, 64.0, 11.0)],
        "boss_camera": [(-4.0, 0.0, 11.0), (4.8, 16.0, 8.0), (-3.8, 32.0, 9.2), (2.2, 48.0, 7.8), (-4.0, 64.0, 11.0)],
        "target_z": 0.2,
        "speed": 0.025,
        "world": (0.018, 0.045, 0.035),
        "sun_color": (0.62, 0.94, 0.72),
        "sun_energy": 2.1,
        "fog": {"color": [0.08, 0.19, 0.13], "start": 20.0, "end": 88.0, "density": 0.34, "effect": "forest_fireflies"},
    },
    3: {
        "slug": "mira_aisha_velvet_wishcourt",
        "location": "Mira and Aisha's Vegas Grand Illusion",
        "palette": ((0.035, 0.015, 0.075, 1), (0.20, 0.06, 0.27, 1), (0.85, 0.08, 0.45, 1), (0.08, 0.56, 0.82, 1), (0.96, 0.64, 0.14, 1)),
        "camera": [(0.0, 0.0, 9.5), (-3.5, 15.0, 10.5), (3.5, 31.0, 10.5), (-2.0, 48.0, 9.0), (0.0, 64.0, 9.5)],
        "boss_camera": [(0.0, 0.0, 9.5), (4.2, 16.0, 8.1), (-4.0, 32.0, 9.4), (3.0, 48.0, 7.8), (0.0, 64.0, 9.5)],
        "target_z": 1.5,
        "speed": 0.023,
        "world": (0.025, 0.01, 0.05),
        "sun_color": (0.72, 0.35, 1.0),
        "sun_energy": 1.6,
        "fog": {"color": [0.11, 0.035, 0.17], "start": 22.0, "end": 82.0, "density": 0.34, "effect": "vegas_magic_dust"},
    },
    4: {
        "slug": "caelia_bloodstar_orrery",
        "location": "Caelia's Deep-Space Orrery",
        "palette": ((0.018, 0.012, 0.06, 1), (0.12, 0.06, 0.21, 1), (0.72, 0.035, 0.16, 1), (0.12, 0.45, 0.78, 1), (0.96, 0.62, 0.12, 1)),
        "camera": [(2.0, 0.0, 11.5), (-2.5, 16.0, 12.5), (1.0, 32.0, 8.8), (3.0, 48.0, 11.8), (2.0, 64.0, 11.5)],
        "boss_camera": [(2.0, 0.0, 11.5), (5.0, 16.0, 8.0), (-5.0, 32.0, 12.2), (3.2, 48.0, 8.6), (2.0, 64.0, 11.5)],
        "target_z": 2.4,
        "speed": 0.021,
        "world": (0.008, 0.008, 0.03),
        "sun_color": (0.35, 0.58, 1.0),
        "sun_energy": 1.45,
        "fog": {"color": [0.025, 0.02, 0.09], "start": 20.0, "end": 96.0, "density": 0.27, "effect": "deep_space"},
    },
    5: {
        "slug": "moon_selkie_infinite_violet_garden",
        "location": "The Infinite Violet and Vine Field",
        "palette": ((0.028, 0.015, 0.07, 1), (0.18, 0.07, 0.26, 1), (0.68, 0.08, 0.52, 1), (0.10, 0.48, 0.28, 1), (1.0, 0.68, 0.20, 1)),
        "camera": [(0.0, 0.0, 8.8), (-3.0, 15.0, 9.7), (3.0, 31.0, 8.3), (-1.5, 48.0, 10.2), (0.0, 64.0, 8.8)],
        "boss_camera": [(0.0, 0.0, 8.8), (2.6, 16.0, 6.8), (-2.6, 32.0, 7.6), (1.2, 48.0, 6.5), (0.0, 64.0, 8.8)],
        "target_z": 0.8,
        "speed": 0.019,
        "world": (0.035, 0.012, 0.055),
        "sun_color": (0.72, 0.32, 1.0),
        "sun_energy": 2.1,
        "fog": {"color": [0.14, 0.055, 0.19], "start": 22.0, "end": 84.0, "density": 0.38, "effect": "violet_pollen_petals"},
    },
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for image in list(bpy.data.images):
        if image.name not in {"Render Result", "Viewer Node"}:
            bpy.data.images.remove(image)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras,
                       bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def material(name: str, color, emission: float = 0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    if principled:
        principled.inputs["Base Color"].default_value = color
        principled.inputs["Roughness"].default_value = 0.78
        if "Emission Color" in principled.inputs:
            principled.inputs["Emission Color"].default_value = color
            principled.inputs["Emission Strength"].default_value = emission
    return mat


def tag(obj, category: str) -> None:
    obj["atlas_category"] = category
    obj["runtime_mesh"] = True


def add_cube(name, location, scale, mat, category="architecture", rotation=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        modifier = obj.modifiers.new("Pixel Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.data.materials.append(mat)
    tag(obj, category)
    return obj


def add_cylinder(name, location, radius, depth, mat, category="architecture", vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    tag(obj, category)
    return obj


def add_cone(name, location, radius1, radius2, depth, mat, category="accent", vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2,
                                   depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    tag(obj, category)
    return obj


def add_uv_sphere(name, location, scale, mat, category="accent", segments=12, rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    tag(obj, category)
    return obj


def add_torus(name, location, major_radius, minor_radius, mat, category="accent", rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major_radius, minor_radius=minor_radius,
                                    major_segments=16, minor_segments=4,
                                    location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    tag(obj, category)
    return obj


def add_curve(name, points, bevel_depth, mat, category="foliage", cyclic=False):
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 0
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coordinate in zip(spline.points, points):
        point.co = (*coordinate, 1)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    tag(obj, category)
    return obj


def add_billboard_proxy(name, location, width, height, mat, tile):
    """Add an editable layout card that is replaced by a true runtime billboard."""
    bpy.ops.mesh.primitive_plane_add(size=2, location=(location[0], location[1], location[2] + height / 2),
                                     rotation=(math.radians(90), 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (width / 2, height / 2, 1)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj["runtime_mesh"] = False
    obj["billboard_proxy"] = True
    obj["billboard_tile"] = tile
    return obj


def add_tree(name, x, y, height, mats, pink=False):
    ink, structure, accent, cool, gold = mats
    add_cylinder(f"{name}_Trunk", (x, y, height * 0.38), 0.65, height * 0.76,
                 structure, "architecture", vertices=9)
    canopy = accent if pink else cool
    for index, (dx, dy, dz, scale) in enumerate((
        (0, 0, 0.78, 2.4), (-1.5, 0.2, 0.66, 1.75),
        (1.5, -0.1, 0.69, 1.9), (0.2, 0.6, 0.98, 1.6),
    )):
        add_uv_sphere(f"{name}_Canopy_{index}",
                      (x + dx, y + dy, height * dz),
                      (scale, scale * 0.72, scale * 0.82), canopy,
                      "foliage", 10, 5)


def add_rabbit_topiary(name, x, y, scale, mats):
    ink, structure, accent, cool, gold = mats
    add_uv_sphere(f"{name}_Body", (x, y, 1.45 * scale),
                  (1.3 * scale, 0.92 * scale, 1.55 * scale), cool, "foliage", 10, 5)
    add_uv_sphere(f"{name}_Head", (x, y - 0.15 * scale, 3.25 * scale),
                  (0.9 * scale, 0.75 * scale, 0.9 * scale), cool, "foliage", 10, 5)
    for side in (-1, 1):
        add_cone(f"{name}_Ear_{side}",
                 (x + side * 0.38 * scale, y, 4.55 * scale),
                 0.34 * scale, 0.12 * scale, 2.25 * scale,
                 accent, "foliage", vertices=8,
                 rotation=(0, math.radians(side * 7), 0))
    add_uv_sphere(f"{name}_Tail", (x + 1.05 * scale, y + 0.25 * scale, 1.7 * scale),
                  (0.48 * scale, 0.48 * scale, 0.48 * scale), gold,
                  "accent", 8, 4)


def add_anvil(name, x, y, scale, mats):
    ink, structure, accent, cool, gold = mats
    add_cube(f"{name}_Base", (x, y, 0.5 * scale),
             (2.0 * scale, 1.5 * scale, 1.0 * scale), structure, bevel=0.16 * scale)
    add_cube(f"{name}_Face", (x - 0.25 * scale, y, 1.3 * scale),
             (3.0 * scale, 1.55 * scale, 0.55 * scale), cool, "accent", bevel=0.12 * scale)
    add_cone(f"{name}_Horn", (x + 1.65 * scale, y, 1.3 * scale),
             0.72 * scale, 0.03, 2.0 * scale, gold, "accent", vertices=8,
             rotation=(0, math.radians(90), 0))


def add_pointed_arch(y, mats, index):
    ink, structure, accent, cool, gold = mats
    add_cube(f"Arch_{index}_Left", (-15, y, 4.5), (2.2, 2.0, 9), structure, bevel=0.2)
    add_cube(f"Arch_{index}_Right", (15, y, 4.5), (2.2, 2.0, 9), structure, bevel=0.2)
    add_cube(f"Arch_{index}_PeakL", (-7.5, y, 10.0), (17, 1.7, 1.5), gold,
             "accent", rotation=(0, math.radians(-27), 0), bevel=0.12)
    add_cube(f"Arch_{index}_PeakR", (7.5, y, 10.0), (17, 1.7, 1.5), gold,
             "accent", rotation=(0, math.radians(27), 0), bevel=0.12)


def build_common(mats):
    ink, structure, accent, cool, gold = mats
    add_cube("Continuous_Ground", (0, LOOP_LENGTH / 2, -1.25), (42, LOOP_LENGTH, 2.5), ink, "ground")
    add_cube("Left_Edge", (-20, LOOP_LENGTH / 2, 0.25), (1.2, LOOP_LENGTH, 3), structure, "architecture")
    add_cube("Right_Edge", (20, LOOP_LENGTH / 2, 0.25), (1.2, LOOP_LENGTH, 3), structure, "architecture")


def add_billboard_layout_proxies(stage, mats):
    ink, structure, accent, cool, gold = mats
    count = (12, 16, 14, 14, 32)[stage - 1]
    for index in range(count):
        side = -1 if index % 2 == 0 else 1
        y = ((index * 17) % 64) + (index % 3) * 0.37
        x = side * (10 + ((index * 7) % 10))
        z = -0.05
        width = 3.5 + (index % 4) * 0.8
        height = 5.8 + (index % 5) * 1.0
        if stage == 2:
            width *= 1.55
            height *= 1.45
        elif stage == 3:
            x = side * (9 + ((index * 5) % 10))
        elif stage == 4:
            z = 3 + ((index * 11) % 12)
            width *= 2.0
            height *= 1.45
        elif stage == 5:
            x = -17 + ((index * 11) % 35)
            width *= 1.55
            height *= 1.35
        add_billboard_proxy(f"RuntimeBillboardProxy_{index:02d}",
                            (x, y, z), width, height,
                            accent if index % 2 == 0 else cool, index % 4)


def build_forge(mats):
    ink, structure, accent, cool, gold = mats
    for index, y in enumerate((6, 22, 38, 54)):
        add_pointed_arch(y, mats, index)
        for side in (-1, 1):
            x = side * 12
            add_cube(f"Furnace_{index}_{side}", (x, y + 4.5, 2.2), (6.5, 5.5, 4.4), structure, bevel=0.3)
            add_cube(f"FurnaceGlow_{index}_{side}", (x, y + 1.72, 2.15), (3.5, 0.28, 2.2), accent, "accent")
            add_cylinder(f"Chimney_{index}_{side}", (x, y + 6, 8), 1.6, 10, ink, vertices=8)
            add_torus(f"FurnaceRim_{index}_{side}", (x, y + 1.52, 2.15), 1.75, 0.18,
                      gold, "accent", rotation=(math.radians(90), 0, 0))
            # Hanging hammer racks and bellows make each bay an actual workshop.
            add_cube(f"HammerRack_{index}_{side}", (side * 17, y + 7.5, 4.8),
                     (0.6, 3.8, 7.5), cool, "architecture", bevel=0.12)
            for tool in range(3):
                tx = side * (16.6 + tool * 0.36)
                add_cube(f"HammerHandle_{index}_{side}_{tool}",
                         (tx, y + 6.4 + tool * 0.7, 5.2),
                         (0.18, 0.18, 4.2), gold, "accent")
                add_cube(f"HammerHead_{index}_{side}_{tool}",
                         (tx, y + 6.4 + tool * 0.7, 7.2),
                         (1.4, 0.6, 0.55), cool, "accent", bevel=0.08)
        add_anvil(f"Anvil_{index}", ((-1) ** index) * 5.5, y + 10, 1.15, mats)
        # Molten runnels and metal rails lead the camera through the infinite foundry.
        for rail in (-1, 1):
            add_cube(f"MoltenChannel_{index}_{rail}", (rail * 4.2, y + 8, -0.05),
                     (1.1, 13.5, 0.18), accent, "accent")
            add_cube(f"ChannelLip_{index}_{rail}_A", (rail * 4.85, y + 8, 0.12),
                     (0.2, 13.5, 0.35), gold, "accent")
            add_cube(f"ChannelLip_{index}_{rail}_B", (rail * 3.55, y + 8, 0.12),
                     (0.2, 13.5, 0.35), gold, "accent")
    for i in range(28):
        x = -17 + (i % 5) * 8.5
        y = 3 + ((i * 13) % 59)
        z = 2 + (i % 4) * 1.4
        add_uv_sphere(f"Ember_{i}", (x, y, z), (0.18, 0.18, 0.18), accent, "accent", 8, 4)


def build_moonrabbit_forest(mats):
    ink, structure, accent, cool, gold = mats
    # Alternating tree groves create a readable forest route rather than abstract spires.
    for row, y in enumerate(range(2, 64, 6)):
        for side in (-1, 1):
            x = side * (10.5 + ((row * 3) % 8))
            add_tree(f"Moonwood_{row}_{side}", x, y,
                     9.5 + (row % 4) * 1.6, mats, pink=(row + side) % 4 == 0)
        if row % 2 == 0:
            add_rabbit_topiary(f"RabbitTopiary_{row}",
                               (-1 if row % 4 == 0 else 1) * 6.5,
                               y + 2.2, 0.85 + (row % 3) * 0.12, mats)

    # Burrows, mushroom rings, fallen logs, and moon gates turn the route into a place.
    for index, y in enumerate((8, 24, 40, 56)):
        side = -1 if index % 2 == 0 else 1
        x = side * 14
        add_torus(f"BurrowArch_{index}", (x, y, 1.5), 3.1, 0.42, structure,
                  "architecture", rotation=(math.radians(90), 0, 0))
        add_cube(f"FallenLog_{index}", (-side * 11, y + 3, 0.9),
                 (7.5, 1.7, 1.7), structure, "architecture",
                 rotation=(0, 0, math.radians(side * 12)), bevel=0.28)
        for mushroom in range(5):
            mx = -8 + mushroom * 4 + side * 1.5
            add_cylinder(f"MushroomStem_{index}_{mushroom}",
                         (mx, y + 6.0, 0.75), 0.18, 1.5, gold,
                         "foliage", vertices=7)
            add_uv_sphere(f"MushroomCap_{index}_{mushroom}",
                          (mx, y + 6.0, 1.55), (0.85, 0.7, 0.35),
                          accent if mushroom % 2 else cool, "foliage", 9, 4)
        add_pointed_arch(y + 5, mats, 20 + index)

    for vine in range(12):
        side = -1 if vine % 2 == 0 else 1
        x = side * (8 + (vine % 5) * 2.2)
        y = 3 + (vine * 11) % 60
        points = [(x, y - 3, 0.1), (x + side * 0.8, y, 2.6),
                  (x - side * 0.6, y + 2.5, 5.3), (x, y + 4.5, 8.0)]
        add_curve(f"ForestVine_{vine}", points, 0.16, cool, "foliage")


def build_wishcourt(mats):
    ink, structure, accent, cool, gold = mats
    # A central proscenium unifies Mira's casino floor on the left and Aisha's
    # grand-illusion sorcery stage on the right.
    for index, y in enumerate((7, 19, 31, 43, 55)):
        add_pointed_arch(y, mats, index)
        add_cube(f"VelvetRunway_{index}", (0, y + 6.5, 0.18),
                 (8.5, 9.5, 0.36), structure, "ground", bevel=0.16)

        # Mira / left: roulette tables, slot cabinets, card towers, and bulb marquees.
        add_cylinder(f"RouletteTable_{index}", (-9.5, y + 5.0, 1.35),
                     2.7, 1.15, structure, "architecture", vertices=16)
        add_torus(f"RouletteWheel_{index}", (-9.5, y + 5.0, 2.05),
                  1.75, 0.22, gold, "accent")
        for pocket in range(8):
            angle = pocket * math.tau / 8
            add_uv_sphere(f"RouletteLight_{index}_{pocket}",
                          (-9.5 + math.cos(angle) * 1.3,
                           y + 5.0 + math.sin(angle) * 1.3, 2.12),
                          (0.13, 0.13, 0.13), accent if pocket % 2 else gold,
                          "accent", 6, 3)
        add_cube(f"SlotCabinet_{index}", (-15.2, y + 5.2, 2.9),
                 (3.8, 2.3, 5.8), accent, "architecture", bevel=0.32)
        for reel in range(3):
            add_cube(f"SlotReel_{index}_{reel}",
                     (-16.0 + reel * 0.8, y + 4.0, 3.2),
                     (0.62, 0.15, 1.25), gold if reel == 1 else cool,
                     "accent", bevel=0.08)
        for card in range(3):
            add_cube(f"CardTower_{index}_{card}",
                     (-5.2 + card * 0.42, y + 3.7 + card * 0.18, 4.2 + card * 0.35),
                     (2.8, 0.16, 4.2), accent if card % 2 == 0 else gold,
                     "accent", rotation=(0, math.radians((card - 1) * 7),
                                         math.radians((card - 1) * 4)), bevel=0.08)

        # Aisha / right: curtains, ritual rings, top hats, crystals, and wand arrays.
        add_cube(f"CurtainWing_{index}_Inner", (9.2, y + 5.5, 4.7),
                 (3.4, 1.1, 9.4), cool, "architecture",
                 rotation=(0, 0, math.radians(-4)), bevel=0.25)
        add_cube(f"CurtainWing_{index}_Outer", (14.8, y + 5.5, 4.7),
                 (3.4, 1.1, 9.4), structure, "architecture",
                 rotation=(0, 0, math.radians(5)), bevel=0.25)
        add_torus(f"SorceryCircle_{index}_Wide", (11.7, y + 4.2, 5.5),
                  3.4, 0.16, cool, "accent", rotation=(math.radians(90), 0, 0))
        add_torus(f"SorceryCircle_{index}_Tall", (11.7, y + 4.15, 5.5),
                  2.35, 0.13, gold, "accent", rotation=(math.radians(90), 0, 0))
        add_cylinder(f"TopHatCrown_{index}", (6.0, y + 5.0, 1.45),
                     1.55, 2.1, ink, "architecture", vertices=16)
        add_cylinder(f"TopHatBrim_{index}", (6.0, y + 5.0, 0.45),
                     2.5, 0.22, gold, "accent", vertices=20)
        for wand in range(4):
            angle = 22 + wand * 18
            add_cylinder(f"Wand_{index}_{wand}",
                         (15.5 - wand * 0.8, y + 7.0, 2.6 + wand * 0.55),
                         0.11, 4.3, gold, "accent", vertices=6,
                         rotation=(0, math.radians(angle), 0))
            add_uv_sphere(f"WandStar_{index}_{wand}",
                          (16.15 - wand * 0.35, y + 7.0, 4.6 + wand * 0.55),
                          (0.38, 0.22, 0.48), cool, "accent", 8, 4)

    # Neon dividing line makes the two authored halves legible at a glance.
    for rail in (-1, 1):
        add_cube(f"RunwayNeon_{rail}", (rail * 4.65, LOOP_LENGTH / 2, 0.16),
                 (0.18, LOOP_LENGTH, 0.18), accent if rail < 0 else cool, "accent")


def build_orrery(mats):
    ink, structure, accent, cool, gold = mats
    # The route crosses an exposed cosmic observatory: planets and galaxy hubs
    # occupy real depth instead of appearing only as abstract clockwork.
    for index, y in enumerate((8, 24, 40, 56)):
        for side in (-1, 1):
            x = side * 13
            add_cylinder(f"ObservatoryPylon_{index}_{side}", (x, y, 4.5), 2.2, 9, structure, vertices=10)
            add_torus(f"ClockFace_{index}_{side}", (x, y - 2.25, 5.5), 1.6, 0.18,
                      gold, "accent", rotation=(math.radians(90), 0, 0))
        add_torus(f"OrbitWide_{index}", (0, y + 3, 5.5), 7.5, 0.16, cool,
                  "accent", rotation=(math.radians(72), 0, math.radians(index * 23)))
        add_torus(f"OrbitTall_{index}", (0, y + 3, 5.5), 5.5, 0.14, gold,
                  "accent", rotation=(0, math.radians(67), math.radians(index * 31)))
        add_uv_sphere(f"GalaxyCore_{index}", (0, y + 3, 5.5),
                      (1.8, 1.8, 1.8), accent, "accent", 14, 7)
        add_uv_sphere(f"Planet_{index}", (6, y + 3, 6.5),
                      (1.1 + index * 0.12, 1.1 + index * 0.12, 1.1 + index * 0.12),
                      cool, "accent", 14, 7)
        if index % 2 == 0:
            add_torus(f"PlanetRing_{index}", (6, y + 3, 6.5),
                      1.7 + index * 0.12, 0.12, gold, "accent",
                      rotation=(math.radians(68), math.radians(12), 0))
        # Smaller moons and asteroid clusters make the void feel populated.
        for moon in range(6):
            angle = moon * math.tau / 6 + index * 0.31
            radius = 7.5 + (moon % 3) * 1.7
            mx = math.cos(angle) * radius
            mz = 5.8 + math.sin(angle) * (2.1 + moon % 2)
            add_uv_sphere(f"Moon_{index}_{moon}", (mx, y + 3 + moon * 0.16, mz),
                          (0.28 + moon * 0.04,) * 3,
                          gold if moon % 3 == 0 else cool, "accent", 8, 4)

    for asteroid in range(34):
        x = -18 + ((asteroid * 17) % 37)
        y = 1 + ((asteroid * 19) % 63)
        z = 2.2 + ((asteroid * 11) % 12)
        size = 0.16 + (asteroid % 5) * 0.08
        add_uv_sphere(f"Asteroid_{asteroid}", (x, y, z),
                      (size * 1.4, size, size * 0.8),
                      structure if asteroid % 2 else gold, "accent", 7, 3)

    # A large ringed world hangs beyond one side of the route each loop.
    add_uv_sphere("HorizonPlanet", (-16.5, 33, 13.5), (5.8, 5.8, 5.8),
                  cool, "accent", 18, 9)
    add_torus("HorizonPlanetRings", (-16.5, 33, 13.5), 8.0, 0.24, gold,
              "accent", rotation=(math.radians(72), math.radians(8), math.radians(18)))


def add_violet_flower(index, x, y, scale, mats):
    ink, structure, accent, cool, gold = mats
    height = 2.6 + (index % 5) * 0.45
    add_cylinder(f"VineStem_{index}", (x, y, height / 2), 0.08 * scale, height,
                 cool, "foliage", vertices=6)
    # A slightly crooked climbing tendril reinforces the continuous field.
    points = []
    for step in range(5):
        z = step * height / 4
        points.append((x + math.sin(index + step * 1.4) * 0.35, y, z))
    add_curve(f"VineCurl_{index}", points, 0.055 * scale, cool, "foliage")
    center_z = height + 0.18
    for petal in range(5):
        angle = petal * math.tau / 5
        px = x + math.cos(angle) * 0.42 * scale
        py = y + math.sin(angle) * 0.18 * scale
        pz = center_z + math.sin(angle) * 0.28 * scale
        add_uv_sphere(f"Violet_{index}_Petal_{petal}", (px, py, pz),
                      (0.34 * scale, 0.13 * scale, 0.46 * scale), accent, "foliage", 8, 4)
    add_uv_sphere(f"Violet_{index}_Heart", (x, y - 0.04, center_z),
                  (0.22 * scale, 0.16 * scale, 0.22 * scale), gold, "accent", 8, 4)


def build_violet_garden(mats):
    ink, structure, accent, cool, gold = mats
    # Dense modular rows touch both loop seams, producing a genuinely continuous field.
    flower = 0
    for row, y in enumerate(range(0, 64, 8)):
        for column, x in enumerate(range(-20, 21, 4)):
            jitter_x = ((row * 11 + column * 7) % 5 - 2) * 0.18
            jitter_y = ((row * 5 + column * 13) % 5 - 2) * 0.12
            add_violet_flower(flower, x + jitter_x, y + jitter_y,
                              0.78 + (flower % 5) * 0.14, mats)
            flower += 1
    for index, y in enumerate((8, 24, 40, 56)):
        for side in (-1, 1):
            x = side * 14
            points = [(x, y - 5, 0), (x + side * 1.4, y - 2, 3),
                      (x - side * 1.2, y + 1, 6), (x, y + 4, 10)]
            add_curve(f"TrellisVine_{index}_{side}", points, 0.22, cool, "foliage")
        # Prominent hero blooms tower over the dense field and repeat into the horizon.
        add_violet_flower(1000 + index, (-1 if index % 2 == 0 else 1) * 8.5,
                          y + 4.5, 2.35, mats)
        for side in (-1, 1):
            crown_x = side * 17
            vine_points = []
            for step in range(8):
                vine_points.append((crown_x + math.sin(step * 1.1 + index) * 1.4,
                                    y - 6 + step * 1.7, step * 1.45))
            add_curve(f"HorizonVineWall_{index}_{side}", vine_points,
                      0.32, cool, "foliage")


def add_camera_and_lighting(stage, config, mats):
    camera_data = bpy.data.cameras.new(f"Stage_{stage:02d}_Camera")
    camera = bpy.data.objects.new(camera_data.name, camera_data)
    bpy.context.collection.objects.link(camera)
    first = config["camera"][0]
    camera.location = first
    camera.data.lens = 42
    bpy.context.scene.camera = camera

    curve_data = bpy.data.curves.new(f"Stage_{stage:02d}_Camera_Path", "CURVE")
    curve_data.dimensions = "3D"
    curve_data.resolution_u = 2
    spline = curve_data.splines.new("NURBS")
    spline.points.add(len(config["camera"]) - 1)
    for point, coordinate in zip(spline.points, config["camera"]):
        point.co = (*coordinate, 1)
    spline.use_cyclic_u = False
    spline.order_u = min(3, len(config["camera"]))
    spline.use_endpoint_u = True
    path = bpy.data.objects.new(curve_data.name, curve_data)
    bpy.context.collection.objects.link(path)

    boss_curve_data = bpy.data.curves.new(f"Stage_{stage:02d}_Boss_Camera_Path", "CURVE")
    boss_curve_data.dimensions = "3D"
    boss_curve_data.resolution_u = 2
    boss_spline = boss_curve_data.splines.new("NURBS")
    boss_spline.points.add(len(config["boss_camera"]) - 1)
    for point, coordinate in zip(boss_spline.points, config["boss_camera"]):
        point.co = (*coordinate, 1)
    boss_spline.use_cyclic_u = False
    boss_spline.order_u = min(3, len(config["boss_camera"]))
    boss_spline.use_endpoint_u = True
    boss_path = bpy.data.objects.new(boss_curve_data.name, boss_curve_data)
    bpy.context.collection.objects.link(boss_path)

    sun_data = bpy.data.lights.new(f"Stage_{stage:02d}_Moon_Key", "SUN")
    sun_data.color = config["sun_color"]
    sun_data.energy = config["sun_energy"]
    sun = bpy.data.objects.new(sun_data.name, sun_data)
    sun.rotation_euler = (math.radians(34), math.radians(-18), math.radians(28 + stage * 9))
    bpy.context.collection.objects.link(sun)

    area_data = bpy.data.lights.new(f"Stage_{stage:02d}_Horizon_Rim", "AREA")
    area_data.color = mats[4].diffuse_color[:3]
    area_data.energy = 700 + stage * 85
    area_data.shape = "DISK"
    area_data.size = 8
    area = bpy.data.objects.new(area_data.name, area_data)
    area.location = (0, 42, 12)
    area.rotation_euler = (math.radians(42), 0, math.radians(180))
    bpy.context.collection.objects.link(area)


def export_obj(path: Path) -> int:
    """Export triangulated mesh data with atlas UVs, preserving Blender coordinates."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    lines = ["# Selkie's Moon modular 3D stage export", "s off"]
    index = 1
    triangle_count = 0
    regions = {
        "ground": (0.01, 0.51, 0.49, 0.99),
        "architecture": (0.51, 0.51, 0.99, 0.99),
        "accent": (0.01, 0.01, 0.49, 0.49),
        # Modeled leaves and flowers use the opaque accent quadrant. The
        # transparent lower-right quadrant is reserved for runtime billboards.
        "foliage": (0.01, 0.01, 0.49, 0.49),
    }

    for obj in sorted(bpy.context.scene.objects, key=lambda item: item.name):
        if obj.type != "MESH" or not obj.get("runtime_mesh", False):
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        normal_matrix = obj.matrix_world.to_3x3().inverted_safe().transposed()
        region = regions.get(obj.get("atlas_category", "architecture"), regions["architecture"])
        u0, v0, u1, v1 = region
        lines.append(f"o {obj.name}")

        for triangle in mesh.loop_triangles:
            face_indices = []
            poly_normal = (normal_matrix @ triangle.normal).normalized()
            for loop_index in triangle.loops:
                vertex = mesh.vertices[mesh.loops[loop_index].vertex_index]
                world = obj.matrix_world @ vertex.co
                # Planar mapping repeats inside the selected atlas quadrant.
                if abs(poly_normal.z) > 0.55:
                    su, sv = world.x * 0.08, world.y * 0.08
                elif abs(poly_normal.x) > abs(poly_normal.y):
                    su, sv = world.y * 0.08, world.z * 0.10
                else:
                    su, sv = world.x * 0.08, world.z * 0.10
                u = u0 + ((su % 1.0) * (u1 - u0))
                v = v0 + ((sv % 1.0) * (v1 - v0))
                lines.append(f"v {world.x:.6f} {world.y:.6f} {world.z:.6f}")
                lines.append(f"vt {u:.6f} {v:.6f}")
                lines.append(f"vn {poly_normal.x:.6f} {poly_normal.y:.6f} {poly_normal.z:.6f}")
                face_indices.append(index)
                index += 1
            lines.append("f " + " ".join(f"{i}/{i}/{i}" for i in face_indices))
            triangle_count += 1
        evaluated.to_mesh_clear()

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return triangle_count


def build_stage(stage: int, config: dict) -> dict:
    clear_scene()
    bpy.context.scene.name = f"SelkiesMoon_Stage_{stage:02d}_{config['slug']}"
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 640
    bpy.context.scene.render.resolution_y = 360
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.world.color = config["world"]

    palette = config["palette"]
    mats = (
        material("Ink Ground", palette[0]),
        material("Gothic Structure", palette[1]),
        material("Character Accent", palette[2], 0.12),
        material("Cool Counterlight", palette[3], 0.08),
        material("Horizon Gold", palette[4], 0.20),
    )
    build_common(mats)
    if stage == 1:
        build_forge(mats)
    elif stage == 2:
        build_moonrabbit_forest(mats)
    elif stage == 3:
        build_wishcourt(mats)
    elif stage == 4:
        build_orrery(mats)
    else:
        build_violet_garden(mats)
    add_billboard_layout_proxies(stage, mats)
    add_camera_and_lighting(stage, config, mats)

    # Pack the high-resolution runtime atlas into the native Blender source so
    # the editable scene remains self-contained even if the repo is relocated.
    texture_slug = TEXTURE_SLUGS[stage]
    texture_path = (SOURCE / "textures" / f"stage_{stage:02d}_{texture_slug}"
                    / f"{texture_slug}_runtime_texture.png")
    if texture_path.exists():
        atlas = bpy.data.images.load(str(texture_path), check_existing=False)
        atlas.name = f"Stage_{stage:02d}_Runtime_Atlas_1024"
        # The runtime OBJ uses atlas UVs without a Blender node material, so
        # retain the packed image explicitly instead of allowing orphan purge
        # during save to discard this editable-source dependency.
        atlas.use_fake_user = True
        atlas.pack()

    stage_dir = SOURCE / f"stage_{stage:02d}_{config['slug']}"
    stage_dir.mkdir(parents=True, exist_ok=True)
    blend_path = stage_dir / f"{config['slug']}.blend"
    obj_name = f"stage3d_{stage:02d}_{config['slug']}.obj"
    obj_path = DATAFILES / obj_name
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    triangles = export_obj(obj_path)

    metadata = {
        "stage": stage,
        "slug": config["slug"],
        "location": config["location"],
        "blend_source": str(blend_path.relative_to(ROOT)),
        "runtime_obj": obj_name,
        "loop_length": LOOP_LENGTH,
        "camera_path": config["camera"],
        "boss_camera_path": config["boss_camera"],
        "camera_target_z": config["target_z"],
        "scroll_speed": config["speed"],
        "lighting": {
            "world": config["world"],
            "sun_color": config["sun_color"],
            "sun_energy": config["sun_energy"],
        },
        "fog": config["fog"],
        "triangles": triangles,
        "billboard_proxy_count": sum(1 for obj in bpy.context.scene.objects
                                      if obj.get("billboard_proxy", False)),
    }
    metadata_path = stage_dir / "stage_scene_manifest.json"
    metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return metadata


def main() -> None:
    SOURCE.mkdir(parents=True, exist_ok=True)
    DATAFILES.mkdir(parents=True, exist_ok=True)
    manifest = [build_stage(stage, config) for stage, config in STAGES.items()]
    (SOURCE / "stage_3d_scene_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"SELKIES_MOON_STAGE_BUILD_COMPLETE:{len(manifest)}")


main()

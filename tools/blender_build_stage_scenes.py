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


STAGES = {
    1: {
        "slug": "shalmii_forge_procession",
        "palette": ((0.055, 0.025, 0.07, 1), (0.27, 0.09, 0.10, 1), (0.90, 0.25, 0.055, 1), (1.0, 0.62, 0.16, 1), (0.24, 0.19, 0.30, 1)),
        "camera": [(-1.0, 0.0, 10.0), (1.5, 16.0, 9.2), (-1.5, 32.0, 10.4), (0.8, 48.0, 8.8), (-1.0, 64.0, 10.0)],
        "target_z": 1.2,
        "speed": 0.028,
        "world": (0.018, 0.006, 0.020),
        "sun_color": (1.0, 0.35, 0.12),
        "sun_energy": 2.6,
        "fog": {"color": [0.12, 0.035, 0.045], "start": 20.0, "end": 78.0, "density": 0.42, "effect": "embers"},
    },
    2: {
        "slug": "aster_saltwind_ribbon_coast",
        "palette": ((0.055, 0.06, 0.16, 1), (0.22, 0.18, 0.38, 1), (0.84, 0.31, 0.61, 1), (0.22, 0.72, 0.72, 1), (0.78, 0.72, 0.62, 1)),
        "camera": [(-4.0, 0.0, 11.0), (-1.0, 15.0, 12.0), (4.0, 31.0, 9.4), (1.0, 48.0, 10.5), (-4.0, 64.0, 11.0)],
        "target_z": 0.2,
        "speed": 0.025,
        "world": (0.035, 0.04, 0.10),
        "sun_color": (0.55, 0.82, 1.0),
        "sun_energy": 1.8,
        "fog": {"color": [0.18, 0.16, 0.34], "start": 24.0, "end": 92.0, "density": 0.30, "effect": "salt_mist_ribbons"},
    },
    3: {
        "slug": "mira_aisha_velvet_wishcourt",
        "palette": ((0.035, 0.015, 0.075, 1), (0.20, 0.06, 0.27, 1), (0.85, 0.08, 0.45, 1), (0.08, 0.56, 0.82, 1), (0.96, 0.64, 0.14, 1)),
        "camera": [(0.0, 0.0, 9.5), (-3.5, 15.0, 10.5), (3.5, 31.0, 10.5), (-2.0, 48.0, 9.0), (0.0, 64.0, 9.5)],
        "target_z": 1.5,
        "speed": 0.023,
        "world": (0.025, 0.01, 0.05),
        "sun_color": (0.72, 0.35, 1.0),
        "sun_energy": 1.6,
        "fog": {"color": [0.11, 0.035, 0.17], "start": 22.0, "end": 82.0, "density": 0.34, "effect": "split_magenta_cyan_dust"},
    },
    4: {
        "slug": "caelia_bloodstar_orrery",
        "palette": ((0.018, 0.012, 0.06, 1), (0.12, 0.06, 0.21, 1), (0.72, 0.035, 0.16, 1), (0.12, 0.45, 0.78, 1), (0.96, 0.62, 0.12, 1)),
        "camera": [(2.0, 0.0, 11.5), (-2.5, 16.0, 12.5), (1.0, 32.0, 8.8), (3.0, 48.0, 11.8), (2.0, 64.0, 11.5)],
        "target_z": 2.4,
        "speed": 0.021,
        "world": (0.008, 0.008, 0.03),
        "sun_color": (0.35, 0.58, 1.0),
        "sun_energy": 1.45,
        "fog": {"color": [0.04, 0.025, 0.11], "start": 18.0, "end": 76.0, "density": 0.38, "effect": "astral_sparks"},
    },
    5: {
        "slug": "moon_selkie_infinite_violet_garden",
        "palette": ((0.028, 0.015, 0.07, 1), (0.18, 0.07, 0.26, 1), (0.68, 0.08, 0.52, 1), (0.10, 0.48, 0.28, 1), (1.0, 0.68, 0.20, 1)),
        "camera": [(0.0, 0.0, 8.8), (-3.0, 15.0, 9.7), (3.0, 31.0, 8.3), (-1.5, 48.0, 10.2), (0.0, 64.0, 8.8)],
        "target_z": 0.8,
        "speed": 0.019,
        "world": (0.035, 0.012, 0.055),
        "sun_color": (0.72, 0.32, 1.0),
        "sun_energy": 1.65,
        "fog": {"color": [0.15, 0.045, 0.18], "start": 16.0, "end": 68.0, "density": 0.46, "effect": "violet_pollen_petals"},
    },
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
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


def build_forge(mats):
    ink, structure, accent, cool, gold = mats
    for index, y in enumerate((6, 22, 38, 54)):
        add_pointed_arch(y, mats, index)
        for side in (-1, 1):
            x = side * 12
            add_cube(f"Furnace_{index}_{side}", (x, y + 5, 2.0), (6, 5, 4), structure, bevel=0.25)
            add_cube(f"FurnaceGlow_{index}_{side}", (x, y + 2.45, 2.1), (3.2, 0.3, 2.0), accent, "accent")
            add_cylinder(f"Chimney_{index}_{side}", (x, y + 6, 7), 1.5, 8, ink, vertices=8)
        add_cube(f"Anvil_{index}", ((-1) ** index * 6, y + 10, 0.7), (5, 2.5, 1.4), gold, "accent", bevel=0.2)
    for i in range(16):
        x = -17 + (i % 5) * 8.5
        y = 3 + ((i * 13) % 59)
        z = 2 + (i % 4) * 1.4
        add_uv_sphere(f"Ember_{i}", (x, y, z), (0.18, 0.18, 0.18), accent, "accent", 8, 4)


def build_saltwind(mats):
    ink, structure, accent, cool, gold = mats
    for i, y in enumerate(range(4, 64, 8)):
        for side in (-1, 1):
            x = side * (14 + (i % 3) * 2)
            add_cone(f"SaltSpire_{i}_{side}", (x, y, 3.5), 3.6, 0.3, 8,
                     cool if i % 2 else structure, "architecture", vertices=7)
        wave = []
        for step in range(9):
            x = -17 + step * 4.25
            z = 7 + math.sin(step * 1.2 + i) * 2.2
            wave.append((x, y + 1.5, z))
        add_curve(f"Ribbon_{i}", wave, 0.24, accent if i % 2 else gold, "accent")
    for y in (12, 28, 44, 60):
        add_cube(f"CoastBridge_{y}", (0, y, 0.0), (24, 3, 1), structure, "ground", bevel=0.2)


def build_wishcourt(mats):
    ink, structure, accent, cool, gold = mats
    for index, y in enumerate((7, 19, 31, 43, 55)):
        add_pointed_arch(y, mats, index)
        for side in (-1, 1):
            x = side * 12
            add_cube(f"CardPillar_{index}_{side}", (x, y + 4, 4), (4.5, 1.1, 8),
                     accent if side < 0 else cool, "accent", rotation=(0, 0, math.radians(side * 5)), bevel=0.18)
            add_torus(f"DesireRing_{index}_{side}", (x, y + 3.4, 5), 2.0, 0.25,
                      gold, "accent", rotation=(math.radians(90), 0, 0))
        add_cube(f"DealerDais_{index}", (0, y + 7, 0.25), (11, 4, 0.5), structure, "ground", bevel=0.15)
    for i in range(12):
        y = 4 + i * 5
        x = -8 if i % 2 == 0 else 8
        add_cone(f"WishCrystal_{i}", (x, y, 2), 1.2, 0.0, 4,
                 accent if i % 2 == 0 else cool, "accent", vertices=4)


def build_orrery(mats):
    ink, structure, accent, cool, gold = mats
    for index, y in enumerate((8, 24, 40, 56)):
        for side in (-1, 1):
            x = side * 13
            add_cylinder(f"ClockTower_{index}_{side}", (x, y, 4.5), 2.2, 9, structure, vertices=10)
            add_torus(f"ClockFace_{index}_{side}", (x, y - 2.25, 5.5), 1.6, 0.18,
                      gold, "accent", rotation=(math.radians(90), 0, 0))
        add_torus(f"OrbitWide_{index}", (0, y + 3, 5.5), 7.5, 0.16, cool,
                  "accent", rotation=(math.radians(72), 0, math.radians(index * 23)))
        add_torus(f"OrbitTall_{index}", (0, y + 3, 5.5), 5.5, 0.14, gold,
                  "accent", rotation=(0, math.radians(67), math.radians(index * 31)))
        add_uv_sphere(f"Bloodstar_{index}", (0, y + 3, 5.5), (1.6, 1.6, 1.6), accent, "accent")
        add_uv_sphere(f"Planet_{index}", (6, y + 3, 6.5), (0.8, 0.8, 0.8), cool, "accent", 10, 5)


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
        for column, x in enumerate(range(-18, 19, 6)):
            if abs(x) < 4 and row % 2 == 0:
                continue
            jitter_x = ((row * 11 + column * 7) % 5 - 2) * 0.18
            jitter_y = ((row * 5 + column * 13) % 5 - 2) * 0.12
            add_violet_flower(flower, x + jitter_x, y + jitter_y, 0.72 + (flower % 4) * 0.12, mats)
            flower += 1
    for index, y in enumerate((8, 24, 40, 56)):
        add_pointed_arch(y, mats, index)
        for side in (-1, 1):
            x = side * 14
            points = [(x, y - 5, 0), (x + side * 1.4, y - 2, 3),
                      (x - side * 1.2, y + 1, 6), (x, y + 4, 10)]
            add_curve(f"TrellisVine_{index}_{side}", points, 0.22, cool, "foliage")


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
        "foliage": (0.51, 0.01, 0.99, 0.49),
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
        build_saltwind(mats)
    elif stage == 3:
        build_wishcourt(mats)
    elif stage == 4:
        build_orrery(mats)
    else:
        build_violet_garden(mats)
    add_camera_and_lighting(stage, config, mats)

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
        "blend_source": str(blend_path.relative_to(ROOT)),
        "runtime_obj": obj_name,
        "loop_length": LOOP_LENGTH,
        "camera_path": config["camera"],
        "camera_target_z": config["target_z"],
        "scroll_speed": config["speed"],
        "lighting": {
            "world": config["world"],
            "sun_color": config["sun_color"],
            "sun_energy": config["sun_energy"],
        },
        "fog": config["fog"],
        "triangles": triangles,
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

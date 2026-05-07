import bpy
import math
import os
from mathutils import Vector


PROJECT_ROOT = "/Users/bxpressure/Desktop/pivot_horses"
VARIANT_DIR = os.path.join(PROJECT_ROOT, "assets/horses/reference/variants")
OUTPUT_DIR = os.path.join(PROJECT_ROOT, "assets/horses/reference/previews")


FILES = [
    "pph_arabian_w.glb",
    "pph_appaloosa.glb",
    "pph_bay_brown.glb",
    "pph_paint_bw.glb",
    "pph_percheron_blk.glb",
    "pph_shetland_wbr.glb",
]


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)
    for block in bpy.data.images:
        if not block.users:
            bpy.data.images.remove(block)


def world_bounds(objects):
    mins = Vector((1e9, 1e9, 1e9))
    maxs = Vector((-1e9, -1e9, -1e9))
    for obj in objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            world_corner = obj.matrix_world @ Vector(corner)
            mins.x = min(mins.x, world_corner.x)
            mins.y = min(mins.y, world_corner.y)
            mins.z = min(mins.z, world_corner.z)
            maxs.x = max(maxs.x, world_corner.x)
            maxs.y = max(maxs.y, world_corner.y)
            maxs.z = max(maxs.z, world_corner.z)
    return mins, maxs


def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100


def add_camera(bounds_min, bounds_max):
    center = (bounds_min + bounds_max) * 0.5
    width = bounds_max.x - bounds_min.x
    depth = bounds_max.y - bounds_min.y
    height = bounds_max.z - bounds_min.z

    bpy.ops.object.camera_add(location=(0.0, -8.0, 0.0))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(width, height) * 1.6

    camera.location = (
        center.x,
        bounds_min.y - max(depth * 4.0, 6.0),
        center.z + height * 0.10,
    )
    direction = center - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = camera


def add_lights(bounds_min, bounds_max):
    center = (bounds_min + bounds_max) * 0.5
    width = bounds_max.x - bounds_min.x
    height = bounds_max.z - bounds_min.z

    bpy.ops.object.light_add(type="SUN", location=(0, 0, 0))
    sun = bpy.context.object
    sun.rotation_euler = (math.radians(50), math.radians(5), math.radians(20))
    sun.data.energy = 2.0

    bpy.ops.object.light_add(
        type="AREA",
        location=(center.x - width * 0.3, bounds_min.y - 2.5, center.z + height * 0.7),
    )
    area = bpy.context.object
    area.rotation_euler = (math.radians(78), 0, math.radians(8))
    area.data.energy = 3500
    area.data.shape = "RECTANGLE"
    area.data.size = max(width * 1.4, 2.0)
    area.data.size_y = max(height * 1.2, 2.0)


def render_model(filename):
    reset_scene()
    setup_render()

    filepath = os.path.join(VARIANT_DIR, filename)
    bpy.ops.import_scene.gltf(filepath=filepath)
    imported = list(bpy.context.selected_objects)

    bounds_min, bounds_max = world_bounds(imported)
    add_camera(bounds_min, bounds_max)
    add_lights(bounds_min, bounds_max)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, filename.replace(".glb", ".png"))
    bpy.context.scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)


for filename in FILES:
    render_model(filename)


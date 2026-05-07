import bpy
import math
import os
import sys
from mathutils import Vector


def parse_args():
    if "--" not in sys.argv:
        raise SystemExit("Missing -- input.glb output.png")
    idx = sys.argv.index("--")
    args = sys.argv[idx + 1 :]
    if len(args) != 2:
        raise SystemExit("Usage: blender -b --python script.py -- input.glb output.png")
    return args[0], args[1]


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


input_path, output_path = parse_args()

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.resolution_percentage = 100

bpy.ops.import_scene.gltf(filepath=input_path)
imported = list(bpy.context.selected_objects)
mins, maxs = world_bounds(imported)
center = (mins + maxs) * 0.5
width = maxs.x - mins.x
depth = maxs.y - mins.y
height = maxs.z - mins.z

bpy.ops.object.camera_add(location=(center.x, mins.y - max(depth * 4.0, 6.0), center.z + height * 0.12))
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.ortho_scale = max(width, height) * 1.55
direction = center - camera.location
camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
scene.camera = camera

bpy.ops.object.light_add(type="SUN", location=(0, 0, 0))
sun = bpy.context.object
sun.rotation_euler = (math.radians(50), math.radians(5), math.radians(20))
sun.data.energy = 2.0

bpy.ops.object.light_add(
    type="AREA",
    location=(center.x - width * 0.3, mins.y - 2.5, center.z + height * 0.7),
)
area = bpy.context.object
area.rotation_euler = (math.radians(78), 0, math.radians(8))
area.data.energy = 3500
area.data.shape = "RECTANGLE"
area.data.size = max(width * 1.4, 2.0)
area.data.size_y = max(height * 1.2, 2.0)

os.makedirs(os.path.dirname(output_path), exist_ok=True)
scene.render.filepath = output_path
bpy.ops.render.render(write_still=True)


# Import a single 'wrl' and render it (without any fancy stuff).
# 'Tip' to see how blender settings translate to python, enable the 'scripting' window before clicking on buttons.
import bpy
import argparse
import sys
import math
import functools

def get_args():
    """ Arguments to the script need to be after '--'.
        eg:
        ./blender -b <input> --python <this_script> -- <script args>
    """
    parser = argparse.ArgumentParser(description="Render a '.wrl' file in blender")
    parser.add_argument('input_file')
    parser.add_argument('--output_file', default=None)
    parser.add_argument('--rotation', type=float, default=0.0)

    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    args = parser.parse_args(argv)
    if not args.output_file:
        args.output_file = f"{args.input_file}.png"

    return args

def set_renderer_options():
    # likely options: 'CYCLES', 'BLENDER_EEVEE_NEXT' or 'BLENDER_WORKBENCH'
    # Some require a 'gpu' so aren't suitable for github actions.
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.context.scene.render.engine = 'BLENDER_EEVEE'
    # Set an upper time limit of rendering 
    bpy.context.scene.cycles.time_limit = 180 # seconds

    # If there's no 'denoiser', then disable denoising.
    if bpy.context.scene.cycles.denoiser == '':
        print("Disabling denoiser")
        # Need to disable denoising for some builds of blender.
        bpy.context.scene.cycles.use_denoising = False
        bpy.context.view_layer.cycles.use_denoising = False

def import_and_render(input_file, output_file, object_rotation, camera_location):

    # Create an empty scene
    bpy.ops.scene.new(type='EMPTY')

    # Create new camera and set as active:
    camera = bpy.data.cameras.new('Camera')
    camera_object = bpy.data.objects.new('Camera', camera)
    bpy.context.collection.objects.link(camera_object)
    bpy.context.scene.camera = camera_object
    bpy.context.scene.camera.data.lens_unit = 'FOV'
    bpy.context.scene.camera.data.angle = math.radians(60)

    # Create a light source:
    for (i, location) in enumerate([(-2.0, -3.0, 2.0), (3.0, -3.0, 2.0)]):
        light = bpy.data.lights.new(f'Light{i}', type='POINT')
        light.energy = 200
        light_object = bpy.data.objects.new(f'Light{i}', object_data=light)
        bpy.context.collection.objects.link(light_object)
        light_object.location = location

    assembly = bpy.data.objects.new('ImportedAssembly', None)
    bpy.context.collection.objects.link(assembly)
    existing_objects = bpy.data.objects.keys()

    bpy.ops.import_scene.x3d(filepath=input_file, axis_forward='Y', axis_up='Z')

    # Assign all of the objects to have the 'imported assembly' as the parent.
    for obj in bpy.data.objects:
        if obj.name not in existing_objects:
            obj.parent = assembly

    # Get a 'target' to track .
    target = bpy.data.objects.get('ImportedAssembly', False)

    # Constraint the camera to 'look' at the target.

    constraint2 = bpy.context.scene.camera.constraints.new('TRACK_TO')
    constraint2.target = target
    constraint2.track_axis = 'TRACK_NEGATIVE_Z'
    constraint2.up_axis =  'UP_Y'

    # Moves object origin to 3D cursor wherever the cursor is located.
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.transform.rotate( value=object_rotation, orient_axis='X')

    target.select_set(True)

    # Get the diagonal of the rectangular bounding box (to figure out overall size).
    min_x = min([b.location.x for b in bpy.context.selected_objects])
    min_y = min([b.location.y for b in bpy.context.selected_objects])
    min_z = min([b.location.z for b in bpy.context.selected_objects])
    max_x = max([b.location.x for b in bpy.context.selected_objects])
    max_y = max([b.location.y for b in bpy.context.selected_objects])
    max_z = max([b.location.z for b in bpy.context.selected_objects])

    v = (max_x - min_x, max_y - min_y, max_z - min_z)
    scale = math.sqrt(sum([x*x for x in v]))


    scale /= math.atan(bpy.context.scene.camera.data.angle)

    # Set camera location
    bpy.context.scene.camera.location = tuple(map(lambda x : x * scale, camera_location))

    bpy.context.scene.render.filepath = output_file
    bpy.ops.render.render(write_still = True)

def main():
    args = get_args()
    camera_location = (0.1, -0.5, 1.0) # Rough 'direction', will convert to unit vector and add a 'fudge scale', final location is related to assembly size.
    mag = math.sqrt(sum([x*x for x in camera_location]))
    camera_location = tuple([v/mag for v in camera_location])
    
    set_renderer_options()
    import_and_render(args.input_file, args.output_file, args.rotation * math.pi / 180.0, camera_location)

main()

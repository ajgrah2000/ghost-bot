# Import a single 'wrl' and render it (without any fancy stuff).
import bpy
import argparse
import sys
import math

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

def import_and_render(input_file, output_file, object_rotation, camera_location):

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
    constraint = bpy.data.objects['Camera'].constraints.new('TRACK_TO')
    constraint.target = target
    constraint.track_axis = 'TRACK_NEGATIVE_Z'
    constraint.up_axis =  'UP_Y'

    # Moves object origin to 3D cursor wherever the cursor is located.
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.transform.rotate( value=object_rotation, orient_axis='Y')

    target.select_set(True)

    # Get the largest dimension from the selected objects (poor person's bounding box).
    max_x = max([b.dimensions.x for b in bpy.context.selected_objects])
    max_y = max([b.dimensions.y for b in bpy.context.selected_objects])
    max_z = max([b.dimensions.z for b in bpy.context.selected_objects])

    scale = max(max_x, max_y, max_z)

    # Fudge factor, place the camera further away..
    scale *= 4
    print(scale)
    # Set camera location
    print(tuple(map(lambda x : x * scale, camera_location)))
    bpy.context.scene.camera.location = tuple(map(lambda x : x * scale, camera_location))

    bpy.context.scene.render.filepath = output_file
    bpy.ops.render.render(write_still = True)

def main():
    args = get_args()
    camera_location = (0.1, -0.3, 1.0) # Unit-ish vector (will be scaled by the size of the imported model)
    import_and_render(args.input_file, args.output_file, args.rotation * math.pi / 180.0, camera_location)

main()

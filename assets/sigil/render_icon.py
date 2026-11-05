import bpy
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parent
material=bpy.data.materials.new('SigilIconWhite');material.use_nodes=True
nodes=material.node_tree.nodes;nodes.clear();surface=nodes.new('ShaderNodeEmission');surface.inputs['Color'].default_value=(1,1,1,1);surface.inputs['Strength'].default_value=1
output=nodes.new('ShaderNodeOutputMaterial');material.node_tree.links.new(surface.outputs[0],output.inputs['Surface'])
bpy.context.view_layer.material_override=material
scene=bpy.context.scene;scene.camera.location=(0,-200,52);scene.camera.rotation_euler=(Vector((0,0,52))-scene.camera.location).to_track_quat('-Z','Y').to_euler();scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=120
scene.render.resolution_x=256;scene.render.resolution_y=512;scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.render.filepath=str(root.parents[1]/'content/materials/zombiesurvival/sigil/icon.png')
bpy.ops.render.render(write_still=True)

import bpy,math,json,sys
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=.0254
materials={}
for name,color,metal,rough in [('sigil_frame',(.12,.17,.21,1),.8,.3),('sigil_shell',(.12,.65,.9,.45),.2,.16),('sigil_core',(.5,1,1,1),.05,.12)]:
 m=bpy.data.materials.new(name);m.diffuse_color=color;m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=color;p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if name=='sigil_shell':
  p.inputs['Alpha'].default_value=.38
  p.inputs['Transmission Weight'].default_value=.4
 if name!='sigil_frame':p.inputs['Emission Color'].default_value=color;p.inputs['Emission Strength'].default_value=1 if name=='sigil_shell'else 3
 materials[name]=m
objects=[]
def mesh(name,verts,faces,mat):
 m=bpy.data.meshes.new(name);m.from_pydata(verts,[],faces);m.update();o=bpy.data.objects.new(name,m);scene.collection.objects.link(o);o.data.materials.append(materials[mat]);objects.append(o);return o
def ring(z,r,n=6,angle=0):return[(math.cos(angle+i*2*math.pi/n)*r,math.sin(angle+i*2*math.pi/n)*r,z)for i in range(n)]
verts=ring(0,8.25)+ring(3,7.3)+ring(6,4.5);faces=[tuple(reversed(range(6))),tuple(range(12,18))]
for level in range(2):
 for i in range(6):j=(i+1)%6;faces.append((level*6+i,level*6+j,(level+1)*6+j,(level+1)*6+i))
mesh('Frame',verts,faces,'sigil_frame')
for i in range(3):
 a=i*2*math.pi/3;r=6.7
 local=[(-1.3,-1,4),(1.3,-1,4),(0,-1,21),(-1.3,1,4),(1.3,1,4),(0,1,21)]
 points=[(math.cos(a)*(r+x)-math.sin(a)*y,math.sin(a)*(r+x)+math.cos(a)*y,z)for x,y,z in local]
 mesh('Stabilizer_'+str(i),points,[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)],'sigil_frame')
verts=[(0,0,13)]+ring(24,5.5,6,math.pi/6)+ring(41,4.2,6,math.pi/6)+[(0,0,52.25)]
faces=[]
for i in range(6):
 j=(i+1)%6;faces.extend([(0,j+1,i+1),(i+1,j+1,j+7,i+7),(i+7,j+7,13)])
mesh('Crystal',verts,faces,'sigil_shell')
verts=[(0,0,14)]+ring(29,1.6,4,math.pi/4)+[(0,0,47)]
mesh('Core',verts,[(0,(i+1)%4+1,i+1)for i in range(4)]+[(i+1,(i+1)%4+1,5)for i in range(4)],'sigil_core')
collider=mesh('Collision',[(-8.25,-8.25,-.44685),(8.25,-8.25,-.44685),(8.25,8.25,-.44685),(-8.25,8.25,-.44685),(-8.25,-8.25,52.25),(8.25,-8.25,52.25),(8.25,8.25,52.25),(-8.25,8.25,52.25)],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'sigil_frame');collider.hide_render=True;collider.hide_set(True)
for obj in objects:
 for vertex in obj.data.vertices:
  if obj==collider:vertex.co.z*=2
  else:vertex.co*=2
 obj.data.update()
source=root/'source';source.mkdir(exist_ok=True)
header='version 1\nnodes\n0 "root" -1\nend\nskeleton\ntime 0\n0 0 0 0 0 0 0\nend\n'
def smd(name,items):
 out=[header,'triangles\n'];count=0
 for obj in items:
  obj.data.calc_loop_triangles()
  for tri in obj.data.loop_triangles:
   out.append(obj.data.materials[tri.material_index].name+'\n');normal=tri.normal
   for index in tri.vertices:
    point=obj.matrix_world@obj.data.vertices[index].co
    out.append('0 '+' '.join(f'{n:.7f}'for n in (*point,*normal,point.x/32+.5,point.z/64))+'\n')
   count+=1
 out.append('end\n');(source/name).write_bytes(''.join(out).encode());return count
counts={}
counts['frame']=smd('frame.smd',[o for o in objects if o.name=='Frame'or o.name.startswith('Stabilizer_')]);counts['crystal']=smd('crystal.smd',[o for o in objects if o.name=='Crystal']);counts['core']=smd('core.smd',[o for o in objects if o.name=='Core']);smd('collision.smd',[collider]);(source/'idle.smd').write_bytes(header.encode())
assert sum(counts.values())<=120,counts
qc='''$modelname "zombiesurvival/sigil/sigil.mdl"
$bodygroup "frame"
{
 studio "frame.smd"
 blank
}
$bodygroup "crystal"
{
 studio "crystal.smd"
 blank
}
$bodygroup "core"
{
 blank
 studio "core.smd"
}
$cdmaterials "zombiesurvival/sigil/"
$surfaceprop "metal"
$bbox -16.5 -16.5 -0.8937 16.5 16.5 104.5
$hboxset "default"
$hbox 0 "root" -16.5 -16.5 -0.8937 16.5 16.5 104.5
$sequence "idle" "idle.smd" fps 1
$collisionmodel "collision.smd"
{
 $mass 100
}
''';(source/'sigil.qc').write_bytes(qc.encode())
scene.world.color=(.08,.08,.08)
bpy.ops.object.camera_add(location=(150,-200,134));camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,52))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=136;scene.camera=camera
for pos,power,size in [((25,-35,75),2200,45),((-30,-10,35),1500,35),((0,35,55),2500,30)]:
 bpy.ops.object.light_add(type='AREA',location=tuple(value*2 for value in pos));light=bpy.context.object;light.data.energy=power*1200;light.data.shape='DISK';light.data.size=size*2;light.rotation_euler=(Vector((0,0,50))-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=1024;scene.render.resolution_y=1024;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True
scene.render.filepath=str(root/'sigil-preview.png')
bpy.data.orphans_purge(do_recursive=True)
assert len(bpy.data.libraries)==0
bpy.ops.wm.save_as_mainfile(filepath=str(root/'sigil.blend'))
bpy.ops.render.render(write_still=True)
(root/'authoring.json').write_bytes((json.dumps(dict(projectAuthored=True,externalAssetCopies=False,triangles=counts,totalTriangles=sum(counts.values()),collisionBounds=[[-8.25,-8.25,-.8937],[8.25,8.25,104.5]],visualBounds=[[-16.5,-16.5,-.8937],[16.5,16.5,104.5]],sizeMultiplier=2,bodygroups=['frame','crystal','core'],source='Blender mesh exported as SMD by build_sigil.py'),indent=2)+'\n').encode())
print(json.dumps(counts))

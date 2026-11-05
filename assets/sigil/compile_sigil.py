from pathlib import Path
import json,struct,subprocess,uuid,hashlib,sys
r=Path('.').resolve();build=Path('D:/tmp/zs-overhaul-tools')/('sigil-asset-build-'+uuid.uuid4().hex);game=build/'garrysmod';game.mkdir(parents=True)
(game/'gameinfo.txt').write_bytes(('"GameInfo"\n{\n "game" "Project sigil build"\n "FileSystem"\n {\n  "SteamAppId" "4000"\n  "SearchPaths"\n  {\n   "Game" "|gameinfo_path|."\n   "Game" "C:/Program Files (x86)/Steam/steamapps/common/GarrysMod/garrysmod"\n   "Game" "C:/Program Files (x86)/Steam/steamapps/common/GarrysMod/hl2"\n  }\n }\n}\n').encode())
folder=game/'materials/zombiesurvival/sigil';folder.mkdir(parents=True)
header=bytearray(64);header[:4]=b'VTF\0';struct.pack_into('<IIIHHIHH',header,4,7,1,64,4,4,0,1,0);struct.pack_into('<3f',header,32,1,1,1);struct.pack_into('<fI',header,48,1,13);header[56]=3;struct.pack_into('<I',header,57,0xffffffff)
(folder/'white.vtf').write_bytes(header+struct.pack('<HHI',65535,65535,0)*3)
(folder/'sigil_frame.vmt').write_bytes(b'"VertexLitGeneric"\n{\n "$basetexture" "zombiesurvival/sigil/white"\n "$model" "1"\n "$color2" "[0.32 0.38 0.42]"\n "$phong" "1"\n "$phongexponent" "18"\n}\n')
(folder/'sigil_shell.vmt').write_bytes(b'"UnlitGeneric"\n{\n "$basetexture" "zombiesurvival/sigil/white"\n "$model" "1"\n "$translucent" "1"\n "$additive" "1"\n "$alpha" "0.3"\n}\n')
(folder/'sigil_core.vmt').write_bytes(b'"UnlitGeneric"\n{\n "$basetexture" "zombiesurvival/sigil/white"\n "$model" "1"\n "$additive" "1"\n}\n')
(game/'cfg').mkdir()
(game/'cfg/mount.cfg').write_text('"mountcfg" {}',encoding='utf-8')
exe=Path('C:/Program Files (x86)/Steam/steamapps/common/GarrysMod/bin/win64/studiomdl.exe')
p=subprocess.run([str(exe),'-nop4','-game',str(game),str(r/'assets/sigil/source/sigil.qc')],cwd=exe.parent,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(r/'tests/results/sigil_render_compiler.log').write_bytes(p.stdout);assert p.returncode==0,p.stdout.decode(errors='replace')
outputs=[p for base in [game/'models',game/'materials']for p in base.rglob('*')if p.is_file()];assert len(outputs)>=4,[str(p)for p in outputs]
files={}
previous=json.loads((r/'tests/results/sigil_render_asset_build.json').read_text(encoding='utf-8'))['files'] if '--replace-known' in sys.argv else {}
for p in outputs:
 target=r/'content'/p.relative_to(game)
 if target.exists():assert hashlib.sha256(target.read_bytes()).hexdigest()==previous.get(target.relative_to(r).as_posix())
for p in outputs:
 target=r/'content'/p.relative_to(game);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(p.read_bytes());files[target.relative_to(r).as_posix()]=hashlib.sha256(target.read_bytes()).hexdigest()
report=dict(buildRoot=str(build),compiled=True,compiler=str(exe),files=files,authoring=json.loads((r/'assets/sigil/authoring.json').read_text(encoding='utf-8')))
(r/'tests/results/sigil_render_asset_build.json').write_bytes((json.dumps(report,indent=2)+'\n').encode());print({'files':len(files),'triangles':report['authoring']['totalTriangles']})

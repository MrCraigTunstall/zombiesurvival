The sigil is a project-authored Blender mesh with 88 triangles: 56 for the frame, 24 for the crystal shell, and 8 for the health core. The enlarged model is 104.5 Source units tall. It has one root bone, three bodygroups and one box collision hull with mass 100.

`build_sigil.py` generates `sigil.blend`, the preview, SMD sources and QC. Procedural geometry changes belong in that script. `sigil.blend` is the editable Blender project. The collision mesh is separate from the visible meshes.

From the repository root in PowerShell:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python-exit-code 1 --python assets/sigil/build_sigil.py
python -B assets/sigil/compile_sigil.py --replace-known
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background assets/sigil/sigil.blend --python-exit-code 1 --python assets/sigil/render_icon.py
```

The compiler writes into an isolated build directory. `--replace-known` checks the previously recorded output hashes before replacing owned content. Build reports are under `tests/results`. A rebuild changes those outputs and needs new verification evidence.

Ten runtime files live in `content/models/zombiesurvival/sigil` and `content/materials/zombiesurvival/sigil`. The HUD icon is rendered from the same mesh. The asset has no external mesh, texture or Workshop dependency; the effects use base-game sprites.

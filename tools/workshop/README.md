# Workshop packaging

Run `package.ps1` with PowerShell 7.2 or newer after committing the runtime source. It creates two clean addon folders and `.gma` archives under a fresh `dist/workshop-<commit>` directory. It never publishes, deletes prior outputs, changes source files or starts the game.

```powershell
pwsh -File tools/workshop/package.ps1 `
    -ExpectedCommit <full-source-commit> `
    -GamemodeWorkshopId 1357369797 `
    -ContentWorkshopId 1357352304 `
    -DataStaticNavigation
```

Those IDs are the existing project items; verify their ownership before uploading. `-OutputRoot` can select another fresh directory under this repository's `dist`. `-StageOnly` stops before invoking GMad. The installed GMad path and addon titles can be supplied explicitly.

The gamemode archive contains its Lua, descriptor, icons, backgrounds and Mako navigation data under `data_static/zombiesurvival/navmeshes`. The content archive contains the runtime materials, models, sound and fonts. GMad's unsupported software/console VTX companions are listed as exclusions and remain in source.

The supplied Workshop IDs produce two explicit release configuration variants: the packaged descriptor identifies the gamemode item, and the packaged resource configuration defaults or falls back to the content item. A server can still set `zs_content_workshop` to `0` to disable that registration. The source files retain their configurable blank defaults. Every variant has its source hash, release hash and exact diff in `manifest.json`.

No `.py`, `.ps1`, `.blend`, `.smd`, `.qc`, `.vmf`, development records, tests, backup files or source-control metadata enter either archive. Each archive is reread to verify all paths, payload SHA256 hashes, per-file CRC32 values and the final archive CRC32. The manifest also records the source commit, all source/staged hashes, GMad hash, exclusions and build status. Set the content item as a required item of the gamemode when publishing; the builder does not edit Steam Workshop relationships.

The layout follows [Facepunch's Workshop packaging guide](https://wiki.facepunch.com/gmod/Workshop_Addon_Creation) and [GMad's file whitelist](https://github.com/Facepunch/gmad/blob/master/include/AddonWhiteList.h).

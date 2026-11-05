# Optional D3bot optimization patch

This patch packages the D3bot changes used with this Zombie Survival update. The addon stays separate from the gamemode; it is not bundled here.

Base: [Dadido3/D3bot at bf3399e07dada622f9009232c91432c68c91f800](https://github.com/Dadido3/D3bot/tree/bf3399e07dada622f9009232c91432c68c91f800).

D3bot is based on AzBot. Keep the upstream in-game attribution and README terms; this patch does not assign a new license to upstream code.

## Install

1. Obtain the [exact base archive](https://github.com/Dadido3/D3bot/archive/bf3399e07dada622f9009232c91432c68c91f800.zip) and place its addon files in `garrysmod/addons/d3bot/`.
2. From that pristine addon folder, use Git to check and apply this patch:

   ```sh
   git apply --check /path/to/zombiesurvival/extras/d3bot-optimization.patch
   git apply /path/to/zombiesurvival/extras/d3bot-optimization.patch
   ```

3. Follow the upstream instructions for navmeshes, optional ULX tools and bot configuration. Keep local configuration and navmesh backups when upgrading an existing installation. Avoid loading a second copy of D3bot.

Apply this patch only to the pinned base. It includes navigation, target selection, barricade interaction, survivor actions and Zombine support used by the recorded local checks.

## Provenance

- Base archive SHA256: `20bbad8c5f97c5903d83abc7c2c7e2ca6deceed1501bd35b519a446f325fc1e6`
- Patch SHA256: `3eb2cfe362aa54a99c3132b68dc737cfef2afab26c7e0df304d43abaf2f7c1bd`
- Result: 56 Lua files; SHA256 of their sorted compact JSON path-to-SHA256 mapping: `f0511fabcc7b5bf2b802277c239fd7a96514cff5d08e7b5a45a8c11bdb3bff98`.

The patch reconstructs the accepted addon source exactly. Existing Windows local/dedicated and 128-bot results are scoped evidence; no whole-game FPS percentage or universal platform/addon compatibility is claimed.

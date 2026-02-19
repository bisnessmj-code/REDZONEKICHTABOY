# HUD Reticle Options

Currently, there are 2 versions of the HUD reticle:

1. `hud_reticle.gfx` in the `stream` folder – the default file we provide. This removes the red and white X of the GTA default killfeed.
2. `hud_reticle.gfx` in the `stream v2` folder – identical to the default, but in this version, when aiming at a player, the reticle does not turn red and you are not notified that you are targeting a player.

## Usage

- The folder considered by the game is always `stream`.
- By default, the script is set up to remove the GTA default killfeed, since the `hud_reticle.gfx` file is present.

### Using the v2 HUD Reticle

1. Delete the `hud_reticle.gfx` in the active `stream` folder.
2. Copy the `hud_reticle.gfx` from `stream v2` into the `stream` folder.
3. Configure the script via its config file to enable the custom killfeed.
   > It is recommended to remove the default GTA killfeed when using the script's killfeed.

### Using the default GTA killfeed

1. Delete the `hud_reticle.gfx` from the active `stream` folder, or delete the entire `stream` folder.
2. Open the `fxmanifest.lua` file and comment out the line:
   ```lua
   'stream/hud_reticle.gfx'
   ```
3. The GTA default killfeed (red and white X) will now appear.

**Important Notes:**

- If you leave the default GTA killfeed active and also enable the script's killfeed via the config, both killfeeds will appear simultaneously.
- To use only the script's killfeed, make sure the `hud_reticle.gfx` is present in `stream` and the line in `fxmanifest.lua` is active (not commented out), while the default GTA killfeed is removed.

This setup allows you to fully control whether you want the default killfeed, the v2 HUD reticle, or both at the same time.

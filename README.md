# kuro-haru: NYSU combat system

Combat scripts for **NYSU Testing Hub** (Now You See Us). R6 rig, server-checked combat.
The code lives here and gets synced into Roblox Studio with **Rojo**.

## Where everything goes in Studio

| In this repo | Shows up in Studio as | What it is |
|---|---|---|
| `src/shared/` | `ReplicatedStorage > Combat` | Settings and move data that both server and client read |
| (created by Rojo) | `ReplicatedStorage > CombatRemotes` | `Action` and `Effect` RemoteEvents (client to server, server to clients) |
| `src/server/` | `ServerScriptService > CombatServer` | The server side: decides what actually happens (anti-cheat) |
| `src/client/` | `StarterPlayer > StarterPlayerScripts > CombatClient` | Reads your keys and asks the server to act |

Rojo **owns** those four folders. Anything you add inside them by hand in Studio gets
removed on the next sync, so put changes in the repo instead (or ask Claude to).
Everything else in your place (maps, models, your own folders) is left alone.

## Controls (default)

- **M1 (left click)**: 4-hit combo; the last hit launches.
- **F (hold)**: guard, blocks hits from the front. Tapping F right before a hit lands **parries** it.
- **Q**: dash the way you're walking (forward if standing). In the air: one air dash per jump.

## Tuning without coding

- `src/shared/CombatSettings.luau`: global numbers (combo reset time, parry window, chip damage, keybinds, debug printing).
- `src/shared/Moves/BasicCombo.luau`: the M1 string, one block per hit (damage, startup, hitstun, knockback, hitbox, animation id).
- `src/client/CombatEffects.luau`: where hit VFX, sounds and camera shake go. Right now a hit flashes the victim white.

Before publishing, turn off `Debug`, `ShowHitboxes` and `SpawnTestDummy` in `CombatSettings`.
Set `TestDummyGuards = true` to make the dummy hold guard (for testing blocks and guard breaks).

## R6 only

The game is built for R6. Set it in Studio under **Avatar Settings** (Avatar tab), or
**Game Settings > Avatar** on older Studio versions, then publish. If an R15 character
ever spawns, the server prints a warning in Output.

Animation ids must be owned by the same group/account that owns the place, or Roblox
refuses to load them.

Timing is in **frames at 60 per second** (60 = 1 second), like fighting games.

## One-time setup on your PC

You already have the Rojo plugin in Studio. The plugin needs a small helper program
running on your PC that reads these files. The friendliest way:

1. Install **GitHub Desktop** (desktop.github.com), sign in, then *File > Clone repository > KuroHarumada/kuro-haru*.
2. Install **Visual Studio Code** (code.visualstudio.com).
3. In VS Code, open the Extensions tab and install **Rojo** (by evaera). It installs the Rojo helper for you.
4. In VS Code, *File > Open Folder* and pick the cloned `kuro-haru` folder.

## Syncing into Studio (every time)

1. In GitHub Desktop, switch to the branch you want to test and press **Fetch / Pull** to get the latest code.
2. In VS Code, open the Rojo panel (or the command palette, `Ctrl+Shift+P`, "Rojo: Open menu") and start `default.project.json`.
3. In Studio, open NYSU Testing Hub, open the Rojo plugin and press **Connect**.
4. The folders above appear. Keep it connected and new pulls show up live.

If Rojo warns that the plugin and server versions don't match, update the plugin in
Studio (or the VS Code extension) so both are on the same version.

## Quick check after syncing

Press **Play** and open the Output window. You should see `[Combat] Server loaded`
and `[Combat] Client loaded`. Clicking, pressing F and pressing Q prints a line for each.

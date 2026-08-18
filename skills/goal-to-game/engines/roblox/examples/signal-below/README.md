# Signal Below

Signal Below is a compact exploration and repair game set at a storm-darkened remote signal station. Reach four perimeter relays before the four-minute emergency window closes, then watch the station's real tracking dish acquire the rescue signal.

## Play

- Move with normal Roblox character controls: WASD on keyboard, mouse to look, and Space to jump.
- Follow the illuminated paths to Relay A, B, C, and D.
- Hold **E** at each relay console to repair it.
- Repair all four relays within 240 seconds to begin dish alignment and win on signal lock.
- If time expires, repair prompts are disabled and the HUD shows failure. Use **RESTART SEQUENCE** to retry.

## Required imported asset

The place must contain `Workspace.ThrixelAssets.TrackingSignalDish`, imported separately from Thrixel. The model must have the `GoalToGameAsset=true` attribute and these direct child Models:

- `AzimuthYoke_Group` with `GoalToGameMovingPart=true`
- `DishAssembly_Group` with `GoalToGameMovingPart=true`
- `Pedestal_Group`
- `StaticBody`
- `SupportHardware_Group`

The server caches the child model pivots when play begins. During activation it rotates `AzimuthYoke_Group` horizontally and tilts `DishAssembly_Group` independently. It never pivots the parent dish; the pedestal, static body, and support hardware remain fixed.

## Run with Rojo

From this directory, serve `default.project.json` (for example, `rojo serve --port 34872`) and connect Roblox Studio with the Rojo plugin. Start Play after the imported asset is present. Server-authoritative scripts build `Workspace.SignalBelowRuntime`, manage prompts, relay state, timer, victory/failure, retry, and dish motion. The client script only presents the HUD.

Runtime generation creates the ground, central deck, walkable paths, path lights, four labeled relay structures, SpawnLocation, emergency mast, prompts, fog, and atmosphere. No generated level geometry is stored as a binary Roblox file and the runtime folder disappears when Play stops.

## Verification status

Verified locally in connected Studio Play mode on 2026-08-18: intended spawn and HUD present, exactly four prompts, `0 / 4` initial progress, all relay transitions, victory activation, controlled timeout failure, retry/reset path, and clean return to Edit mode. Transform inspection confirmed distinct yoke yaw and dish elevation changes while all three stationary groups stayed fixed. Studio logged no runtime errors or warnings. `git diff --check` passed; the local Rojo CLI build was inconclusive because that CLI process reported `home directory not found`, while live Rojo sync was confirmed from the Studio tree and successful playtest. Screen-capture requests timed out, so no exploratory captures are claimed. No public URL, final evidence package, performance claim, or publication is asserted.

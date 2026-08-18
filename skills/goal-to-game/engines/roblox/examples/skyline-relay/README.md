# Skyline Relay

Skyline Relay is a rooftop delivery time trial. Carry an emergency power cell across a dusk-lit
logistics district and clear seven checkpoints in order before the 150-second grid-failure window
closes. It is deliberately a different genre from Signal Below and keeps each player's run,
timer, splits, and best time independent on the server.

## Play

- Move with normal Roblox controls: WASD on keyboard, mouse to look, and Space to jump.
- Follow the cyan skybridges and gold-highlighted next checkpoint.
- Cross checkpoints 01–07 in order. Skipped checkpoints do not count.
- Falling from the course resets the character and begins a new run.
- Deliver the cell at Emergency Grid before the timer reaches zero, then use **RUN IT AGAIN**
  to retry and improve the locally tracked best time.

The HUD shows the next rooftop and distance, current checkpoint, last split, remaining time, and
horizontal movement speed. The carried power cell is attached by the server and disappears only
on a completed or failed delivery.

## Runtime structure

Rojo maps only authored scripts. At Play start, server code builds `Workspace.SkylineRelayRuntime`
with seven rooftop towers, six sloped skybridges, checkpoint touch volumes, route lights, a fall
reset plane, SpawnLocation, skyline lighting, and the four imported Thrixel models when they exist
under `Workspace.ThrixelAssets`. Missing imports fall back to explicit labelled placeholders instead
of failing the round. The real power-cell carrier is fitted and welded to each player; drone rotors,
the gantry trolley, and the gantry hoist animate as independent parts. Checkpoint order, timers,
retry eligibility, completion times, and best times are server-authoritative; the client only
renders the local HUD and local checkpoint colors.

In Studio, `Workspace.SkylineRelayRuntime.StudioTestControl` accepts `Checkpoint`, `Fail`, and
`Reset` commands for deterministic local play checks. It exists only while running in Studio.

## Thrixel asset set

The authorized generation run created a dedicated Thrixel project, `Skyline Relay`
(`b8ae85a7-2f87-458b-950b-3c6c90eeb2d7`), and produced the four ranked hero props. Each source was
visually inspected and refined; the moving assets went through Architect, a focused edit, Detailer
at adherence 9, a material pass, and grouping that preserves exact moving nodes. Static props used
Sculptor, a focused material pass, and grouping. Final GLBs and the complete identifier chain are in
[`assets/thrixel`](assets/thrixel).

Import each final GLB through Studio's 3D Importer under `Workspace.ThrixelAssets`, enable
**Import Only as a Model**, and name the resulting root exactly as listed:

1. `emergency-power-cell-carrier.glb` → `EmergencyPowerCellCarrier`
2. `cargo-drone.glb` → `CargoDrone` (keeps `Rotor_FL`, `Rotor_FR`, `Rotor_RL`, `Rotor_RR`)
3. `freight-gantry.glb` → `FreightGantry` (keeps `Trolley`, `Hoist`)
4. `delivery-terminal.glb` → `DeliveryTerminal`

The runtime marks clones with `GoalToGameAsset=true` and the animation system marks each discovered
moving node with `GoalToGameMovingPart=true`. Do not rename those moving nodes after import.

## Run with Rojo

From this directory, serve `default.project.json` (for example, `rojo serve --port 34873`) and
connect a new Roblox Studio place with the Rojo plugin. Do not sync this example into the existing
Signal Below place. Start Play after the three mapped source trees appear.

## Verification status

Verification on 2026-08-18: all four authored Luau files compiled successfully in Studio, their
byte hashes matched the repository sources, `git diff --check` passed, and all 10 Roblox
evidence-tool unit tests passed. A connected Studio Play session verified the initial HUD and cargo,
out-of-order checkpoint rejection, all seven ordered transitions, physical checkpoint contact,
delivery, controlled failure, and the real retry-button reset after both end states. The user also
completed the full keyboard-driven route through checkpoint 07. The runtime console was empty. A
five-second desktop sample at a 1120-pixel viewport measured 60.02 average FPS, 51.93 minimum
instantaneous FPS, and a 19.26 ms maximum frame; this is a short local sample, not a shipping-device
benchmark. The narrow-viewport HUD layout was also checked in iPhone 17 Pro landscape during the
connected test pass.

Rojo 7.6.1 successfully built dedicated Signal Below and Skyline Relay `.rbxlx` files on
2026-08-18. A second connected Play test exercised the imported-asset branch with four temporary
local models: it produced four runtime assets and zero placeholders, attached the real-asset cargo
path, and measured independent rotor, trolley, and hoist transform changes with no console output.
Only the four tagged temporary test models were then removed; the existing Signal Below asset was
preserved.

The connected place remains unpublished. Actual final GLB import, the post-import instance audit,
six-view evidence, longer desktop/mobile performance captures, playable URL, and gameplay video
still require the Studio/account-bound finishing pass. No screenshot, public URL, video, or
publication is claimed here.

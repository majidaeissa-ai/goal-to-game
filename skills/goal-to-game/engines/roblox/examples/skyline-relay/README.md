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
reset plane, SpawnLocation, skyline lighting, and explicit Thrixel placeholders. Checkpoint order,
timers, retry eligibility, completion times, and best times are server-authoritative; the client
only renders the local HUD and local checkpoint colors.

In Studio, `Workspace.SkylineRelayRuntime.StudioTestControl` accepts `Checkpoint`, `Fail`, and
`Reset` commands for deterministic local play checks. It exists only while running in Studio.

## Ranked Thrixel asset plan

No cubes should be spent without explicit user authorization. Until the required Thrixel flow is
available and authorized, the four most visible missing assets are placed in the course as purple,
labelled blocks with `GoalToGamePlaceholder=true`:

1. `EmergencyPowerCellCarrier` — hero delivery pack with emissive cell and harness.
2. `CargoDrone` — rooftop logistics drone with independently moving rotors.
3. `FreightGantry` — industrial loading frame with an independently moving hoist.
4. `DeliveryTerminal` — final emergency-grid receiver and control console.
5. Modular rooftop service cores and access housings.
6. Solar arrays, HVAC clusters, vents, and cable trays.
7. Neon district signage, barriers, and parcel props.

Before replacing any block, inspect the generated model, preserve exact moving-part node names in
`keep_groups`, validate Roblox mesh limits, import through Studio under `Workspace.ThrixelAssets`,
tag real asset and moving-part attributes, and audit the actual imported instances.

## Run with Rojo

From this directory, serve `default.project.json` (for example, `rojo serve --port 34873`) and
connect a new Roblox Studio place with the Rojo plugin. Do not sync this example into the existing
Signal Below place. Start Play after the three mapped source trees appear.

## Verification status

Verification on 2026-08-18: all four authored Luau files compiled successfully in Studio, their
byte hashes matched the repository sources, `git diff --check` passed, and all 10 Roblox
evidence-tool unit tests passed. A connected Studio Play session verified the initial HUD and cargo,
out-of-order checkpoint rejection, all seven ordered transitions, physical checkpoint contact,
delivery, controlled failure, and the real retry-button reset after both end states. The runtime
console was empty. A five-second desktop sample at a 1120-pixel viewport measured 60.02 average FPS,
51.93 minimum instantaneous FPS, and a 19.26 ms maximum frame; this is a short local sample, not a
shipping-device benchmark. The narrow-viewport HUD layout was also checked in iPhone 17 Pro
landscape during the connected test pass.

The test used the existing unsaved `Place1.rbxl` session and returned Studio to Edit mode without
saving or publishing. The installed Rojo shim previously reported `home directory not found`, so no
successful `.rbxlx` build is claimed. Skyline Relay still requires a complete keyboard-driven course
traversal, a dedicated place, real Thrixel imports, comprehensive desktop/mobile performance runs,
six-view evidence, and account-authorized publication/video. No screenshot, public URL, video, or
publication is claimed.

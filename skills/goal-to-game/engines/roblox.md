# Roblox Studio

Engine-specific rules for the Roblox path. Read `../SKILL.md` first. The shared Thrixel generation,
pricing, quality, grouping, concurrency, and account rules stay there; do not copy or override them.

Read [roblox/PITFALLS.md](roblox/PITFALLS.md) before the first import.

## Non-negotiable completion contract

A Roblox build is not complete because Luau parses or a `.rbxlx` file exists. Before presenting it:

1. Verify Roblox Studio and Rojo are available. If Studio is unavailable, stop at the Studio gate.
2. Use the required Thrixel MCP flow: `thrixel_account_status`, `thrixel_start_project`,
   `thrixel_group_parts`, and `thrixel_download`. Never replace it with hand-written API polling.
3. Inspect the generated model before grouping. Copy exact moving-part names into `keep_groups`.
4. Make every final Roblox `MeshPart` satisfy the current Roblox import constraints before import.
5. Import into Studio and audit the **actual imported instances**, not a guessed manifest.
6. Run the verification plugin and preserve the collector's SHA-256 evidence ledger.
7. Playtest the game and measure both desktop and mobile-sized viewport runs.
8. Publish only at the user's Roblox-account authorization boundary.
9. For a bounty/review build, provide public playable URL, video, tested versions, and real evidence.

Never mark an evidence requirement complete from a placeholder, a planned value, or a Boolean written
by the build script itself.

## Project shape

Use a Rojo-compatible source tree but do not let Rojo own the imported asset container:

```text
game/
  default.project.json
  src/
    client/
    server/
    shared/
  thrixel_assets/
    source/
    grouped/
  evidence/
  build.rbxlx
```

Map authored scripts/UI through Rojo. Keep imported models under `Workspace/ThrixelAssets` and do not
map that folder from the filesystem, because a Rojo sync must never erase Studio-imported MeshIds.

## Asset ingest: Thrixel to visible Roblox instances

For every important asset:

1. Decide what must move before generation.
2. Generate with the path selected by the shared skill.
3. Run `thrixel_inspect_model` and read exact node names.
4. Call `thrixel_group_parts`, passing only genuinely moving pieces in `keep_groups`.
5. Use Thrixel's free reduction/rebake tools where needed before adding local geometry transforms.
6. Download the grouped result. Prefer **GLB** for this path because hierarchy and PBR material data
   stay in one inspectable file.
7. Validate the result. No final mesh may exceed Roblox's per-mesh triangle limit. Reject obvious
   non-manifold/zero-thickness output rather than inventing a silent repair.
8. Import through Studio. A fully unattended Open Cloud route is optional only if it can prove the
   descendant MeshPart mapping; a returned Model/package ID is not proof of child MeshIds.
9. After import, place the model under `Workspace/ThrixelAssets`, then run the verification plugin.
   The audit records the actual MeshIds, texture maps, sizes, pivots, collision settings, and names.

The explicit Studio Importer gate is acceptable. Hiding a manual import behind prose is not.

## Materials and textures

One `MeshPart` has one appearance. Preserve separate objects for semantic material regions that need
different appearance (paint/glass/chrome/rubber/etc.).

Use `SurfaceAppearance` for PBR maps. Inspect the imported hierarchy and verify each expected map is
on the intended MeshPart. If a mesh is invisible or grey, diagnose in this order:

1. moderation state;
2. ownership/experience permission;
3. actual imported MeshId/texture IDs;
4. SurfaceAppearance parenting/map assignment;
5. UVs and normal orientation.

Do not repeatedly re-upload a correctly referenced asset merely because moderation is pending.

## Scale and orientation

Never assume a global Thrixel forward axis. Put a default Roblox avatar/reference rig beside the
asset, correct scale and forward direction once at the model root, then record the correction in
evidence. Gameplay code must not accumulate trial-and-error rotations on individual parts.

## Moving parts and pivots

`keep_groups` protects addressability, not the mechanical hinge location. A wheel may rotate around
its geometric center; a door or turret usually needs an explicit pivot/attachment at the real axis.

For every required moving Thrixel part:

- tag it with attribute `GoalToGameMovingPart = true`;
- tag the owning asset root with `GoalToGameAsset = true`;
- animate around an explicit pivot;
- run the verification plugin while it moves;
- capture at least one evidence view that visibly demonstrates independent motion.

## Collision and performance

Choose collision deliberately:

- decoration: collision off;
- static architecture: box/hull unless exact collision is gameplay-critical;
- moving pieces: simple collision and an intentional collision group;
- traversal surfaces: playtest seams, slopes, stairs, and doorways.

Set `CollisionFidelity` and `RenderFidelity` deliberately on imported meshes.

The minimum review bar is 30 FPS on the tested mobile-sized viewport. Record the viewport size,
sampling window, average/minimum FPS, instance count, MeshPart count, and moving-part count. Do not
claim a device result when the test was only a resized desktop Studio viewport; label it exactly.

## Verification: evidence must come from Studio

Use [roblox/plugin/GoalToGameVerifier.plugin.lua](roblox/plugin/GoalToGameVerifier.plugin.lua)
with [roblox/tools/evidence_collector.py](roblox/tools/evidence_collector.py).

The plugin:

- audits `Workspace/ThrixelAssets`;
- records actual imported MeshIds and `SurfaceAppearance` maps;
- verifies moving-part tags;
- captures six repeatable camera views through `StudioCaptureService`;
- sends capture bytes and audit JSON to `127.0.0.1`.

The collector:

- writes artifacts to disk;
- rejects path traversal and oversized payloads;
- hashes every artifact with SHA-256;
- writes an append-only JSONL ledger.

Run:

```bash
python skills/goal-to-game/engines/roblox/tools/evidence_collector.py \
  --output evidence/roblox-run
```

Then run the plugin's **Audit + Capture** action in Studio.

Finally:

```bash
python skills/goal-to-game/engines/roblox/tools/validate_evidence.py \
  evidence/roblox-run \
  --require-views front rear left right top gameplay
```

If the plugin cannot capture or localhost permission is denied, say exactly which evidence is
missing. Do not synthesize screenshots or manufacture a passing JSON file.

## Failure behavior

Hard-stop and explain the exact boundary when:

- Roblox Studio is absent;
- Thrixel MCP is unavailable or not authenticated;
- grouping cannot preserve a required moving part;
- imported MeshIds cannot be resolved/verified;
- moderation blocks visual verification;
- the evidence collector is not reachable;
- Studio screenshot permission is denied;
- performance is below the target after reasonable optimization.

A failed verification is useful evidence. Preserve it, fix the cause, and rerun.

## Bounty-quality example requirement

A complete engine submission must include two games of different genres made from this skill,
not hand-authored exceptions. At least one must exercise an independently moving Thrixel part.

For each game commit:

- editable source and place build;
- real Thrixel project/submission identifiers;
- evidence directory and SHA-256 ledger;
- six-view capture set;
- desktop and mobile-sized viewport performance record;
- public playable URL;
- gameplay video URL;
- exact Studio/Rojo/Python versions;
- concise build/failure notes.

Anything account-bound that has not actually happened remains marked `PENDING`; never use a
validator schema that lets a placeholder URL or a hand-written `true` masquerade as proof.

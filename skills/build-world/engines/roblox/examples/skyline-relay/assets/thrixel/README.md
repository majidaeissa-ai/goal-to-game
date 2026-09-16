# Skyline Relay — Thrixel assets

Project: `Skyline Relay`

Project ID: `b8ae85a7-2f87-458b-950b-3c6c90eeb2d7`

Generated with Thrixel MCP 1.1.8 on 2026-08-18. All triangle counts below are from
`thrixel_inspect_model`; preview images are Thrixel renders and are not presented as Roblox Studio
evidence. The checked-in hashes and machine-readable metadata are in [`manifest.json`](manifest.json).
Khronos glTF Validator reported zero errors and zero warnings for all four final GLBs.

| Roblox root name | Final file | Final grouped submission | Final triangles | Preserved moving groups |
|---|---|---|---:|---|
| `EmergencyPowerCellCarrier` | `emergency-power-cell-carrier.glb` | `2c5067d1-dc3d-4414-ba69-92cb3a3d9d84` | 6,564 | none |
| `CargoDrone` | `cargo-drone.glb` | `c7c8f35d-1441-43e0-b9d0-3e879787041a` | 19,258 effective | `Rotor_FL`, `Rotor_FR`, `Rotor_RL`, `Rotor_RR` |
| `FreightGantry` | `freight-gantry.glb` | `a2118763-c3f2-4a1c-9c8d-84bbb712293f` | 19,320 effective | `Trolley`, `Hoist` |
| `DeliveryTerminal` | `delivery-terminal.glb` | `cde1e5b3-a866-4f02-a344-bd6fa6ae0cd0` | 6,814 | none |

## Generation chain

- Emergency power-cell carrier: Sculptor `f3a4ae76-e368-45ae-b162-c617bfdf4af4` → focused texture
  pass `ffada5c5-568d-46f0-9ced-fd59885ca1ff` → group
  `2c5067d1-dc3d-4414-ba69-92cb3a3d9d84`.
- Cargo drone: Architect `1ad0df38-b718-4027-b514-8fcb17cd6f02` → focused body edit
  `5d383437-bc9d-4b73-8639-769517cc0336` → Detailer
  `f8b41aa5-5555-4f24-a9d4-3869f7e9fe0c` → texture
  `146abd19-0cf7-4ebc-af2b-32b29f34803b` → group
  `c7c8f35d-1441-43e0-b9d0-3e879787041a`.
- Freight gantry: Architect `f7c0e71a-a8f0-4c86-9150-c991eac0a487` → focused body edit
  `ec79997b-4e6b-4b5d-a59a-277ffce0c0f8` → Detailer
  `051c221d-4041-4d15-959e-b7f70ddcc4a3` → texture
  `beb3fd2b-7826-4ff8-907d-3f87244b7072` → group
  `a2118763-c3f2-4a1c-9c8d-84bbb712293f`.
- Delivery terminal: Sculptor `c76e5b9c-2284-4c76-ab1e-9b182ac46bb2` → focused texture pass
  `7b1c9fd8-4262-4425-87fa-04316f57c5fe` → group
  `cde1e5b3-a866-4f02-a344-bd6fa6ae0cd0`.

## Studio import boundary

Roblox's 3D Importer uses a local file browser and an account upload/ownership choice. Import all
four files with **Import Only as a Model**, place the resulting roots under
`Workspace.ThrixelAssets`, and use the exact Roblox root names from the table. After import, rerun
Play and verify the runtime creates four real assets and zero placeholders before collecting final
evidence or publishing.

For the two grouped moving assets, Thrixel's inspection output prints both the inclusive `Scene`
group count and the child-mesh count in its `total` line. The effective figures in the table are the
group operation's reported mesh totals and equal the sum of the final `Body` plus preserved moving
meshes; they avoid counting the inclusive group and its children twice.

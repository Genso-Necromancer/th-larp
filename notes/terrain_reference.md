# Terrain Reference

Quick lookup for terrain types currently used by the tile layers.

Values come from `character_data/pStats.gd`. Movement columns are terrain costs by movement type. Values omitted in code are listed here as `0`, because `PlayerData` fills missing terrain fields with zeroes at load time.

## Ground Layer

| Type | Example IDs | Grz | Def | Hit | Other | Foot | Fly | Ranger | Mount | Armor | Swim |
| --- | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `Flat` | `Tile` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `Ground` | `Grass`, `Stone` | +3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `River` | `River`, `Water` | +10 | 0 | 0 | 0 | 3 | 0 | 2 | 10 | 10 | 2 |
| `Water` | `Sea` | +20 | 0 | 0 | 0 | 20 | 0 | 20 | 20 | 20 | 3 |
| `Sanzu` | `Sanzu` | +20 | 0 | 0 | 0 | 20 | 0 | 20 | 20 | 20 | 3 |
| `HotSpring` | `HotSpring` | 0 | 0 | 0 | Comp regen +5, price -100 | 1 | 0 | 1 | 2 | 2 | 1 |
| `Rough` | `Brush` | +5 | +1 | 0 | 0 | 1 | 0 | 0.5 | 3 | 3 | 1 |
| `OpenRough` | `Snow`, `Sand` | -3 | 0 | 0 | 0 | 1 | 0 | 0.5 | 3 | 3 | 1 |
| `HellSand` | `HellSand` | +3 | +1 | 0 | 0 | 2 | 0 | 2 | 4 | 4 | 2 |

## Modifier Layer

| Type | Example IDs | Grz | Def | Hit | Mag | Other | Foot | Fly | Ranger | Mount | Armor | Swim |
| --- | --- | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `Fort` | `Fort` | +20 | +3 | +10 | 0 | 0 | 2 | 1 | 2 | 2 | 2 | 2 |
| `Woodland` | `Woodland` | +15 | +1 | 0 | 0 | 0 | 1 | 0 | 0.5 | 3 | 3 | 1 |
| `Hill` | `Hill` | +10 | 0 | +5 | 0 | 0 | 2 | 0 | 1 | 3 | 3 | 2 |
| `Mountain` | `Mountain` | +15 | +1 | +5 | 0 | 0 | 3 | 0 | 2 | 5 | 5 | 3 |
| `Shrine` | `Shrine` | +10 | 0 | 0 | +1 | Life regen +5, price -100 | 1 | 0 | 1 | 2 | 2 | 1 |
| `House` | `House` | +10 | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 2 | 2 | 1 |
| `Bridge` | `Bridge` | -5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `Shop` | `Shop` | +10 | 0 | 0 | 0 | Active special terrain; shop scene not implemented yet | 1 | 0 | 1 | 2 | 2 | 1 |

## Interactives And Walls

These appear in modifier/wall-related TileSets, but they are not ordinary stat terrain in the same way as the tables above.

| Type/ID | Notes |
| --- | --- |
| `Chest`, `OpenChest` | Chest interaction visuals. Chest contents are handled by map/chest logic. |
| `Door`, `OpenDoor`, `BrokenDoor` | Door visuals and interaction flow. Closed doors currently use wall-like blocking type data in the TileSet. |
| `BreakableWall`, `BrokenWall` | Breakable wall visuals. Blocking behavior depends on wall type and wall-edge data. |
| `Void` | Wall autotile filler. Treated as empty by map logic; should not provide stats, movement costs, wall blocking, or focus-viewer terrain info. |
| `Wall` | Blocks movement for Foot, Fly, Ranger, Mount, Armor, and Swim. Blocks targeting through the wall edge. |
| `WallShoot` | Blocks movement for Foot, Fly, Ranger, Mount, Armor, and Swim. Allows targeting through the wall edge. |
| `WallFly` | Blocks Foot, Ranger, Mount, Armor, and Swim. Fly can cross at cost 1. Allows targeting through the wall edge. |

## Notes

- Terrain `Type` is the mechanical key used by `PlayerData.terrainData`.
- Terrain `ID` is player-facing/flavor text and can share a Type with other IDs.
- Ground and modifier terrain bonuses stack when both layers define values.
- Passive special terrain restoration currently resolves between rounds.

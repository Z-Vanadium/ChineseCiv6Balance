# AGENTS.md — CCB (ChineseCiv6Balance)

Civ 6 balance mod forked from BBG (Better Balanced Game). Replaces BBG for Chinese community play.

## Project nature

No build system, no tests, no CI. The mod is defined declaratively through XML/SQL/Lua. The game engine loads files in order defined by `CCB.modinfo`. There is nothing to "run" — you only edit files and verify in-game.

## File organization

```
CCB.modinfo          ← Mod manifest: metadata, dependencies, file load order, conditional loading
sql/_utils.sql       ← Shared utility SQL (auto-generated Requirement/Modifier helpers)
sql/Base/            ← Base game changes (civs, buildings, policies, units, wonders, etc.)
sql/XP1/             ← Rise & Fall expansion changes
sql/XP2/             ← Gathering Storm expansion changes
sql/NFP/             ← New Frontier Pass DLC changes
sql/LP/              ← Leader Pass DLC changes
sql/DLC_*/           ← Individual DLC packs (Aztec, Vikings, Poland, Australia, etc.)
sql/CityStates/      ← City-state balance
sql/victories/       ← Victory condition reworks
sql/BBG_Expanded/    ← BBG Expanded addon: custom civs + leaders
sql/bbcc/            ← BBCC sub-mod (yield mode selection)
scripts/             ← Core Lua gameplay scripts (bbg_script.lua is main, ~4500 lines)
lua/BBG_Expanded/    ← Lua scripts for BBG Expanded civs/leaders
ui/replacements/     ← UI override scripts (world rankings, unit panel, trade panel)
lang/                ← Localization in 11 languages (XML, keyed by Tag + Language)
config/              ← Front-end config (game setup screen)
data/                ← Custom icons
MABC/                ← More Adjacency Bonus sub-module (self-contained)
dev_script/          ← Dev utilities (Python localization updater)
```

## Mod ID management (CRITICAL)

`CCB.modinfo` has **three** UUIDs, one active at a time. Before uploading to Steam Workshop, swap which UUID is uncommented:

```xml
<!-- Release ModID -->
<!-- <Mod id="8af4fe8e-5406-7d72-d9d6-a8f5d1b66e00" version="1420"> -->

<!-- BETA ModID -->
<!-- <Mod id="8af4fe8e-5406-7d72-d9d6-a8f5d1b66e05" version="1450"> -->

<!-- WIP ModID -->
<Mod id="8af4fe8e-5406-7d72-d9d6-a8f5d1b66e08" version="1300">
```

Also update `<Name>` accordingly. **WIP mod never gets uploaded.** Beta and Release use their own UUIDs.

## Version numbering

Version string `1.4.5` → `version="1450"` in modinfo (no decimal point, rightmost digit is patch * 10).

## File load order (CRITICAL)

Every `UpdateDatabase` block in modinfo has a `LoadOrder` integer. **Order matters.** Files are loaded in ascending LoadOrder within each action type:
- `-1` / `0–11599`: Utils and preload SQL (creates helper RequirementSets, Types, etc.)
- `11600–11699`: Main balance SQL files (Base → XP1 → XP2 → DLCs → NFP → LP)
- `20000`: Victory condition SQL, Settlers SQL
- `100000000`: BBG Expanded, text updates (must load last)

When adding a new SQL file:
1. Add it to `<Files>` section
2. Add an `UpdateDatabase` block in `<InGameActions>` with appropriate LoadOrder
3. Add any conditional `Criteria` if it depends on a DLC/expansion being present

## Conditional loading

Files guard on `Criteria` blocks in modinfo. Common criteria:
- `XP1`, `XP2`, `XP1_OR_XP2`, `XP1_AND_XP2` — expansion presence
- `DLC_Aztec`, `DLC_Vikings`, `DLC_Macedon_Persia`, etc. — DLC presence
- DLC-specific files must have both a `_utils.sql` preload AND the main SQL file with matching criteria

## SQL conventions

- All custom types/IDs prefix with `BBG_` (inherited from BBG) or `CCB_`
- Changes are done via `INSERT`/`UPDATE`/`DELETE` on game database tables (Districts, Buildings, Units, Modifiers, RequirementSets, etc.)
- Modifier chains: `Modifiers` → `ModifierArguments` → attach via `BuildingModifiers` / `UnitAbilityModifiers` / `TraitModifiers` etc.
- Requirement chains: `Requirements` → `RequirementArguments` → `RequirementSets` → `RequirementSetRequirements` → referenced in `SubjectRequirementSetId`
- Always `INSERT OR IGNORE` or `INSERT OR REPLACE` when targeting base-game rows
- Use `_utils.sql` pattern: auto-generate Requirement/Modifier rows from existing game data

## Lua conventions

- Core gameplay logic lives in `scripts/bbg_script.lua`
- Use `GameInfo.X[Type].Index` to get table indices for performance
- State passed through `ExposedMembers` and hook registrations
- Comment format: `-- 4.00` version markers, date-stamped changes `-- 2026/02/26`

## Localization workflow

1. Edit English text in `lang/english.xml` (or Chinese in `lang/chinese.xml`)
2. Use `dev_script/lang_update.py` to propagate a new Tag+Text to all 11 languages:
   ```
   python lang_update.py "LOC_TRAIT_..." "Your text here"
   ```
3. Non-English entries get `[COLOR_RED]TO_TRANSLATE:` prefix — translators fill these in later
4. Each language file has `<LocalizedText>` root with `<Replace>` entries keyed by `Tag` + `Language`
5. Use `[ICON_X]` markup for game icons and `[NEWLINE]` for line breaks

## BBG Expanded

Self-contained DLC-style addon loaded at LoadOrder 100000000 (last). Adds 9 custom leaders + 4 custom civs. Each has its own SQL file in `sql/BBG_Expanded/` with matching Lua in `lua/BBG_Expanded/`. Referenced via separate mod UUIDs.

## MABC sub-module

More Adjacency Bonus system by Ruivo. Self-contained adjacency bonus framework:
- `MABC/NEW_ADJACENCY_BONUS_BY_RUIVO_CORE_TABLE.sql` — schema
- `MABC/NEW_ADJACENCY_BONUS_BY_RUIVO_CORE_INSERT.sql` — data
- `MABC/NEW_ADJACENCY_BONUS_BY_RUIVO_GP.lua` — gameplay logic
- `MABC/RUIVO_STAT_MODULE_GP.lua` — UI stat module
- `MABC/标准写法.sql` — API reference for writing adjacency bonuses ("standard writing")

## Common pitfalls

- **Forgetting `<Files>` registration**: Every file must be listed in `<Files>` AND in its corresponding action block
- **Load order collisions**: Two blocks with the same LoadOrder — behavior undefined
- **Criteria mismatch**: SQL utils file loaded without criteria but main file has criteria → orphaned references
- **Missing inverse criteria**: `NoConflictingUIMod` uses `inverse="1"` — UI files conflict with other mods
- **Version number format**: `version="1450"` not `version="1.4.5"`
- **Language tags**: Chinese uses `zh_Hans_CN`, not `zh_CN`
- **File encoding**: All XML/lang files use UTF-8

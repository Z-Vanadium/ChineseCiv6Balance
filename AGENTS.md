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
lang/                ← Localization：**只维护 chinese / japanese / english 三个文件**（其余 8 个语言文件不再改，见「Localization workflow」）
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

**⚠ 只维护 3 种语言：`lang/chinese.xml`（zh_Hans_CN）/ `lang/japanese.xml`（ja_JP）/ `lang/english.xml`（en_US）**
（用户 2026-10-14 指示：**文本改动只改中 / 日 / 英，不要动其它 8 个语言文件** —— french / german / italian / korean / polish / portuguese / russian / spanish。
其它语言保持现状：历史译文不必回滚，但**新增或修改文案时不要扩到它们**。唯一例外见下第 6 条。）

1. 文案**手写**中/日/英三份（zh 优先）——这三个都不用 `[COLOR_RED]TO_TRANSLATE:` 前缀
2. 每个语言文件是 `<LocalizedText>` 根 + `<Replace Tag="..." Language="...">` 条目（Tag + Language 双键）
3. **新增键**：插在文件末尾 `</LocalizedText>` 之前即可；**改现有键**：用正则框出该条目、**只在块内**替换，块内计数必须是 1（同一句在整份文件里可能出现 2~10 次 → 见 `docs/Civ6开发排坑实录.md` §十三.E）
4. Use `[ICON_X]` markup for game icons and `[NEWLINE]` for line breaks
5. ⚠ `dev_script/lang_update.py` 是上游工具、**默认会同时写 8 个其它语言** —— 已按本规则改成只写 `japanese.xml`；若从上游/别处拿到旧版，不要直接跑
6. ⚠ **其余 8 个语言一律不管**（用户 2026-10-14 复核："以后的文本同步工作只考虑中日英"）：即便某处文案与数值/条件强绑定（尤里卡数字、造价、时代字样…），导致那 8 个语言显示**错数**，也**不改它们**；只在交付说明里提一句即可，不必专门询问。
7. ⚠ 读写语言文件一律用文件工具或 Python（`encoding='utf-8'` + `newline=''`）：`italian.xml`/`spanish.xml` 是 **LF**、其余 9 个是 **CRLF**；用 PowerShell 的 `Get-Content`/`WriteAllText` 会按 GBK 往返**永久损坏**文件（排坑实录 §十三.A）

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

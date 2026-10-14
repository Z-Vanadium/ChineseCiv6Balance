--==============================================================================================
-- CCB 强化堡垒 + 军事工程师/堡垒提前解锁（2026-09-20 用户需求）
--
--   ① 军事工程师 UNIT_MILITARY_ENGINEER：解锁科技 军事工程学 → **工程（TECH_ENGINEERING）**；
--      建筑前置 = **兵营 或 马厩（含其文明替代建筑：马其顿皇家学堂 / 蒙古蒙古包）**
--      （`Unit_BuildingPrereqs` 是**或列表**，多行即"有其一即可"；替代建筑必须显式列出，理由见下方注释）。
--      ⚠ 该表是**或列表**（先例：使徒 = 神庙/木条教堂/帕萨特 三选一）→ 写入前必须先清空该单位原有行，
--        否则会留下配套模组写的 BUILDING_LEU_ESTANCIA（阿根廷建筑），变成"庄园城以外造不了"。
--      本文件 LoadOrder **100300**，排在全部常规批次与配套模组（CCB 文明拓展 = 99100）之后，
--      确保这些改动不会被后加载的模组覆盖（详见排坑实录 §十五）。
--   ② 堡垒 IMPROVEMENT_FORT：解锁科技 军事工程学 → **工程**（弹道学尤里卡"造 2 座堡垒"不受影响）；
--      并新增 ④「弹道学后由强化堡垒取代」的授权链。
--
--   ③ 新改良「强化堡垒」CCB_IMPROVEMENT_REINFORCED_FORT：
--      · 由**弹道学（TECH_BALLISTICS）**解锁，**军事工程师**建造（消耗 1 次建造次数）
--      · **整行复制堡垒**（49 列，含 DefenseModifier=+4 / GrantFortification=2 / 可境外建造 / 可修复 /
--        可掠夺 / 可通行 / 图标沿用 ICON_IMPROVEMENT_FORT），并复制其 10 条可建造地形 + 1 条可建造特征
--      · **可在树林 / 雨林 / 人工林上直接修建**（不砍伐）：追加 3 条 `Improvement_ValidFeatures`
--        —— 该表语义 = "该地貌存在时也可建"（先例：伐木场建在森林/雨林上、钓鱼船建在礁石上），
--           所以树木**不会被移除**；与"先清除树林再建"是两回事
--      · **美术与堡垒完全一致**：图标沿用 `ICON_IMPROVEMENT_FORT`；模型 / 战略视图走新加的
--        `ArtDefs/Improvements.artdef`（条目整段照抄原版 IMPROVEMENT_FORT → 模型仍是原版 LM_FORT 地标；
--         引用的全是原版现成资产，**不需要 AssetEditor 重新烘焙**）
--      · 追加进 BBG 的「防御改良」分类 `IMPROVEMENT_IS_DEFENSIVE`
--        → 于是它同样吃到"进驻防御改良 +1 视野"（ABILITY_DEFENSIVE_IMPROVEMENT_BONUS_SIGHT）等
--          **全部以"防御改良"为条件的既有效果** —— 这就是"继承堡垒全部效果"的落点
--
--   ④ 「弹道学后强化堡垒**取代**堡垒」（2026-10-14 用户需求）：
--      引擎**没有**改良的"过时"机制（`Improvements` 无 ObsoleteTech 列，也没有能移除"可建清单"的修正器）
--      → 改用原版**城邦特色改良的授权链**实现"科技一到手就收回"：
--        原版先例（运行时库可查）：TraitModifiers(MINOR_CIV_GRANADA_TRAIT → MINOR_CIV_GRANADA_UNIQUE_INFLUENCE_BONUS)
--          └ MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER（SubjectRequirementSetId = PLAYER_IS_SUZERAIN）
--              └ MODIFIER_PLAYER_ADJUST_VALID_IMPROVEMENT（ImprovementType = IMPROVEMENT_ALCAZAR）
--        照此办理：堡垒默认不可建（`TraitType` 指向一个没人拥有的内部 trait，写法同 IMPROVEMENT_CITY_PARK），
--        再由**全局修正器**在"**已研究工程 且 尚未研究弹道学**"时把它授权回来
--        （"尚未"用 `Requirements.Inverse=1` 取反 —— 原版同款先例 `REQUIRES_PLAYER_HAS_NO_STEEL`）。
--        需求集每回合动态求值 → 研究完弹道学授权当即失效，堡垒从建造列表消失，只剩强化堡垒。
--        ⚠ 弹道学尤里卡"造 2 座堡垒"不受影响（研究弹道学**之前**堡垒一直可建）。
--
--   ⑤ 新效果「最高射击高度」：位于强化堡垒中的 **远程（CLASS_RANGED）/ 攻城（CLASS_SIEGE）** 单位
--      在计算**射击视线**时无视地形与地貌阻挡：
--        MODIFIER_PLAYER_UNIT_ADJUST_SEE_THROUGH_TERRAIN  （无视地形）
--      + MODIFIER_PLAYER_UNIT_ADJUST_SEE_THROUGH_FEATURES （无视地貌）
--      两者靠 `SubjectRequirementSetId = CCB_REQSET_UNIT_IS_IN_REINFORCED_FORT`（地块改良判定）开关，
--      能力本体经 TypeTags 常驻授予两个单位职业
--      —— 与工程内既有写法 **ABILITY_DEFENSIVE_IMPROVEMENT_BONUS_SIGHT**（能力常驻 + 效果靠地块需求）完全同构。
--      ⚠ 山脉：`TERRAIN_*_MOUNTAIN` 的 `SightThroughModifier=2`（丘陵=1、平原=0）且 `Impassable=1`
--        → 预期**仍然阻挡**射击视线；若实测发现山脉也被绕过，则引擎只认"地形"标志、无法用数据区分，
--          需回报后另想办法（见测试清单）。
--
--   ⑥ 军事工程师的**队形类别**（`FormationClass`）：新开 `FORMATION_CLASS_CCB_MILITARY_ENGINEER`
--      （用户 2026-10-14 需求：让它能与**观测气球 / 补给车队 / 无人机**同格）—— 机制与 UI 兜底见文件末 ⑥ 段。
--==============================================================================================

-- ── ① / ② 解锁科技调整 + 军事工程师建筑前置（兵营 或 马厩） ─────────────────────────
UPDATE Units SET PrereqTech = 'TECH_ENGINEERING' WHERE UnitType = 'UNIT_MILITARY_ENGINEER';
UPDATE Improvements SET PrereqTech = 'TECH_ENGINEERING' WHERE ImprovementType = 'IMPROVEMENT_FORT';

-- 2026-10-14 用户需求：研究「工程」后，**拥有兵营 或 马厩**的城市可生产军事工程师。
-- ⚠ `Unit_BuildingPrereqs` 是**或列表**（先例：使徒同时列 神庙/木条教堂/帕萨特 → 三选一），
--   所以多行 = "有其一即可"，不需要额外需求集。
-- ⚠ 但正因为它**是或列表**：只删军械库那一行会留下配套模组写入的 `BUILDING_LEU_ESTANCIA`
--   （阿根廷建筑，"庄园城以外造不了"，反而更糟）→ 必须先**整单位清空**再写入，
--   见 `docs\Civ6开发排坑实录.md` §十五。
-- ⚠⚠ **替代建筑（文明 UD）必须显式列出**：引擎**不会**把"替代兵营的建筑"当成"兵营"
--   —— 依据：上游 BBG 在 04/07/26 那批改动里，除了本体两行，还**专门**在
--   `sql\DLC_Macedon_Persia\Macedon.sql` 补了 `BUILDING_BASILIKOI_PAIDES`、
--   在 `sql\XP1\Mongolia.sql` 补了 `BUILDING_ORDU`；本工程 `sql\XP2\Buildings.sql`
--   （马厩给马 / 兵营给铁）也是同一个套路：用 `BuildingReplaces` 展开替代建筑。
--   → 这里同样用**查询展开**，一次覆盖"本体 + 全部替代建筑"（当前 = 兵营 / 马厩 /
--      马其顿「皇家学堂」/ 蒙古「蒙古包」），以后再冒出替代建筑（含配套模组）也自动跟上
--      （本文件 LoadOrder **100300**，晚于配套模组 99100 ⇒ 它们的 BuildingReplaces 已就位）。
--   ※ 祖鲁的「伊坎达」是**区域**（替代兵营区），不是兵营建筑 → 祖鲁照常造兵营/马厩，不受影响。
-- `NumSupported = -1` = 不限数量（与使徒 / 传教士 / 审判官等原版行一致）。
DELETE FROM Unit_BuildingPrereqs WHERE Unit = 'UNIT_MILITARY_ENGINEER';
INSERT OR IGNORE INTO Unit_BuildingPrereqs (Unit, PrereqBuilding, NumSupported)
SELECT 'UNIT_MILITARY_ENGINEER', b.BuildingType, -1
FROM Buildings b
LEFT JOIN BuildingReplaces br ON b.BuildingType = br.CivUniqueBuildingType
WHERE b.BuildingType IN ('BUILDING_BARRACKS', 'BUILDING_STABLE')
   OR br.ReplacesBuildingType IN ('BUILDING_BARRACKS', 'BUILDING_STABLE');

-- ── ③ 新改良：整行复制堡垒，仅改 类型 / 名称 / 描述 / 解锁科技 ────────────────────────
INSERT INTO Types (Type, Kind) VALUES
	('CCB_IMPROVEMENT_REINFORCED_FORT', 'KIND_IMPROVEMENT');

INSERT INTO Improvements (
	ImprovementType, Name, BarbarianCamp, PrereqTech, PrereqCivic, Buildable, Description, RemoveOnEntry,
	DispersalGold, PlunderType, PlunderAmount, Goody, TilesPerGoody, GoodyRange, Icon, TraitType, Housing,
	TilesRequired, SameAdjacentValid, RequiresRiver, EnforceTerrain, BuildInLine, CanBuildOutsideTerritory,
	BuildOnFrontier, AirSlots, DefenseModifier, GrantFortification, MinimumAppeal, Coast, YieldFromAppeal,
	WeaponSlots, ReligiousUnitHealRate, Appeal, OnePerCity, YieldFromAppealPercent, ValidAdjacentTerrainAmount,
	Domain, AdjacentSeaResource, RequiresAdjacentBonusOrLuxury, MovementChange, Workable, ImprovementOnRemove,
	GoodyNotify, NoAdjacentSpecialtyDistrict, RequiresAdjacentLuxury, AdjacentToLand, Removable, OnlyOpenBorders, Capturable)
SELECT
	'CCB_IMPROVEMENT_REINFORCED_FORT', 'LOC_CCB_IMPROVEMENT_REINFORCED_FORT_NAME', BarbarianCamp,
	'TECH_BALLISTICS', PrereqCivic, Buildable, 'LOC_CCB_IMPROVEMENT_REINFORCED_FORT_DESCRIPTION',
	RemoveOnEntry, DispersalGold, PlunderType, PlunderAmount, Goody, TilesPerGoody, GoodyRange, Icon,
	-- ⚠ TraitType 必须显式写 NULL：本文件 ④ 会把 IMPROVEMENT_FORT 的 TraitType 改成内部 trait 让它默认不可建，
	--   而本 INSERT 是"整行复制堡垒"——若沿用 TraitType 列，强化堡垒会连"不可建"一起继承（顺序陷阱）。
	NULL, Housing, TilesRequired, SameAdjacentValid, RequiresRiver, EnforceTerrain, BuildInLine,
	CanBuildOutsideTerritory, BuildOnFrontier, AirSlots, DefenseModifier, GrantFortification, MinimumAppeal,
	Coast, YieldFromAppeal, WeaponSlots, ReligiousUnitHealRate, Appeal, OnePerCity, YieldFromAppealPercent,
	ValidAdjacentTerrainAmount, Domain, AdjacentSeaResource, RequiresAdjacentBonusOrLuxury, MovementChange,
	Workable, ImprovementOnRemove, GoodyNotify, NoAdjacentSpecialtyDistrict, RequiresAdjacentLuxury,
	AdjacentToLand, Removable, OnlyOpenBorders, Capturable
FROM Improvements WHERE ImprovementType = 'IMPROVEMENT_FORT';

-- 可建造地形 / 特征 / 建造单位（照抄堡垒；ConsumesCharge=1 → 消耗 1 次建造次数）
INSERT INTO Improvement_ValidTerrains (ImprovementType, TerrainType, PrereqTech, PrereqCivic)
SELECT 'CCB_IMPROVEMENT_REINFORCED_FORT', TerrainType, PrereqTech, PrereqCivic
FROM Improvement_ValidTerrains WHERE ImprovementType = 'IMPROVEMENT_FORT';

INSERT INTO Improvement_ValidFeatures (ImprovementType, FeatureType, PrereqTech, PrereqCivic)
SELECT 'CCB_IMPROVEMENT_REINFORCED_FORT', FeatureType, PrereqTech, PrereqCivic
FROM Improvement_ValidFeatures WHERE ImprovementType = 'IMPROVEMENT_FORT';

INSERT INTO Improvement_ValidBuildUnits (ImprovementType, UnitType, ConsumesCharge, ValidRepairOnly)
SELECT 'CCB_IMPROVEMENT_REINFORCED_FORT', UnitType, ConsumesCharge, ValidRepairOnly
FROM Improvement_ValidBuildUnits WHERE ImprovementType = 'IMPROVEMENT_FORT';

-- 树林 / 雨林 / 人工林上也能修（不砍伐）—— 2026-10-14 用户需求：
--   `Improvement_ValidFeatures` 的语义是"**该地貌存在时也可以建**"（先例：伐木场在森林/雨林上、
--   圣地在森林上、钓鱼船在礁石上）→ 地貌**保留**，不会像"先清除地貌再建"那样砍掉树木。
--   人工林 = CCB 自建特征 `FEATURE_CCB_PLANTED_FOREST`（种植后由 scripts/ccb_planted_forest.lua 替换）。
INSERT INTO Improvement_ValidFeatures (ImprovementType, FeatureType, PrereqTech, PrereqCivic) VALUES
	('CCB_IMPROVEMENT_REINFORCED_FORT', 'FEATURE_FOREST', NULL, NULL),
	('CCB_IMPROVEMENT_REINFORCED_FORT', 'FEATURE_JUNGLE', NULL, NULL),
	('CCB_IMPROVEMENT_REINFORCED_FORT', 'FEATURE_CCB_PLANTED_FOREST', NULL, NULL);

-- ── ④ 弹道学后「强化堡垒」取代「堡垒」 ──────────────────────────────────────────────
-- 机制出处：原版城邦特色改良的授权链（见文件头 ④ 说明）。三步：
--   (a) 堡垒挂上一个"没人拥有"的内部 trait → 默认谁都不能建（同 IMPROVEMENT_CITY_PARK 的写法）
INSERT INTO Types (Type, Kind) VALUES
	('CCB_TRAIT_LEGACY_FORT', 'KIND_TRAIT');
INSERT INTO Traits (TraitType, Name, Description, InternalOnly) VALUES
	('CCB_TRAIT_LEGACY_FORT', NULL, NULL, 1);
UPDATE Improvements SET TraitType = 'CCB_TRAIT_LEGACY_FORT' WHERE ImprovementType = 'IMPROVEMENT_FORT';

--   (b) 需求："已研究工程" 且 "**尚未**研究弹道学"（后者用 Inverse=1 取反，原版同款先例 REQUIRES_PLAYER_HAS_NO_STEEL）
INSERT INTO Requirements (RequirementId, RequirementType, Inverse) VALUES
	('CCB_REQ_PLAYER_HAS_ENGINEERING', 'REQUIREMENT_PLAYER_HAS_TECHNOLOGY', 0),
	('CCB_REQ_PLAYER_LACKS_BALLISTICS', 'REQUIREMENT_PLAYER_HAS_TECHNOLOGY', 1);
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('CCB_REQ_PLAYER_HAS_ENGINEERING', 'TechnologyType', 'TECH_ENGINEERING'),
	('CCB_REQ_PLAYER_LACKS_BALLISTICS', 'TechnologyType', 'TECH_BALLISTICS');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('CCB_REQSET_FORT_VALID_BEFORE_BALLISTICS', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('CCB_REQSET_FORT_VALID_BEFORE_BALLISTICS', 'CCB_REQ_PLAYER_HAS_ENGINEERING'),
	('CCB_REQSET_FORT_VALID_BEFORE_BALLISTICS', 'CCB_REQ_PLAYER_LACKS_BALLISTICS');

--   (c) 授权修正器（子）：让玩家"可建堡垒"；父修正器：对**所有玩家**附加，条件 = 上面的需求集
--       （`MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER` 的 Subject 需求集是**逐玩家**求值的，
--         原版同款：GOV_BUILDING_* → MODIFIER_ALL_PLAYERS_ADJUST_GOVERNOR_POINTS + PLAYER_HAS_GOV_BUILDING_*）
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_FORT_VALID_BEFORE_BALLISTICS', 'MODIFIER_PLAYER_ADJUST_VALID_IMPROVEMENT');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_FORT_VALID_BEFORE_BALLISTICS', 'ImprovementType', 'IMPROVEMENT_FORT');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('CCB_FORT_VALID_PARENT', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'CCB_REQSET_FORT_VALID_BEFORE_BALLISTICS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_FORT_VALID_PARENT', 'ModifierId', 'CCB_FORT_VALID_BEFORE_BALLISTICS');

INSERT INTO GameModifiers (ModifierId) VALUES
	('CCB_FORT_VALID_PARENT');

-- ── ⑤-a 「地块是强化堡垒」需求（同时用于把新改良并入"防御改良"分类） ──────────────────
INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('CCB_REQ_PLOT_HAS_REINFORCED_FORT', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('CCB_REQ_PLOT_HAS_REINFORCED_FORT', 'ImprovementType', 'CCB_IMPROVEMENT_REINFORCED_FORT');

-- 并入 BBG 的"防御改良"集合 → 与堡垒同待遇（+1 视野等一切以该集合为条件的效果）
INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('IMPROVEMENT_IS_DEFENSIVE', 'CCB_REQ_PLOT_HAS_REINFORCED_FORT');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('CCB_REQSET_UNIT_IS_IN_REINFORCED_FORT', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('CCB_REQSET_UNIT_IS_IN_REINFORCED_FORT', 'CCB_REQ_PLOT_HAS_REINFORCED_FORT');

-- ── ⑤-b 能力：最高射击高度（远程 / 攻城 常驻持有，效果仅在该地块生效） ────────────────
INSERT INTO Types (Type, Kind) VALUES
	('ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND', 'KIND_ABILITY');
INSERT INTO TypeTags (Type, Tag) VALUES
	('ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND', 'CLASS_RANGED'),
	('ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND', 'CLASS_SIEGE');
INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive) VALUES
	('ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND',
	 'LOC_ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND_NAME',
	 'LOC_ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND_DESC', 0);
INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
	('ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND', 'CCB_FORT_HIGH_GROUND_TERRAIN'),
	('ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND', 'CCB_FORT_HIGH_GROUND_FEATURES');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('CCB_FORT_HIGH_GROUND_TERRAIN',  'MODIFIER_PLAYER_UNIT_ADJUST_SEE_THROUGH_TERRAIN',  'CCB_REQSET_UNIT_IS_IN_REINFORCED_FORT'),
	('CCB_FORT_HIGH_GROUND_FEATURES', 'MODIFIER_PLAYER_UNIT_ADJUST_SEE_THROUGH_FEATURES', 'CCB_REQSET_UNIT_IS_IN_REINFORCED_FORT');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_FORT_HIGH_GROUND_TERRAIN', 'CanSee', 1),
	('CCB_FORT_HIGH_GROUND_FEATURES', 'CanSee', 1);
INSERT INTO ModifierStrings (ModifierId, Context, Text) VALUES
	('CCB_FORT_HIGH_GROUND_TERRAIN', 'Preview', 'LOC_ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND_DESC'),
	('CCB_FORT_HIGH_GROUND_FEATURES', 'Preview', 'LOC_ABILITY_CCB_REINFORCED_FORT_HIGH_GROUND_DESC');

-- ── ⑥ 军事工程师的队形类别：新开一类，让它能与支援单位同格（2026-10-14 用户需求） ──────────
-- 需求：军事工程师要能与**观测气球 / 补给车队 / 无人机**在同一单元格。
-- 机制：Civ6 的堆叠规则 = **一个格子每种 `FormationClass` 只能有一个单位**
--   （所以「战斗单位 + 支援 + 平民」可以三层同格；原版百科「编队」页也是这么写的）。
--   军事工程师与气球 / 补给车队 / 无人机**同为 `FORMATION_CLASS_SUPPORT`** → 天然互斥，怎么摆都挤不到一起。
--   → 给军事工程师**单独开一个队形类别**：与支援类不再冲突，同时与战斗单位、平民**仍然**能同格（类别各不相同）。
-- ⚠ 改的是 **`FormationClass`**，**不是** `PromotionClass`：
--   晋升类别与堆叠毫无关系（例证：侦察兵与勇士同为 `FORMATION_CLASS_LAND_COMBAT`、晋升类别不同 —— 照样不能同格）。
--   军事工程师的 `PromotionClass` 保持 `PROMOTION_CLASS_SUPPORT` 不变
--   → Reyna「承包商」等"按支援类生成"的加成照旧生效（见下方 LoadOrder 说明）。
-- ⚠⚠ 原版 UI 对 FormationClass 是**硬编码 5 类**，自定义类别会掉进 `else`／取到 nil，必须同时补 UI 兜底
--   （本 MOD 已加两个，见 `ui/replacements/unitflagmanager_ccb.lua` / `mapsearchpanel_ccb.lua`）：
--     · `UnitFlagManager.lua` 的旗帜样式判断**没有 else** → 未知类别会**完全不出旗帜**（单位等于无法选中）→ 必须兜底；
--     · `MapSearchPanel.lua` 会用 `FormationClassNameMap[类别]` 取名字，nil 时代码执行 `t[nil]=true` → **Lua 报错** → pcall 兜底；
--     · `ProductionPanel.lua` 的单位图标、`MapSearchPanel` 的类别名列表：只是显示差异，本次不处理。
-- ⚠ 本文件 LoadOrder **100300** 晚于所有"按 FormationClass 生成"的 BBG/CCB 脚本
--   （例：Reyna「承包商」按 `WHERE FormationClass='FORMATION_CLASS_SUPPORT'` 逐单位生成金币折扣）
--   → 这些生成结果仍把军事工程师算作支援 ✔ 行为不变。
--   **不要**把这个改动提到那些脚本之前，否则那些加成会静默丢失。
INSERT INTO Types (Type, Kind) VALUES
	('FORMATION_CLASS_CCB_MILITARY_ENGINEER', 'KIND_FORMATION_CLASS');
INSERT INTO UnitFormationClasses (FormationClassType, Name) VALUES
	('FORMATION_CLASS_CCB_MILITARY_ENGINEER', 'LOC_FORMATION_CLASS_CCB_MILITARY_ENGINEER_NAME');
UPDATE Units SET FormationClass = 'FORMATION_CLASS_CCB_MILITARY_ENGINEER' WHERE UnitType = 'UNIT_MILITARY_ENGINEER';

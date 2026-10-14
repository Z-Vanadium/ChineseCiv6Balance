--==============================================================================================
-- CCB 强化堡垒 + 军事工程师/堡垒提前解锁（2026-09-20 用户需求）
--
--   ① 军事工程师 UNIT_MILITARY_ENGINEER：解锁科技 军事工程学 → **工程（TECH_ENGINEERING）**；
--      并**删除其全部建筑前置**（用户 2026-09-20 拍板"删掉该前置"）——
--      ⚠ 军械库 BUILDING_ARMORY 本身由军事工程学解锁，不删则本项等于空操作（单位仍要等中世纪）；
--      ⚠ 且该表是**或列表**，配套模组还写了一条 BUILDING_LEU_ESTANCIA（阿根廷建筑）→ 必须一并删除
--        （详见下方 ① 处注释）。本文件 LoadOrder **100300**，排在全部常规批次与配套模组之后，
--        确保这两项改动不会被后加载的模组覆盖。
--   ② 堡垒 IMPROVEMENT_FORT：解锁科技 军事工程学 → **工程**（弹道学尤里卡"造 2 座堡垒"不受影响）。
--
--   ③ 新改良「强化堡垒」CCB_IMPROVEMENT_REINFORCED_FORT：
--      · 由**弹道学（TECH_BALLISTICS）**解锁，**军事工程师**建造（消耗 1 次建造次数）
--      · **整行复制堡垒**（49 列，含 DefenseModifier=+4 / GrantFortification=2 / 可境外建造 / 可修复 /
--        可掠夺 / 可通行 / 图标沿用 ICON_IMPROVEMENT_FORT），并复制其 10 条可建造地形 + 1 条可建造特征
--      · 追加进 BBG 的「防御改良」分类 `IMPROVEMENT_IS_DEFENSIVE`
--        → 于是它同样吃到"进驻防御改良 +1 视野"（ABILITY_DEFENSIVE_IMPROVEMENT_BONUS_SIGHT）等
--          **全部以"防御改良"为条件的既有效果** —— 这就是"继承堡垒全部效果"的落点
--
--   ④ 新效果「最高射击高度」：位于强化堡垒中的 **远程（CLASS_RANGED）/ 攻城（CLASS_SIEGE）** 单位
--      在计算**射击视线**时无视地形与地貌阻挡：
--        MODIFIER_PLAYER_UNIT_ADJUST_SEE_THROUGH_TERRAIN  （无视地形）
--      + MODIFIER_PLAYER_UNIT_ADJUST_SEE_THROUGH_FEATURES （无视地貌）
--      两者靠 `SubjectRequirementSetId = CCB_REQSET_UNIT_IS_IN_REINFORCED_FORT`（地块改良判定）开关，
--      能力本体经 TypeTags 常驻授予两个单位职业
--      —— 与工程内既有写法 **ABILITY_DEFENSIVE_IMPROVEMENT_BONUS_SIGHT**（能力常驻 + 效果靠地块需求）完全同构。
--      ⚠ 山脉：`TERRAIN_*_MOUNTAIN` 的 `SightThroughModifier=2`（丘陵=1、平原=0）且 `Impassable=1`
--        → 预期**仍然阻挡**射击视线；若实测发现山脉也被绕过，则引擎只认"地形"标志、无法用数据区分，
--          需回报后另想办法（见测试清单）。
--==============================================================================================

-- ── ① / ② 解锁科技调整 + 删除军械库前置 ─────────────────────────────────────────────
UPDATE Units SET PrereqTech = 'TECH_ENGINEERING' WHERE UnitType = 'UNIT_MILITARY_ENGINEER';
UPDATE Improvements SET PrereqTech = 'TECH_ENGINEERING' WHERE ImprovementType = 'IMPROVEMENT_FORT';

-- ⚠ `Unit_BuildingPrereqs` 是**或列表**（先例：使徒同时列 神庙/木条教堂/帕萨特 → 三选一），
--   所以"只删军械库那一行"会留下配套模组写入的 `BUILDING_LEU_ESTANCIA`（阿根廷建筑）
--   → 变成"只有庄园城能造军事工程师"，反而更糟（实测库内该单位当时正是这两行）。
--   因此这里**删除该单位的全部建筑前置** → 军事工程师与军械库/庄园彻底解耦，研究完「工程」后任意城市可造。
DELETE FROM Unit_BuildingPrereqs WHERE Unit = 'UNIT_MILITARY_ENGINEER';

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
	TraitType, Housing, TilesRequired, SameAdjacentValid, RequiresRiver, EnforceTerrain, BuildInLine,
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

-- ── ④-a 「地块是强化堡垒」需求（同时用于把新改良并入"防御改良"分类） ──────────────────
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

-- ── ④-b 能力：最高射击高度（远程 / 攻城 常驻持有，效果仅在该地块生效） ────────────────
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

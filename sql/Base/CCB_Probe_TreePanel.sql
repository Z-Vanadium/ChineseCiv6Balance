-- ===========================================================================
-- [探针·临时] 新科技树面板 · 数据层（第一轮 + 第二轮）
--
-- 路线 A（用户 2026-10-10 决定）：**不新增任何科技/市政行** —— 节点状态存 Lua，
-- 效果在解锁时运行时挂载 → 原版科技树/市政树/研究下拉/文明百科零污染。
--   证据：科技树节点来自原生 UITree.GetAvailableTechs()（TechTree.lua:1387）；
--         Technologies_XP2.HiddenUntilPrereqComplete 只在"随机科技树"模式生效
--         （原版 TECH_CYBERNETICS 等带此标记但在常规局可见）。
--
-- 第一轮矩阵实测结果（用户 2026-10-10）：
--   ✅ 生效：M1-M9（帝国/城市产出、宜居、住房、发展、每人口）、**M11 单位+1移动**、**M12 单位+1射程**
--   ❌ 不生效：M10 单位+5战斗力、M13 授予能力
--   → 结论：帝国/城市类 + 单位"移动/射程"可运行时挂载；**战斗力与能力只能走"能力"通道**
--     （与寡头那次失败一致：MODIFIER_PLAYER_UNITS_GRANT_ABILITY 不生效）
--
-- 第二轮（本文件 R2-R9）目的：为"战斗力"找一条**零污染**的通道，并补齐其它类别：
--   R2/R3  单位战斗力其它通道（防御时 / 本国领土）
--   R4/R5  单位治疗 / 单位生产力
--   R6/R7  区域伟人点 / 每区域产出
--   R8/R9  ★"授予 Trait"通道（MODIFIER_ALL_PLAYERS_GRANT_TRAIT）——
--          Trait 不出现在任何 UI；若可运行时授予，就能用 TraitModifiers 承载**任意**效果
--          （R9 = 用 Trait 承载"授予战斗能力"，即"隐形旗标 + 战斗力"的完整链路）
-- 全部以 CCB_PROBE_ 前缀命名，验证完整段删除。
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- ① 节点效果：所有城市 +1 生产力
--    类型 = MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE（已证可运行时挂载）
--    ⚠ 原设计"每个种植园 +1 锤"需按城折算（引擎只有 Improvement_BonusYieldChanges
--      能改改良产出，而它必须挂科技/市政，与"零污染"冲突），待后续实现。
-- ---------------------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_NODE_EFFECT', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_NODE_EFFECT', 'YieldType', 'YIELD_PRODUCTION'),
	('CCB_PROBE_NODE_EFFECT', 'Amount', 1);

-- ---------------------------------------------------------------------------
-- ② 第一轮矩阵（M1-M13）—— 结论见文件头，保留以便换档复验
-- ---------------------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_M1',  'MODIFIER_PLAYER_ADJUST_YIELD_CHANGE'),
	('CCB_PROBE_M2',  'MODIFIER_PLAYER_ADJUST_YIELD_CHANGE'),
	('CCB_PROBE_M3',  'MODIFIER_PLAYER_ADJUST_YIELD_CHANGE'),
	('CCB_PROBE_M4',  'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE'),
	('CCB_PROBE_M5',  'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER'),
	('CCB_PROBE_M6',  'MODIFIER_PLAYER_CITIES_ADJUST_TRAIT_AMENITY'),
	('CCB_PROBE_M7',  'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING'),
	('CCB_PROBE_M8',  'MODIFIER_PLAYER_CITIES_ADJUST_CITY_GROWTH'),
	('CCB_PROBE_M9',  'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_PER_POPULATION'),
	('CCB_PROBE_M10', 'MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH'),
	('CCB_PROBE_M11', 'MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT'),
	('CCB_PROBE_M12', 'MODIFIER_PLAYER_UNITS_ADJUST_ATTACK_RANGE'),
	('CCB_PROBE_M13', 'MODIFIER_PLAYER_UNITS_GRANT_ABILITY');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_M1', 'YieldType', 'YIELD_SCIENCE'), ('CCB_PROBE_M1', 'Amount', 1),
	('CCB_PROBE_M2', 'YieldType', 'YIELD_CULTURE'), ('CCB_PROBE_M2', 'Amount', 1),
	('CCB_PROBE_M3', 'YieldType', 'YIELD_GOLD'),    ('CCB_PROBE_M3', 'Amount', 2),
	('CCB_PROBE_M4', 'YieldType', 'YIELD_PRODUCTION'), ('CCB_PROBE_M4', 'Amount', 2),
	('CCB_PROBE_M5', 'YieldType', 'YIELD_PRODUCTION'), ('CCB_PROBE_M5', 'Amount', 10),
	('CCB_PROBE_M6', 'Amount', 1),
	('CCB_PROBE_M7', 'Amount', 1),
	('CCB_PROBE_M8', 'Amount', 15),
	('CCB_PROBE_M9', 'YieldType', 'YIELD_SCIENCE'), ('CCB_PROBE_M9', 'Amount', 1),
	('CCB_PROBE_M10', 'Amount', 5),
	('CCB_PROBE_M11', 'Amount', 1),
	('CCB_PROBE_M12', 'Amount', 1),
	('CCB_PROBE_M13', 'AbilityType', 'ABILITY_OLIGARCHY_MELEE_BUFF');

-- ---------------------------------------------------------------------------
-- ③ 第二轮：单位战斗力其它通道 / 单位治疗 / 单位生产力 / 区域类
-- ---------------------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_R2', 'MODIFIER_PLAYER_UNITS_ADJUST_STRENGTH_WHEN_DEFENDING'),
	('CCB_PROBE_R3', 'MODIFIER_PLAYER_UNITS_ADJUST_FRIENDLY_TERRITORY_COMBAT'),
	('CCB_PROBE_R4', 'MODIFIER_PLAYER_UNITS_ADJUST_HEAL_PER_TURN'),
	('CCB_PROBE_R5', 'MODIFIER_PLAYER_UNITS_ADJUST_UNIT_PRODUCTION'),
	('CCB_PROBE_R6', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_GREAT_PERSON_POINTS'),
	('CCB_PROBE_R7', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_PER_DISTRICT');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	-- R2 防御时 +5 战斗力（原版零用例 → 参数名 Amount 为推断值）
	('CCB_PROBE_R2', 'Amount', 5),
	-- R3 本国领土内 +5 战斗力（同上）
	('CCB_PROBE_R3', 'Amount', 5),
	-- R4 每回合 +10 治疗（原版用例带 Amount + Type）
	('CCB_PROBE_R4', 'Amount', 10), ('CCB_PROBE_R4', 'Type', 'ALL'),
	-- R5 建造者 +100% 生产力（原版用例带 Amount + UnitType）
	('CCB_PROBE_R5', 'Amount', 100), ('CCB_PROBE_R5', 'UnitType', 'UNIT_BUILDER'),
	-- R6 所有区域 +1 大工程师点（原版用例带 Amount + GreatPersonClassType）
	('CCB_PROBE_R6', 'Amount', 1), ('CCB_PROBE_R6', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_ENGINEER'),
	-- R7 每区域 +1 文化
	('CCB_PROBE_R7', 'Amount', 1), ('CCB_PROBE_R7', 'YieldType', 'YIELD_CULTURE');

-- ---------------------------------------------------------------------------
-- ④ 第二轮核心：★"授予 Trait"通道（Trait 不出现在任何 UI）
--    R8：Trait A 的 TraitModifiers = 帝国 +1 科技 → 验证"授予 Trait"本身是否生效
--    R9：Trait B 的 TraitModifiers = 授予战斗能力（+5 战斗力）→ 验证"隐形旗标 + 战斗力"
--    ⚠ MODIFIER_ALL_PLAYERS_GRANT_TRAIT 原版零用例：参数名按 REQUIREMENT_*_TRAIT 的
--      TraitType 命名推断，能否生效正是本轮要测的
-- ---------------------------------------------------------------------------
INSERT INTO Types (Type, Kind) VALUES
	('TRAIT_CCB_PROBE_A', 'KIND_TRAIT'),
	('TRAIT_CCB_PROBE_B', 'KIND_TRAIT'),
	('ABILITY_CCB_PROBE_COMBAT', 'KIND_ABILITY');

INSERT INTO Traits (TraitType, Name, Description, InternalOnly) VALUES
	('TRAIT_CCB_PROBE_A', 'LOC_CCB_PROBE_TRAIT_A_NAME', 'LOC_CCB_PROBE_TRAIT_A_DESC', 1),
	('TRAIT_CCB_PROBE_B', 'LOC_CCB_PROBE_TRAIT_B_NAME', 'LOC_CCB_PROBE_TRAIT_B_DESC', 1);

-- Trait A：帝国 +3 科技（取 +3 便于在读数里一眼判定"授予 Trait"是否生效）
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_TRAIT_A_SCI', 'MODIFIER_PLAYER_ADJUST_YIELD_CHANGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_TRAIT_A_SCI', 'YieldType', 'YIELD_SCIENCE'),
	('CCB_PROBE_TRAIT_A_SCI', 'Amount', 3);
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CCB_PROBE_A', 'CCB_PROBE_TRAIT_A_SCI');

-- Trait B：授予"全战斗单位 +5 战斗力"能力（写法同寡头传承能力：Inactive=1 + CLASS_ALL_COMBAT_UNITS）
INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive, Permanent) VALUES
	('ABILITY_CCB_PROBE_COMBAT', 'LOC_CCB_PROBE_ABILITY_COMBAT_NAME', 'LOC_CCB_PROBE_ABILITY_COMBAT_DESC', 1, 0);
INSERT INTO TypeTags (Type, Tag) VALUES
	('ABILITY_CCB_PROBE_COMBAT', 'CLASS_ALL_COMBAT_UNITS');
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_ABILITY_COMBAT_CS', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_ABILITY_COMBAT_CS', 'Amount', 5);
INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
	('ABILITY_CCB_PROBE_COMBAT', 'CCB_PROBE_ABILITY_COMBAT_CS');
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_TRAIT_B_GRANT_ABILITY', 'MODIFIER_PLAYER_UNITS_GRANT_ABILITY');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_TRAIT_B_GRANT_ABILITY', 'AbilityType', 'ABILITY_CCB_PROBE_COMBAT');
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CCB_PROBE_B', 'CCB_PROBE_TRAIT_B_GRANT_ABILITY');

-- 授予 Trait 的修正器（R8/R9）
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_R8', 'MODIFIER_ALL_PLAYERS_GRANT_TRAIT'),
	('CCB_PROBE_R9', 'MODIFIER_ALL_PLAYERS_GRANT_TRAIT');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_R8', 'TraitType', 'TRAIT_CCB_PROBE_A'),
	('CCB_PROBE_R9', 'TraitType', 'TRAIT_CCB_PROBE_B');

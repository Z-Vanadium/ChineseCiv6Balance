-- ===========================================================================
-- [探针·临时 2026-09-22 / 2026-10-10 改版] 新科技树面板 · 数据层
--
-- 改版要点（用户 2026-10-10 决定走"路线 A"）：
--   ❌ 删除：新增科技旗标（Types/Technologies/Technologies_XP2/TechnologyPrereqs）
--            + Improvement_BonusYieldChanges 门控行
--      原因：数据层无法让新增科技从**原版科技树**消失（节点列表来自原生
--            UITree.GetAvailableTechs()，见 TechTree.lua:1387；Technologies_XP2.
--            HiddenUntilPrereqComplete 只在"随机科技树"游戏模式下起作用 —— 原版
--            TECH_CYBERNETICS 等带此标记但在常规局里照样可见）。
--   ✅ 改为：节点状态只存在 Lua（Player Property），效果在解锁时**运行时挂载**
--            → 原版科技树 / 市政树 / 研究下拉 / 文明百科 全部零污染。
--
-- 本文件只做两件事：
--   ① 定义"节点效果"修饰器（解锁后由 Lua 挂载）
--   ② 定义"效果矩阵"13 个候选修饰器（探针面板逐一点击，用日志+游戏内观察判定
--      哪些 modifier 类型支持运行时 AttachModifierByID）
-- 全部以 CCB_PROBE_ 前缀命名，验证完整段删除。
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- ① 节点效果：所有城市 +1 生产力
--    类型 = MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE（工程已证可运行时挂载：
--    独裁传承卡的城市粮食/生产抵消 CCB_AUT_OFFSET_* 用的就是它）
--    ⚠ 原设计"每个种植园 +1 锤"需要按城折算（引擎只有 Improvement_BonusYieldChanges
--      能改改良产出，而它必须挂科技/市政 —— 与"零污染"冲突），待矩阵结果后实现。
-- ---------------------------------------------------------------------------
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_PROBE_NODE_EFFECT', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_PROBE_NODE_EFFECT', 'YieldType', 'YIELD_PRODUCTION'),
	('CCB_PROBE_NODE_EFFECT', 'Amount', 1);

-- ---------------------------------------------------------------------------
-- ② 效果矩阵（13 类候选，逐一点击验证"运行时挂载是否生效"）
--    M1-M3  帝国级平面产出（MODIFIER_PLAYER_ADJUST_YIELD_CHANGE，已证可用）
--    M4-M9  城市级（平面/百分比/宜居/住房/发展/每人口）
--    M10-M12 单位级（战斗力/移动/射程 —— 关键未知项）
--    M13    授予能力（已知反例，保留作对照）
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
	-- M1 帝国 +1 科技
	('CCB_PROBE_M1', 'YieldType', 'YIELD_SCIENCE'), ('CCB_PROBE_M1', 'Amount', 1),
	-- M2 帝国 +1 文化
	('CCB_PROBE_M2', 'YieldType', 'YIELD_CULTURE'), ('CCB_PROBE_M2', 'Amount', 1),
	-- M3 帝国 +2 金币
	('CCB_PROBE_M3', 'YieldType', 'YIELD_GOLD'), ('CCB_PROBE_M3', 'Amount', 2),
	-- M4 全城 +2 生产（平面）
	('CCB_PROBE_M4', 'YieldType', 'YIELD_PRODUCTION'), ('CCB_PROBE_M4', 'Amount', 2),
	-- M5 全城 +10% 生产（百分比）
	('CCB_PROBE_M5', 'YieldType', 'YIELD_PRODUCTION'), ('CCB_PROBE_M5', 'Amount', 10),
	-- M6 全城 +1 宜居
	('CCB_PROBE_M6', 'Amount', 1),
	-- M7 全城 +1 住房
	('CCB_PROBE_M7', 'Amount', 1),
	-- M8 全城 +15% 发展速度
	('CCB_PROBE_M8', 'Amount', 15),
	-- M9 每人口 +1 科技
	('CCB_PROBE_M9', 'YieldType', 'YIELD_SCIENCE'), ('CCB_PROBE_M9', 'Amount', 1),
	-- M10 所有单位 +5 战斗力
	('CCB_PROBE_M10', 'Amount', 5),
	-- M11 所有单位 +1 移动力
	('CCB_PROBE_M11', 'Amount', 1),
	-- M12 所有单位 +1 攻击距离
	('CCB_PROBE_M12', 'Amount', 1),
	-- M13 授予能力（对照：预期不生效）
	('CCB_PROBE_M13', 'AbilityType', 'ABILITY_OLIGARCHY_MELEE_BUFF');

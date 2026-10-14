--==============================================================================================
-- CCB 蒸汽动力 · 海军单位移动力（2026-09-20 用户需求）
--   需求：科技「蒸汽动力」原本只给**水运单位（上船后的陆军）+2 移动力**，
--         现要求**同时给海军单位 +2 移动力**。
--
--   引擎：原版把这两种"在海上跑得更快"拆成**两套独立效果**（查证见 docs/Civ6开发排坑实录.md §十三）：
--     · MODIFIER_PLAYER_ADJUST_EMBARKED_MOVEMENT → EFFECT_ADJUST_PLAYER_EMBARKED_UNIT_MOVEMENT
--         **仅"已上船(embarked)"单位**；原版 STEAM_POWER_ADJUST_EMBARKED_MOVEMENT 用的就是它（Amount=2）
--         → **本文件保持不动**（水运 +2 原样保留）
--     · MODIFIER_PLAYER_UNITS_ADJUST_SEA_MOVEMENT → EFFECT_ADJUST_UNIT_SEA_MOVEMENT
--         **仅 DOMAIN_SEA 海军单位**；← **本文件新增的这一条**
--
--   写法照抄原版先例（逐字段对齐）：
--     · 科技「数学」MATHEMATICS_ADJUST_SEA_MOVEMENT —— 同为技术挂载的玩家级 SEA 修饰器（Amount=1）
--     · 大灯塔 GREAT_LIGHTHOUSE_SEA_MOVEMENT —— 经 GRANT_ABILITY 授予的 SEA 修饰器
--   大灯塔本身就是"SEA +1 与 EMBARKED +1 两条并存"→ 本次让蒸汽动力复刻这种"海军与水运都吃"的形态。
--
--   结果：研究完成蒸汽动力后 —— 水运单位 +2（原有）、海军单位 +2（新增）；两者互不重叠（各管各的单位）。
--   只加不改：不触碰任何原版/BBG 行，故与「数学 +1 海军」「大灯塔 +1 海军」等来源为**加算**关系。
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_STEAM_POWER_ADJUST_SEA_MOVEMENT', 'MODIFIER_PLAYER_UNITS_ADJUST_SEA_MOVEMENT');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_STEAM_POWER_ADJUST_SEA_MOVEMENT', 'Amount', 2);
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES
	('TECH_STEAM_POWER', 'CCB_STEAM_POWER_ADJUST_SEA_MOVEMENT');

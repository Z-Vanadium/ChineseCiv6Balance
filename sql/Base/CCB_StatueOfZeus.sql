--==============================================================================================
-- CCB 宙斯像 · 抗骑兵生产加成限定为「现代之前」（2026-09-20 用户需求）
--   需求：词条由「生产抗骑兵单位时 +35% 生产力」改为「生产**现代以前的**抗骑兵单位时 +35% 生产力」，
--         其中"现代以前" = 远古 / 古典 / 中世纪 / 文艺复兴 / 工业 五个时代。
--
--   引擎：原版宙斯像用的是 MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION，
--         该类型**自带 EraType 参数**（一次只能填一个时代）：
--           STAUEZEUS_ANTI_CAVALRY_PRODUCTION（注意原版 ID 拼写为 STAUEZEUS）
--             Amount=35, UnitPromotionClass=PROMOTION_CLASS_ANTI_CAVALRY, EraType=**NO_ERA**（= 不限时代）
--         原版政策线正是"一个时代一条"的写法，可作逐字段参照：
--           Agoge           = ERA_ANCIENT / ERA_CLASSICAL
--           Feudal Contract = ERA_MEDIEVAL / ERA_RENAISSANCE
--           Grande Armée    = ERA_INDUSTRIAL / ERA_MODERN
--           Military First  = ERA_ATOMIC / ERA_INFORMATION
--         → 因此"限定 5 个时代"的做法 = 摘掉 NO_ERA 那条，改成 5 条各带一个 EraType。
--
--   本文件：① 摘除原版 NO_ERA 那条的挂载（建筑→修饰器）；② 新增 5 条 CCB 修饰器，逐字段照抄原版取值，
--           仅 EraType 不同；③ 逐条挂回 BUILDING_STATUE_OF_ZEUS。
--   ⚠ 只动"抗骑兵生产加成"这一条：宙斯像的 3 弓手 / 3 枪兵 / 1 破城槌（STAUEZEUS_GRANT_*）保持原样。
--   ⚠ 原版那条 Modifiers 行本身保留（不再被挂载，成为孤行；删它没有必要，留着便于日后比对）。
--   ⚠ 实际影响：现代时代的反坦克小组、原子能时代的现代反坦克将**不再**享受 +35%；
--     远古枪兵/希腊重装步兵、中世纪长枪兵/祖鲁班图武士、文艺复兴长枪火枪兵/瑞典卡洛琳仍享受。
--     古典与工业时代目前没有抗骑兵单位，列出这两个时代是为了与用户口径一致且对未来模组单位生效。
--==============================================================================================
DELETE FROM BuildingModifiers
	WHERE BuildingType = 'BUILDING_STATUE_OF_ZEUS' AND ModifierId = 'STAUEZEUS_ANTI_CAVALRY_PRODUCTION';

INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_ZEUS_ANTI_CAVALRY_ANCIENT',     'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION'),
	('CCB_ZEUS_ANTI_CAVALRY_CLASSICAL',   'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION'),
	('CCB_ZEUS_ANTI_CAVALRY_MEDIEVAL',    'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION'),
	('CCB_ZEUS_ANTI_CAVALRY_RENAISSANCE', 'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION'),
	('CCB_ZEUS_ANTI_CAVALRY_INDUSTRIAL',  'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_TAG_ERA_PRODUCTION');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_ZEUS_ANTI_CAVALRY_ANCIENT',     'Amount', 35),
	('CCB_ZEUS_ANTI_CAVALRY_ANCIENT',     'UnitPromotionClass', 'PROMOTION_CLASS_ANTI_CAVALRY'),
	('CCB_ZEUS_ANTI_CAVALRY_ANCIENT',     'EraType', 'ERA_ANCIENT'),
	('CCB_ZEUS_ANTI_CAVALRY_CLASSICAL',   'Amount', 35),
	('CCB_ZEUS_ANTI_CAVALRY_CLASSICAL',   'UnitPromotionClass', 'PROMOTION_CLASS_ANTI_CAVALRY'),
	('CCB_ZEUS_ANTI_CAVALRY_CLASSICAL',   'EraType', 'ERA_CLASSICAL'),
	('CCB_ZEUS_ANTI_CAVALRY_MEDIEVAL',    'Amount', 35),
	('CCB_ZEUS_ANTI_CAVALRY_MEDIEVAL',    'UnitPromotionClass', 'PROMOTION_CLASS_ANTI_CAVALRY'),
	('CCB_ZEUS_ANTI_CAVALRY_MEDIEVAL',    'EraType', 'ERA_MEDIEVAL'),
	('CCB_ZEUS_ANTI_CAVALRY_RENAISSANCE', 'Amount', 35),
	('CCB_ZEUS_ANTI_CAVALRY_RENAISSANCE', 'UnitPromotionClass', 'PROMOTION_CLASS_ANTI_CAVALRY'),
	('CCB_ZEUS_ANTI_CAVALRY_RENAISSANCE', 'EraType', 'ERA_RENAISSANCE'),
	('CCB_ZEUS_ANTI_CAVALRY_INDUSTRIAL',  'Amount', 35),
	('CCB_ZEUS_ANTI_CAVALRY_INDUSTRIAL',  'UnitPromotionClass', 'PROMOTION_CLASS_ANTI_CAVALRY'),
	('CCB_ZEUS_ANTI_CAVALRY_INDUSTRIAL',  'EraType', 'ERA_INDUSTRIAL');

INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
	('BUILDING_STATUE_OF_ZEUS', 'CCB_ZEUS_ANTI_CAVALRY_ANCIENT'),
	('BUILDING_STATUE_OF_ZEUS', 'CCB_ZEUS_ANTI_CAVALRY_CLASSICAL'),
	('BUILDING_STATUE_OF_ZEUS', 'CCB_ZEUS_ANTI_CAVALRY_MEDIEVAL'),
	('BUILDING_STATUE_OF_ZEUS', 'CCB_ZEUS_ANTI_CAVALRY_RENAISSANCE'),
	('BUILDING_STATUE_OF_ZEUS', 'CCB_ZEUS_ANTI_CAVALRY_INDUSTRIAL');

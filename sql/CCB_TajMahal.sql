------------------------------------------------------------------------------
--	FILE:	 CCB_TajMahal.sql
--	PURPOSE: 泰姬陵「沙贾汗的黄金时代」三选一（2026-09-19 用户设计定稿）
--	机制：   完成泰姬陵 → UI 弹窗三选一（ui/ccb_tajmahal_popup.*）
--	         → UI→Gameplay 桥（scripts/ccb_tajmahal.lua，PlayerOperations.EXECUTE_SCRIPT）
--	         → player:AttachModifierByID 挂对应修饰器
--	门控：   所有效果 OwnerRequirementSetId = PLAYER_HAS_GOLDEN_AGE
--	         → 黄金时代（含英雄时代）生效；非黄金自动失效；再入黄金自动恢复（引擎每回合求值，无残留）
--	结构：   参照已验证探针 tools/archive/HGProbe_v0.1/（全项实测通过 2026-09-11）
--	设计：   见 docs/泰姬陵设计方案.md（C 方案：选项只用"着力点未占用"的维度）
--	备注：   ⏳ 选项 3「铭文之壁」的"人造奇观旅游业绩 +6"待定讨论（引擎把奇观旅游表达为百分比，
--	         且该维度与着力点「愿你在此」重叠）——见文件末尾说明。
------------------------------------------------------------------------------

--==============================================================================================
-- 1. 四分园（Charbagh）：所有城市 +1 宜居度
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId) VALUES
	('CCB_TAJ_CHARBAGH_AMENITY', 'MODIFIER_PLAYER_CITIES_ADJUST_TRAIT_AMENITY', 'PLAYER_HAS_GOLDEN_AGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_TAJ_CHARBAGH_AMENITY', 'Amount', 1);

--==============================================================================================
-- 2. 镶嵌工艺（Parchin Kari）：建造者 +1 充能；每座工业区 +1 大工程师点；每座工作坊 +2 大工程师点
--    原版先例：城邦斯德哥尔摩宗主 = MODIFIER_PLAYER_DISTRICTS_ADJUST_GREAT_PERSON_POINTS + DISTRICT_IS_INDUSTRIAL_ZONE → +1 大工程师点
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
	-- 建造者 +1 充能：Subject 用原版 UNIT_IS_BUILDER 限定（金字塔同款写法）
	('CCB_TAJ_INLAY_BUILDER',       'MODIFIER_PLAYER_UNITS_ADJUST_BUILDER_CHARGES',          'PLAYER_HAS_GOLDEN_AGE', 'UNIT_IS_BUILDER'),
	('CCB_TAJ_INLAY_IZ_GEP',        'MODIFIER_PLAYER_DISTRICTS_ADJUST_GREAT_PERSON_POINTS',  'PLAYER_HAS_GOLDEN_AGE', 'DISTRICT_IS_INDUSTRIAL_ZONE'),
	('CCB_TAJ_INLAY_WORKSHOP_GEP',  'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT_BASE', 'PLAYER_HAS_GOLDEN_AGE', 'CCB_TAJ_REQSET_CITY_HAS_WORKSHOP');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_TAJ_INLAY_BUILDER', 'Amount', 1),
	('CCB_TAJ_INLAY_IZ_GEP', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_ENGINEER'),
	('CCB_TAJ_INLAY_IZ_GEP', 'Amount', 1),
	('CCB_TAJ_INLAY_WORKSHOP_GEP', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_ENGINEER'),
	('CCB_TAJ_INLAY_WORKSHOP_GEP', 'Amount', 2);

-- 「城市拥有工作坊」需求（工程内同类先例：Kotoku 的 REQUIREMENT_CITY_HAS_BUILDING）
INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('CCB_TAJ_REQ_CITY_HAS_WORKSHOP', 'REQUIREMENT_CITY_HAS_BUILDING');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('CCB_TAJ_REQ_CITY_HAS_WORKSHOP', 'BuildingType', 'BUILDING_WORKSHOP');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('CCB_TAJ_REQSET_CITY_HAS_WORKSHOP', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('CCB_TAJ_REQSET_CITY_HAS_WORKSHOP', 'CCB_TAJ_REQ_CITY_HAS_WORKSHOP');

--==============================================================================================
-- 3. 铭文之壁（Calligraphy）：拥有剧院广场的城市 +2 大作家点、+2 大艺术家点
--    （"人造奇观旅游业绩 +6"待定：见文件末尾）
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
	('CCB_TAJ_CALLI_WRITER', 'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT_BASE', 'PLAYER_HAS_GOLDEN_AGE', 'BBG_CITY_HAS_DISTRICT_THEATER'),
	('CCB_TAJ_CALLI_ARTIST', 'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT_BASE', 'PLAYER_HAS_GOLDEN_AGE', 'BBG_CITY_HAS_DISTRICT_THEATER');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_TAJ_CALLI_WRITER', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_WRITER'),
	('CCB_TAJ_CALLI_WRITER', 'Amount', 2),
	('CCB_TAJ_CALLI_ARTIST', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_ARTIST'),
	('CCB_TAJ_CALLI_ARTIST', 'Amount', 2);

--==============================================================================================
-- 待接入：选项 3 的奇观旅游
--   用户设计值："所有人造奇观的旅游业绩增加 6 点"。
--   引擎限制：奇观旅游只能用百分比表达（MODIFIER_PLAYER_CITIES_ADJUST_TOURISM + BoostsWonders=true
--   + ScalingFactor=N），没有"每座奇观 +N 点"的平坦写法；且该维度已被着力点「愿你在此」占用
--   （原版 COMMEMORATION_TOURISM_GA_WONDERS = 总督城 +150% 奇观旅游）。
--   备选：① 奇观旅游 +X%（同维度叠加，违反 C 原则）② 巨作旅游 +X%（
--   MODIFIER_PLAYER_ADJUST_GREAT_WORK_OBJECT_TOURISM，无占用 ✅）③ 换维度（巨作槽位等）。
--   用户拍板后在此追加 1 条修饰器 + 挂载 + 文本。
--==============================================================================================

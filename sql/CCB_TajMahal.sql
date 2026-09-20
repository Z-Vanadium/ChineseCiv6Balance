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
--	备注：   选项 3「铭文之壁」的旅游条款按用户 2026-09-19 二次定稿改为 **书本类巨作旅游业绩 +100%**
--	         （原"人造奇观旅游 +6"因引擎只支持百分比、且与着力点「愿你在此」同维度而废弃）
------------------------------------------------------------------------------

--==============================================================================================
-- 1. 四分园（Charbagh）：所有城市 +1 宜居度
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId) VALUES
	('CCB_TAJ_CHARBAGH_AMENITY', 'MODIFIER_PLAYER_CITIES_ADJUST_TRAIT_AMENITY', 'PLAYER_HAS_GOLDEN_AGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_TAJ_CHARBAGH_AMENITY', 'Amount', 1);

--==============================================================================================
-- 2. 镶嵌工艺（Parchin Kari）：建造者 +1 充能；每座工业区 +1 大工程师点；每座工作坊 +1 大工程师点
--    原版先例：城邦斯德哥尔摩宗主 = MODIFIER_PLAYER_DISTRICTS_ADJUST_GREAT_PERSON_POINTS + DISTRICT_IS_INDUSTRIAL_ZONE → +1 大工程师点
--    调整沿革：2026-09-20 一轮（工业区 1→2、工作坊 2→1）；2026-09-20 二轮（工业区回退为 1，两者均为 +1）
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
	('CCB_TAJ_INLAY_WORKSHOP_GEP', 'Amount', 1);

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
-- 3. 铭文之壁（Calligraphy）：每座剧院广场 +1 大作家点；每座古罗马剧场（BUILDING_AMPHITHEATER）+1 大艺术家点
--    调整沿革：2026-09-20 一轮（大作家点 2→4，随即回退）；二轮（大作家点定为 +1/剧院广场；
--              大艺术家点由"每座剧院广场 +2"改为"每座古罗马剧场 +1" —— 用户口径"每座古罗马"= 剧院广场 T1 建筑）
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
	('CCB_TAJ_CALLI_WRITER', 'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT_BASE', 'PLAYER_HAS_GOLDEN_AGE', 'BBG_CITY_HAS_DISTRICT_THEATER'),
	('CCB_TAJ_CALLI_ARTIST', 'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT_BASE', 'PLAYER_HAS_GOLDEN_AGE', 'CCB_TAJ_REQSET_CITY_HAS_AMPHITHEATER');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_TAJ_CALLI_WRITER', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_WRITER'),
	('CCB_TAJ_CALLI_WRITER', 'Amount', 1),
	('CCB_TAJ_CALLI_ARTIST', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_ARTIST'),
	('CCB_TAJ_CALLI_ARTIST', 'Amount', 1);

-- 「城市拥有古罗马剧场」需求（做法同上面的"城市拥有工作坊"）
INSERT INTO Requirements (RequirementId, RequirementType) VALUES
	('CCB_TAJ_REQ_CITY_HAS_AMPHITHEATER', 'REQUIREMENT_CITY_HAS_BUILDING');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('CCB_TAJ_REQ_CITY_HAS_AMPHITHEATER', 'BuildingType', 'BUILDING_AMPHITHEATER');
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('CCB_TAJ_REQSET_CITY_HAS_AMPHITHEATER', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('CCB_TAJ_REQSET_CITY_HAS_AMPHITHEATER', 'CCB_TAJ_REQ_CITY_HAS_AMPHITHEATER');

--==============================================================================================
-- 3b. 铭文之壁（追加）：巨作旅游业绩 +100%，按巨作类别过滤（两类各一条）
--     ① 著作类（Great Works of Writing，GREATWORKOBJECT_WRITING）
--     ② 宗教艺术类（GREATWORKOBJECT_RELIGIOUS —— 大艺术家创作的宗教主题艺术品）
--     用户定稿：2026-09-19 首次（原设计"人造奇观旅游 +6"替换为本条）；2026-09-20 追加宗教艺术类
--     写法完全取自原版同款先例（玩家级、按巨作类别过滤）：
--       · OPERA_BALLET_BOOST_WRITING_TOURISM（歌剧与芭蕾市政）/ PRINTING_BOOST_WRITING_TOURISM（印刷术科技）
--         = MODIFIER_PLAYER_CITIES_ADJUST_TOURISM + GreatWorkObjectType=GREATWORKOBJECT_WRITING + ScalingFactor=200
--       · HERITAGE_RELIGIOUSTOURISM（世界议会「遗产组织」宗教类）→ 同写法、GreatWorkObjectType=GREATWORKOBJECT_RELIGIOUS
--       · ScalingFactor 语义：200 = ×2（= +100%）、300 = ×3（圣物箱「遗物产出3倍」实证）
--     维度核验：巨作旅游**未被任何着力点占用**（「愿你在此」加的是奇观旅游与魅力）✅ 符合 C 方案
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId) VALUES
	('CCB_TAJ_CALLI_WRITING_TOURISM',   'MODIFIER_PLAYER_CITIES_ADJUST_TOURISM', 'PLAYER_HAS_GOLDEN_AGE'),
	('CCB_TAJ_CALLI_RELIGIOUS_TOURISM', 'MODIFIER_PLAYER_CITIES_ADJUST_TOURISM', 'PLAYER_HAS_GOLDEN_AGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_TAJ_CALLI_WRITING_TOURISM', 'GreatWorkObjectType', 'GREATWORKOBJECT_WRITING'),
	('CCB_TAJ_CALLI_WRITING_TOURISM', 'ScalingFactor', 200),
	('CCB_TAJ_CALLI_RELIGIOUS_TOURISM', 'GreatWorkObjectType', 'GREATWORKOBJECT_RELIGIOUS'),
	('CCB_TAJ_CALLI_RELIGIOUS_TOURISM', 'ScalingFactor', 200);



------------------------------------------------------------------------------
--	FILE:	 CCB_NaturalWonderBalance.sql
--	PURPOSE: CCB 对「CCB 地图 / BBM」新增自然奇观的数值与机制调整（2026-09-19 用户需求）
--	NOTE:	 加载序很关键 —— CCB 地图的 sql/bbs_new_wonders.sql 在 LoadOrder 20000 加载，
--	         晚于 CCB 的 base.sql(11611)/Catherine_Persona.sql(11646)。因此本块必须用
--	         LoadOrder 100110（> 20000/20005）才能覆盖生效，并以 <Criteria>BBS</Criteria> 门控
--	         （仅在启用 CCB 地图/BBM 时加载，避免无该模组时对不存在的 FEATURE_* 行做无效写入）。
--	         文本覆盖在 lang/chinese.xml、lang/english.xml（LoadOrder 100000000，最后加载）。
------------------------------------------------------------------------------

--==============================================================================================
-- 1. 西奈山（FEATURE_SINAI）：相邻信仰 2 → 3
--==============================================================================================
UPDATE Feature_AdjacentYields SET YieldChange=3
	WHERE FeatureType='FEATURE_SINAI' AND YieldType='YIELD_FAITH';

--==============================================================================================
-- 2. 老实泉（FEATURE_OLD_FAITHFUL）：新增 +1 生产力；学院相邻 +2 科技扩展到学院类 UD
--    UD：朝鲜「书院」DISTRICT_SEOWON、玛雅「天文台」DISTRICT_OBSERVATORY
--==============================================================================================
UPDATE Feature_YieldChanges SET YieldChange=1
	WHERE FeatureType='FEATURE_OLD_FAITHFUL' AND YieldType='YIELD_PRODUCTION';
INSERT INTO Feature_YieldChanges (FeatureType, YieldType, YieldChange)
	SELECT 'FEATURE_OLD_FAITHFUL', 'YIELD_PRODUCTION', 1
	WHERE NOT EXISTS (SELECT 1 FROM Feature_YieldChanges
		WHERE FeatureType='FEATURE_OLD_FAITHFUL' AND YieldType='YIELD_PRODUCTION');

-- 只有当对应 UD 存在时才写入（缺 DLC 时跳过，避免外键校验失败）；带 NOT EXISTS 保证幂等
INSERT INTO District_Adjacencies (DistrictType, YieldChangeId)
	SELECT 'DISTRICT_SEOWON', 'OldFaithful_Science'
	WHERE EXISTS (SELECT 1 FROM Districts WHERE DistrictType='DISTRICT_SEOWON')
	  AND NOT EXISTS (SELECT 1 FROM District_Adjacencies WHERE DistrictType='DISTRICT_SEOWON' AND YieldChangeId='OldFaithful_Science');
INSERT INTO District_Adjacencies (DistrictType, YieldChangeId)
	SELECT 'DISTRICT_OBSERVATORY', 'OldFaithful_Science'
	WHERE EXISTS (SELECT 1 FROM Districts WHERE DistrictType='DISTRICT_OBSERVATORY')
	  AND NOT EXISTS (SELECT 1 FROM District_Adjacencies WHERE DistrictType='DISTRICT_OBSERVATORY' AND YieldChangeId='OldFaithful_Science');

--==============================================================================================
-- 3. 维多利亚湖（FEATURE_LAKE_VICTORIA）：生产力 1 → 2
--==============================================================================================
UPDATE Feature_YieldChanges SET YieldChange=2
	WHERE FeatureType='FEATURE_LAKE_VICTORIA' AND YieldType='YIELD_PRODUCTION';

--==============================================================================================
-- 4. 乌尤尼盐沼（FEATURE_SALAR_DE_UYUNI）
--    4a 移除「商业中心相邻 +2 金」
--    4b 新增「拥有至少 1 格乌尤尼盐沼 → 国内所有带资源的矿场 +2 金」（与万神殿「宗教偶像」叠加）
--       参考写法：奇观「生物荧光海滩」的 ALL_PLAYERS_ATTACH + GameModifiers 结构；
--       地块判定用原版需求集思路（矿产需求 ID REQUIRES_PLOT_HAS_MINE + 任意资源）
--==============================================================================================
-- 4a
DELETE FROM District_Adjacencies WHERE YieldChangeId='SalarDeUyuni_Gold';
DELETE FROM Adjacency_YieldChanges WHERE ID='SalarDeUyuni_Gold';

-- 4b-1 需求
INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType) VALUES
	('CCB_NW_REQ_PLAYER_HAS_SALAR', 'REQUIREMENT_PLAYER_HAS_FEATURE'),
	('CCB_NW_REQ_MAP_HAS_SALAR', 'REQUIREMENT_MAP_HAS_FEATURE'),
	('CCB_NW_REQ_PLOT_HAS_ANY_RESOURCE', 'REQUIREMENT_PLOT_HAS_ANY_RESOURCE');
INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('CCB_NW_REQ_PLAYER_HAS_SALAR', 'FeatureType', 'FEATURE_SALAR_DE_UYUNI'),
	('CCB_NW_REQ_MAP_HAS_SALAR', 'FeatureType', 'FEATURE_SALAR_DE_UYUNI');

-- 4b-2 需求集
INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('CCB_NW_REQSET_PLAYER_HAS_SALAR', 'REQUIREMENTSET_TEST_ALL'),
	('CCB_NW_REQSET_MAP_HAS_SALAR', 'REQUIREMENTSET_TEST_ALL'),
	('CCB_NW_REQSET_PLOT_HAS_RESOURCE_MINE', 'REQUIREMENTSET_TEST_ALL');
INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('CCB_NW_REQSET_PLAYER_HAS_SALAR', 'CCB_NW_REQ_PLAYER_HAS_SALAR'),
	('CCB_NW_REQSET_MAP_HAS_SALAR', 'CCB_NW_REQ_MAP_HAS_SALAR'),
	('CCB_NW_REQSET_PLOT_HAS_RESOURCE_MINE', 'REQUIRES_PLOT_HAS_MINE'),
	('CCB_NW_REQSET_PLOT_HAS_RESOURCE_MINE', 'CCB_NW_REQ_PLOT_HAS_ANY_RESOURCE');

-- 4b-3 修饰器：外层「转发给玩家」+ 内层「地块产出」
INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
	('CCB_NW_SALAR_MINE_GOLD_ATTACH', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'CCB_NW_REQSET_MAP_HAS_SALAR', 'CCB_NW_REQSET_PLAYER_HAS_SALAR'),
	('CCB_NW_SALAR_MINE_GOLD', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', NULL, 'CCB_NW_REQSET_PLOT_HAS_RESOURCE_MINE');
INSERT OR IGNORE INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_NW_SALAR_MINE_GOLD_ATTACH', 'ModifierId', 'CCB_NW_SALAR_MINE_GOLD'),
	('CCB_NW_SALAR_MINE_GOLD', 'YieldType', 'YIELD_GOLD'),
	('CCB_NW_SALAR_MINE_GOLD', 'Amount', 2);
INSERT OR IGNORE INTO GameModifiers (ModifierId) VALUES ('CCB_NW_SALAR_MINE_GOLD_ATTACH');

--==============================================================================================
-- 5. 巴林格陨石坑（FEATURE_BARRINGER_CRATER）
--    科技 3 → 5；太空竞赛 +10% → +15%；修复「修饰器未挂载」BUG（同族其它奇观都进了 GameModifiers）
--==============================================================================================
UPDATE Feature_YieldChanges SET YieldChange=5
	WHERE FeatureType='FEATURE_BARRINGER_CRATER' AND YieldType='YIELD_SCIENCE';
UPDATE ModifierArguments SET Value='-15'
	WHERE ModifierId='MODIFIER_FEATURE_BARRINGER_CRATER_SPACE_PROJECT' AND Name='Amount';
INSERT OR IGNORE INTO GameModifiers (ModifierId) VALUES ('MODIFIER_FEATURE_BARRINGER_CRATER_ATTACH_PLAYERS');

--==============================================================================================
-- 6. 生物荧光海滩（FEATURE_BIOLUMINESCENT_BAY）：科技 3 → 5（「渔船 +1 金」维持原样）
--==============================================================================================
UPDATE Feature_YieldChanges SET YieldChange=5
	WHERE FeatureType='FEATURE_BIOLUMINESCENT_BAY' AND YieldType='YIELD_SCIENCE';

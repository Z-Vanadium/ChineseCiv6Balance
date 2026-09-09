-- free city center building after code of laws
--====Trajan====--
-- 08/07/24 delayed to foreign trade
-- 08/04/25 delayed to early empire
UPDATE Modifiers SET SubjectRequirementSetId='BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET' WHERE ModifierId='TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING';

--====Rome======--
-- 2026/07/12 浴场：不再提供文化
-- reverted 04/10/22
-- back to the menu 07/07/25
-- 2026/09 用户确认：澡堂（罗马 UD，凯撒可用）每相邻 2 个区域提供 +1 文化（专业区域相邻加成同款结构）
INSERT INTO District_Adjacencies (DistrictType, YieldChangeId) VALUES
	('DISTRICT_BATH' , 'District_Culture');

-- 07/07/25 Bath no longer give amenity
-- 2026/06/02 back
-- UPDATE Districts SET Entertainment=0 WHERE DistrictType='DISTRICT_BATH';


-- 08/04/25 Legions down to 38
UPDATE Units SET Combat=38 WHERE UnitType='UNIT_ROMAN_LEGION';
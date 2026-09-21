--==============================================================================================
--******				GOVERNMENT						   ******
--==============================================================================================
-- fascism attack bonus works on defense now too
UPDATE Modifiers SET SubjectRequirementSetId=NULL WHERE ModifierId='FASCISM_ATTACK_BUFF';
UPDATE Modifiers SET SubjectRequirementSetId=NULL WHERE ModifierId='FASCISM_LEGACY_ATTACK_BUFF';

UPDATE Governments SET OtherGovernmentIntolerance=0 WHERE GovernmentType='GOVERNMENT_DEMOCRACY';
UPDATE Governments SET OtherGovernmentIntolerance=-40 WHERE GovernmentType='GOVERNMENT_FASCISM';
UPDATE Governments SET OtherGovernmentIntolerance=-50 WHERE GovernmentType='GOVERNMENT_COMMUNISM';
UPDATE ModifierArguments SET Value='4' WHERE ModifierId='COLLECTIVIZATION_INTERNAL_TRADE_PRODUCTION' AND Name='Amount';

-- Government slot
UPDATE Government_SlotCounts SET NumSlots=1 WHERE GovernmentType='GOVERNMENT_MERCHANT_REPUBLIC' AND GovernmentSlotType='SLOT_DIPLOMATIC';
UPDATE Government_SlotCounts SET NumSlots=2 WHERE GovernmentType='GOVERNMENT_MERCHANT_REPUBLIC' AND GovernmentSlotType='SLOT_WILDCARD';

--11/12/22 Communism -1 red card +1 yellow card
-- 15/12/24 -1 yellow +1 wildcard
UPDATE Government_SlotCounts SET NumSlots=2 WHERE GovernmentType='GOVERNMENT_COMMUNISM' AND GovernmentSlotType='SLOT_MILITARY';
-- UPDATE Government_SlotCounts SET NumSlots=4 WHERE GovernmentType='GOVERNMENT_COMMUNISM' AND GovernmentSlotType='SLOT_ECONOMIC';
UPDATE Government_SlotCounts SET NumSlots=2 WHERE GovernmentType='GOVERNMENT_COMMUNISM' AND GovernmentSlotType='SLOT_WILDCARD';

--11/12/22
--11/12/22 Collectivization also give +4 gold per traderoute
INSERT INTO Modifiers(ModifierId, ModifierType) VALUES
    ('BBG_COLLECTIVIZATION_TRADE_GOLD', 'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_YIELD');
INSERT INTO ModifierArguments(ModifierId, Name, Value) VALUES
    ('BBG_COLLECTIVIZATION_TRADE_GOLD', 'YieldType', 'YIELD_GOLD'),
    ('BBG_COLLECTIVIZATION_TRADE_GOLD', 'Amount', '4');
INSERT INTO PolicyModifiers(PolicyType, ModifierId) VALUES
    ('POLICY_COLLECTIVIZATION', 'BBG_COLLECTIVIZATION_TRADE_GOLD');

-- 15/10/23 Theocracy discount from 15 to 10%
-- 10/03/24 Reverted
-- UPDATE ModifierArguments SET Value=10 WHERE ModifierId='THEOCRACY_FAITH_PURCHASE' and Name='Amount';

-- 10/03/24 Autocracy gives 1 food and production to monument if the city have at least one district
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('BBG_MONUMENT_FOOD_AUTOCRACY_1_DISTRICT', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 'CITY_HAS_1_SPECIALTY_DISTRICT'),
    ('BBG_MONUMENT_PRODUCTION_AUTOCRACY_1_DISTRICT', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 'CITY_HAS_1_SPECIALTY_DISTRICT');
INSERT INTO ModifierArguments(ModifierId, Name, Value) VALUES
    ('BBG_MONUMENT_FOOD_AUTOCRACY_1_DISTRICT', 'BuildingType', 'BUILDING_MONUMENT'),
    ('BBG_MONUMENT_FOOD_AUTOCRACY_1_DISTRICT', 'YieldType', 'YIELD_FOOD'),
    ('BBG_MONUMENT_FOOD_AUTOCRACY_1_DISTRICT', 'Amount', '1'),
    ('BBG_MONUMENT_PRODUCTION_AUTOCRACY_1_DISTRICT', 'BuildingType', 'BUILDING_MONUMENT'),
    ('BBG_MONUMENT_PRODUCTION_AUTOCRACY_1_DISTRICT', 'YieldType', 'YIELD_PRODUCTION'),
    ('BBG_MONUMENT_PRODUCTION_AUTOCRACY_1_DISTRICT', 'Amount', '1');
INSERT INTO GovernmentModifiers (GovernmentType, ModifierId) VALUES
    ('GOVERNMENT_AUTOCRACY', 'BBG_MONUMENT_FOOD_AUTOCRACY_1_DISTRICT'),
    ('GOVERNMENT_AUTOCRACY', 'BBG_MONUMENT_PRODUCTION_AUTOCRACY_1_DISTRICT');
INSERT INTO PolicyModifiers (PolicyType, ModifierId) VALUES
    ('POLICY_GOV_AUTOCRACY', 'BBG_MONUMENT_FOOD_AUTOCRACY_1_DISTRICT'),
    ('POLICY_GOV_AUTOCRACY', 'BBG_MONUMENT_PRODUCTION_AUTOCRACY_1_DISTRICT');

-- 2026-XX-XX Anarchy duration reduced: repeated-same-government penalty 4 -> 2 turns
-- 原版 GOVERNMENT_BASE_ANARCHY_TURNS=2：首次切换政体 2 回合无政府；
-- 重复进入相同政体时惩罚翻倍为 4 回合。改为 base=1 → 首次 1 回合、重复 2 回合。
UPDATE GlobalParameters SET Value='1' WHERE Name='GOVERNMENT_BASE_ANARCHY_TURNS';

--==============================================================================================
-- 2026-09-20 四级政体「团体自由意志主义（GOVERNMENT_CORPORATE_LIBERTARIANISM）」新增：
--   **所有战斗单位攻击后可移动**（用户需求；原来只有象兵/哥萨克等个别单位有）
--
--   机制（原版同款）：`MODIFIER_PLAYER_UNIT_ADJUST_ATTACK_AND_MOVE` + `CanMove=1`
--     · 越南象兵 UNIT_VIETNAMESE_VOI_CHIEN = 能力 ABILITY_VOI_CHIEN（标签 CLASS_VOI_CHIEN）
--       → UnitAbilityModifiers → VOI_CHIEN_MOVE_AND_ATTACK（同类型，CanMove=1）
--     · 哥萨克 COSSACK_MOVE_AND_ATTACK 同款；远距离作战验证：象兵本身是远程单位 → 远程同样适用
--     · 原版 ABILITY_NO_MOVE_AND_SHOOT 只作用于 CLASS_FIELD_SETUP / CLASS_SIEGE_SETUP（攻城架设），不冲突
--
--   挂法（与寡头 +4 战斗力同一套"政体 → GRANT_ABILITY"框架）：
--     政体 → CCB_CORPLIB_GRANT_MOVE_AFTER_ATTACK（GRANT_ABILITY）
--          → ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK（Inactive=1；标签 **CLASS_ALL_COMBAT_UNITS** = 全战斗单位）
--          → UnitAbilityModifiers → CCB_CORPLIB_MOVE_AFTER_ATTACK（CanMove=1）
--   ⚠ GRANT_ABILITY 只对 Inactive=1 的能力生效，且能力必须与单位共享至少一个 ABILITY_CLASS 标签
--     （本文件顶部的既有结论）——CLASS_ALL_COMBAT_UNITS 是原版常用的"全战斗单位"通配标签。
--==============================================================================================
INSERT INTO Types (Type, Kind) VALUES
	('ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK', 'KIND_ABILITY');
INSERT INTO TypeTags (Type, Tag) VALUES
	('ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK', 'CLASS_ALL_COMBAT_UNITS');
INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive) VALUES
	('ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK',
	 'LOC_ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK_NAME',
	 'LOC_ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK_DESC', 1);
INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
	('ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK', 'CCB_CORPLIB_MOVE_AFTER_ATTACK');
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
	('CCB_CORPLIB_MOVE_AFTER_ATTACK', 'MODIFIER_PLAYER_UNIT_ADJUST_ATTACK_AND_MOVE'),
	('CCB_CORPLIB_GRANT_MOVE_AFTER_ATTACK', 'MODIFIER_PLAYER_UNITS_GRANT_ABILITY');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('CCB_CORPLIB_MOVE_AFTER_ATTACK', 'CanMove', 1),
	('CCB_CORPLIB_GRANT_MOVE_AFTER_ATTACK', 'AbilityType', 'ABILITY_CCB_CORPLIB_MOVE_AFTER_ATTACK');
INSERT INTO GovernmentModifiers (GovernmentType, ModifierId) VALUES
	('GOVERNMENT_CORPORATE_LIBERTARIANISM', 'CCB_CORPLIB_GRANT_MOVE_AFTER_ATTACK');

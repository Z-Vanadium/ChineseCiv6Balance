-- Leader
-- regional gold and production remove
DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_LEADER_CVS_ESCHER_UA' AND ModifierId IN ('MODIFIER_CVS_ESCHER_UA_REGIONAL_PRODUCTION', 'MODIFIER_CVS_ESCHER_UA_REGIONAL_GOLD');

-- 2026/07/02 帝国初期市政后，位于山脉 2 个单元格范围内时 +1 宜居度
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_CVS_ESCHER_UA', 'CCB_SWITZERLADN_AMENITY');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SWITZERLADN_AMENITY', 'MODIFIER_PLAYER_CITIES_ADJUST_TRAIT_AMENITY', 0, 0, 0, 'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET', 'REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SWITZERLADN_AMENITY', 'Amount', '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS', 'REQUIREMENTSET_TEST_ANY');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) SELECT 
'REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS', 'REQ_CCB_PLOT_IS_IN_RANG_2_OF_' || TerrainType
FROM Terrains WHERE Mountain=1;
INSERT INTO Requirements (RequirementId, RequirementType) SELECT
'REQ_CCB_PLOT_IS_IN_RANG_2_OF_' || TerrainType, 'REQUIREMENT_PLOT_ADJACENT_TERRAIN_TYPE_MATCHES'
FROM Terrains WHERE Mountain=1;
INSERT INTO RequirementArguments (RequirementId, Name, Value) SELECT
'REQ_CCB_PLOT_IS_IN_RANG_2_OF_' || TerrainType, 'TerrainType', TerrainType
FROM Terrains WHERE Mountain=1;
INSERT INTO RequirementArguments (RequirementId, Name, Value) SELECT
'REQ_CCB_PLOT_IS_IN_RANG_2_OF_' || TerrainType, 'MinRange', 1
FROM Terrains WHERE Mountain=1;
INSERT INTO RequirementArguments (RequirementId, Name, Value) SELECT
'REQ_CCB_PLOT_IS_IN_RANG_2_OF_' || TerrainType, 'MaxRange', 2
FROM Terrains WHERE Mountain=1;

-- 2026/07/09 从 +50% 提升至 +100%；需要城市在山脉2环
-- +50% prod for commercial hub and industrial zone T1 and T2 buildings
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_CVS_ESCHER_UA', 'CCB_SWITZERLADN_PRODUCTION_BUILDING_MARKET'),
('TRAIT_LEADER_CVS_ESCHER_UA', 'CCB_SWITZERLADN_PRODUCTION_BUILDING_CVS_SWITZERLAND_UI'),
('TRAIT_LEADER_CVS_ESCHER_UA', 'CCB_SWITZERLADN_PRODUCTION_BUILDING_WORKSHOP'),
('TRAIT_LEADER_CVS_ESCHER_UA', 'CCB_SWITZERLADN_PRODUCTION_BUILDING_FACTORY');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES ('CCB_SWITZERLADN_PRODUCTION_BUILDING_MARKET', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS'),
('CCB_SWITZERLADN_PRODUCTION_BUILDING_CVS_SWITZERLAND_UI', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS'),
('CCB_SWITZERLADN_PRODUCTION_BUILDING_WORKSHOP', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS'),
('CCB_SWITZERLADN_PRODUCTION_BUILDING_FACTORY', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_IN_RANG_2_OF_MOUNTAINS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SWITZERLADN_PRODUCTION_BUILDING_MARKET', 'Amount', '100'), 
('CCB_SWITZERLADN_PRODUCTION_BUILDING_MARKET', 'BuildingType', 'BUILDING_MARKET'),
('CCB_SWITZERLADN_PRODUCTION_BUILDING_CVS_SWITZERLAND_UI', 'Amount', '100'), 
('CCB_SWITZERLADN_PRODUCTION_BUILDING_CVS_SWITZERLAND_UI', 'BuildingType', 'BUILDING_CVS_SWITZERLAND_UI'),
('CCB_SWITZERLADN_PRODUCTION_BUILDING_WORKSHOP', 'Amount', '100'), 
('CCB_SWITZERLADN_PRODUCTION_BUILDING_WORKSHOP', 'BuildingType', 'BUILDING_WORKSHOP'),
('CCB_SWITZERLADN_PRODUCTION_BUILDING_FACTORY', 'Amount', '100'), 
('CCB_SWITZERLADN_PRODUCTION_BUILDING_FACTORY', 'BuildingType', 'BUILDING_FACTORY');

-- commercial hub bonus from mountains
INSERT INTO	TraitModifiers
		(TraitType,						ModifierId	)		
SELECT	'TRAIT_LEADER_CVS_ESCHER_UA',	 'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType
FROM	Terrains WHERE Mountain = 1;
INSERT INTO	Modifiers
		(ModifierId,											ModifierType,							SubjectRequirementSetId	)
SELECT	'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'MODTYPE_CVS_ESCHER_UA_TERRAIN_ADJ',	NULL
FROM	Terrains WHERE Mountain = 1;
INSERT INTO ModifierArguments	
        (ModifierId,											Name,			Value	)
SELECT  'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'DistrictType',	'DISTRICT_COMMERCIAL_HUB'
FROM    Terrains WHERE Mountain = 1;
INSERT INTO ModifierArguments	
        (ModifierId,									Name,			Value	)
SELECT  'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'TerrainType',	TerrainType
FROM    Terrains WHERE Mountain = 1;
INSERT INTO ModifierArguments	
        (ModifierId,									Name,			Value	)
SELECT  'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'YieldType',	'YIELD_GOLD'
FROM    Terrains WHERE Mountain = 1;
INSERT INTO ModifierArguments	
        (ModifierId,									Name,			Value	)
SELECT  'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'Amount',		1
FROM    Terrains WHERE Mountain = 1;
INSERT INTO ModifierArguments	
        (ModifierId,									Name,			Value	)
SELECT  'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'Description',	'LOC_MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_MOUNTAIN'
FROM    Terrains WHERE Mountain = 1;

-- Civilization
-- bias
DELETE FROM StartBiasTerrains WHERE TerrainType='TERRAIN_GRASS_HILLS' AND CivilizationType='CIVILIZATION_CVS_SWITZERLAND';
INSERT INTO StartBiasTerrains (Tier, TerrainType, CivilizationType)
VALUES (3, 'TERRAIN_PLAINS_MOUNTAIN', 'CIVILIZATION_CVS_SWITZERLAND');
UPDATE StartBiasTerrains SET Tier='3' WHERE TerrainType = 'TERRAIN_GRASS_MOUNTAIN' AND CivilizationType = 'CIVILIZATION_CVS_SWITZERLAND';

-- ua remove in lua
-- ua remove
DELETE FROM TraitModifiers WHERE TraitType = 'MINOR_CIV_DEFAULT_TRAIT' AND ModifierId = 'MODIFIER_CVS_SWITZERLAND_UA_FAVOR_ATTACH';

--2026/07/09 无需市政前置
-- get geneva suz bonus after political philosophy
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_CVS_SWITZERLAND_UA', 'CCB_SWITZERLAND_GENEVA_SUZ');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SWITZERLAND_GENEVA_SUZ', 'MODIFIER_PLAYER_ADJUST_TECHNOLOGY_BOOST', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SWITZERLAND_GENEVA_SUZ', 'Amount', '5');

-- spy +50% production
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_CVS_SWITZERLAND_UA', 'CCB_SWITZERLAND_SPY_PRODUCTION');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SWITZERLAND_SPY_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PRODUCTION', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SWITZERLAND_SPY_PRODUCTION', 'Amount', '50'), 
('CCB_SWITZERLAND_SPY_PRODUCTION', 'UnitType', 'UNIT_SPY');

-- uu cost from 200 to 125, combat from 45 to 48
UPDATE Units SET Cost=125, Combat=48 WHERE UnitType='UNIT_CVS_SWITZERLAND_UU';

-- uu promote
UPDATE ModifierArguments SET Value='7' WHERE ModifierId='MODIFIER_CVS_SWITZERLAND_UU_VS_WOUNDED' AND Name='Amount';

-- uu upgrade
UPDATE UnitUpgrades SET UpgradeUnit='UNIT_PIKE_AND_SHOT' WHERE Unit='UNIT_CVS_SWITZERLAND_UU';

-- spy efficiency -1
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_CVS_SWITZERLAND_UA', 'CCB_SWITZERLAND_SPY_BONUS');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SWITZERLAND_SPY_BONUS', 'MODIFIER_PLAYER_CITIES_ADJUST_SPY_BONUS', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SWITZERLAND_SPY_BONUS', 'Amount', '1');

-- 2026/07/09 ub 在外交部门而非银行业解锁；提供 +1 住房
UPDATE Buildings SET PrereqTech=NULL, PrereqCivic='CIVIC_DIPLOMATIC_SERVICE', Housing=1 WHERE BuildingType='BUILDING_CVS_SWITZERLAND_UI';

-- ub no gold
UPDATE Building_YieldChanges SET YieldChange=4 WHERE BuildingType = 'BUILDING_CVS_SWITZERLAND_UI' AND YieldType = 'YIELD_GOLD';

-- form bbg
INSERT INTO BuildingModifiers (BuildingType, ModifierId) SELECT
'BUILDING_CVS_SWITZERLAND_UI', ModifierId
FROM BuildingModifiers
WHERE BuildingType='BUILDING_BANK';
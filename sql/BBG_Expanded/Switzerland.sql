-- Leader
-- regional gold and production remove
DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_LEADER_CVS_ESCHER_UA' AND ModifierId IN ('MODIFIER_CVS_ESCHER_UA_REGIONAL_PRODUCTION', 'MODIFIER_CVS_ESCHER_UA_REGIONAL_GOLD');

-- commercial hub bonus from mountains
INSERT INTO	TraitModifiers
		(TraitType,						ModifierId	)		
SELECT	'TRAIT_LEADER_CVS_ESCHER_UA',	 'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType
FROM	Terrains WHERE Mountain = 1;
INSERT INTO	Modifiers
		(ModifierId,											ModifierType,							SubjectRequirementSetId	)
SELECT	'MODIFIER_CCB_ESCHER_UA_COMMERCIAL_ADJ_'||TerrainType,	'MODTYPE_CCB_ESCHER_UA_TERRAIN_ADJ',	NULL
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

-- get geneva suz bonus after political philosophy
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_CVS_SWITZERLAND_UA', 'CCB_SWITZERLAND_GENEVA_SUZ');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SWITZERLAND_GENEVA_SUZ', 'MODIFIER_PLAYER_ADJUST_TECHNOLOGY_BOOST', 0, 0, 0, 'BBG_UTILS_PLAYER_HAS_CIVIC_POLITICAL_PHILOSOPHY_REQSET', NULL);
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

-- spy efficiency -1
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_CVS_SWITZERLAND_UA', 'CCB_SWITZERLAND_SPY_BONUS');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SWITZERLAND_SPY_BONUS', 'MODIFIER_PLAYER_CITIES_ADJUST_SPY_BONUS', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SWITZERLAND_SPY_BONUS', 'Amount', '1');

-- ub no gold
UPDATE Building_YieldChanges SET YieldChange=8 WHERE BuildingType = 'BUILDING_CVS_SWITZERLAND_UI' AND YieldType = 'YIELD_GOLD';
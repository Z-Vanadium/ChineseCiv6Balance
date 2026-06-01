-- la
-- remove
DELETE FROM TraitModifiers WHERE ModifierId IN ('MODIFIER_MER_OUR_HOMES_OUR_FAITH_OUR_COUNTRY_AVERAGE_ATTACH', 'MODIFIER_MER_OUR_HOMES_OUR_FAITH_OUR_COUNTRY_CHARMING_ATTACH', 'MODIFIER_MER_OUR_HOMES_OUR_FAITH_OUR_COUNTRY_BREATHTAKING_ATTACH') AND TraitType = 'TRAIT_LEADER_MER_OUR_HOMES_OUR_FAITH_OUR_COUNTRY';
 
-- -50% debuff from damage
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_MER_OUR_HOMES_OUR_FAITH_OUR_COUNTRY', 'CCB_FINLAND_STRENGTH_REDUCTION');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_STRENGTH_REDUCTION', 'MODIFIER_PLAYER_UNITS_ADJUST_STRENGTH_REDUCTION_FOR_DAMAGE_MODIFIER', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_STRENGTH_REDUCTION', 'Amount', '50');

-- Lost city bonus: +5% all yields per lost city (max +20%)
INSERT INTO Types (Type, Kind) VALUES 
('MODIFIER_CCB_SINGLE_CITY_ADJUST_CITY_YIELD_MODIFIER', 'KIND_MODIFIER');
INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType) VALUES 
('MODIFIER_CCB_SINGLE_CITY_ADJUST_CITY_YIELD_MODIFIER', 'COLLECTION_OWNER', 'EFFECT_ADJUST_CITY_YIELD_MODIFIER');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_LOST_CITY_YIELD', 'MODIFIER_CCB_SINGLE_CITY_ADJUST_CITY_YIELD_MODIFIER', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_LOST_CITY_YIELD', 'Amount', '5'),
('CCB_FINLAND_LOST_CITY_YIELD', 'YieldType', 'YIELD_FOOD, YIELD_PRODUCTION, YIELD_GOLD, YIELD_SCIENCE, YIELD_CULTURE, YIELD_FAITH');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_LOST_CITY_ATTACH_YIELD', 'MODIFIER_PLAYER_CITIES_ATTACH_MODIFIER', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_LOST_CITY_ATTACH_YIELD', 'ModifierId', 'CCB_FINLAND_LOST_CITY_YIELD');

-- Lost city bonus: +1 combat strength per lost city (max +4)
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_LOST_CITY_COMBAT', 'MODIFIER_PLAYER_UNITS_ADJUST_UNIT_COMBAT', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_LOST_CITY_COMBAT', 'Amount', '1');

-- ca
-- remove
DELETE FROM TraitModifiers
      WHERE ModifierId IN ('MODIFIER_MER_KALEVALA_HOME_CONTINENT_LOYALTY', 'MODIFIER_MER_KALEVALA_CULTURE', 'MODIFIER_MER_KALEVALA_PRODUCTION', 'MODIFIER_MER_KALEVALA_UNIMPROVED_WOODS_ATTACH', 'MODIFIER_MER_KALEVALA_UNIMPROVED_WOODS_2_ATTACH', 'MODIFIER_MER_KALEVALA_UNIMPROVED_LAKE_ATTACH', 'MODIFIER_MER_KALEVALA_UNIMPROVED_LAKE_2_ATTACH') AND
            TraitType = 'TRAIT_CIVILIZATION_MER_KALEVALA';

DELETE FROM StartBiasFeatures WHERE CivilizationType='CIVILIZATION_MER_FINLAND' AND FeatureType='FEATURE_FOREST';
DELETE FROM StartBiasResources WHERE CivilizationType='CIVILIZATION_MER_FINLAND' AND ResourceType='RESOURCE_FURS';
DELETE FROM StartBiasRivers WHERE CivilizationType='CIVILIZATION_MER_FINLAND';
UPDATE StartBiasTerrains SET Tier=1 WHERE TerrainType='TERRAIN_TUNDRA' AND CivilizationType='CIVILIZATION_MER_FINLAND';
DELETE FROM StartBiasTerrains WHERE TerrainType='TERRAIN_COAST' AND CivilizationType='CIVILIZATION_MER_FINLAND';
INSERT INTO StartBiasTerrains (Tier, TerrainType, CivilizationType) VALUES (1, 'TERRAIN_TUNDRA_HILLS', 'CIVILIZATION_MER_FINLAND');

-- tundra forest food
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_MER_KALEVALA', 'CCB_FINLAND_TUNDRA_FOREST_FOOD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_TUNDRA_FOREST_FOOD', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_TUNDRA_FOREST');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_TUNDRA_FOREST_FOOD', 'Amount', '1'),
('CCB_FINLAND_TUNDRA_FOREST_FOOD', 'YieldType', 'YIELD_FOOD');

-- tundra hills forest food
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_MER_KALEVALA', 'CCB_FINLAND_TUNDRA_HILLS_FOREST_FOOD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_TUNDRA_HILLS_FOREST_FOOD', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_TUNDRA_HILLS_FOREST_FOOD', 'Amount', '1'),
('CCB_FINLAND_TUNDRA_HILLS_FOREST_FOOD', 'YieldType', 'YIELD_FOOD');

-- tundra forest food with resource
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_MER_KALEVALA', 'CCB_FINLAND_TUNDRA_FOREST_RESOURCE_FOOD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_TUNDRA_FOREST_RESOURCE_FOOD', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_TUNDRA_FOREST_RESOURCE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_TUNDRA_FOREST_RESOURCE_FOOD', 'Amount', '1'),
('CCB_FINLAND_TUNDRA_FOREST_RESOURCE_FOOD', 'YieldType', 'YIELD_FOOD');

-- tundra hills forest food with resource
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_MER_KALEVALA', 'CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE_FOOD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE_FOOD', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE_FOOD', 'Amount', '1'),
('CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE_FOOD', 'YieldType', 'YIELD_FOOD');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_FINLAND_TUNDRA_FOREST', 'REQUIREMENTSET_TEST_ALL'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST', 'REQUIREMENTSET_TEST_ALL'),
('REQSET_CCB_FINLAND_TUNDRA_FOREST_RESOURCE', 'REQUIREMENTSET_TEST_ALL'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_FINLAND_TUNDRA', 'REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES'),
('REQ_CCB_FINLAND_FOREST', 'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES'),
('REQ_CCB_FINLAND_TUNDRA_HILLS', 'REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES'),
('REQ_CCB_FINLAND_RESOURCE', 'REQUIREMENT_PLOT_HAS_ANY_RESOURCE');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_FINLAND_TUNDRA_FOREST', 'REQ_CCB_FINLAND_TUNDRA'),
('REQSET_CCB_FINLAND_TUNDRA_FOREST', 'REQ_CCB_FINLAND_FOREST'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST', 'REQ_CCB_FINLAND_TUNDRA_HILLS'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST', 'REQ_CCB_FINLAND_FOREST'),
('REQSET_CCB_FINLAND_TUNDRA_FOREST_RESOURCE', 'REQ_CCB_FINLAND_TUNDRA'),
('REQSET_CCB_FINLAND_TUNDRA_FOREST_RESOURCE', 'REQ_CCB_FINLAND_FOREST'),
('REQSET_CCB_FINLAND_TUNDRA_FOREST_RESOURCE', 'REQ_CCB_FINLAND_RESOURCE'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE', 'REQ_CCB_FINLAND_TUNDRA_HILLS'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE', 'REQ_CCB_FINLAND_FOREST'),
('REQSET_CCB_FINLAND_TUNDRA_HILLS_FOREST_RESOURCE', 'REQ_CCB_FINLAND_RESOURCE');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_FINLAND_TUNDRA', 'TerrainType', 'TERRAIN_TUNDRA'),
('REQ_CCB_FINLAND_FOREST', 'FeatureType', 'FEATURE_FOREST'),
('REQ_CCB_FINLAND_TUNDRA_HILLS', 'TerrainType', 'TERRAIN_TUNDRA_HILLS');

-- lumber mill gold
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_MER_KALEVALA', 'CCB_FINLAND_LUMBER_MILL_GOLD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_LUMBER_MILL_GOLD', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_LUMBER_MILL');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_LUMBER_MILL_GOLD', 'Amount', '2'),
('CCB_FINLAND_LUMBER_MILL_GOLD', 'YieldType', 'YIELD_GOLD');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_FINLAND_LUMBER_MILL', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_FINLAND_LUMBER_MILL', 'REQ_CCB_FINLAND_LUMBER_MILL');
INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_FINLAND_LUMBER_MILL', 'REQUIREMENT_PLOT_HAS_IMPROVEMENT');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_FINLAND_LUMBER_MILL', 'ImprovementType', 'IMPROVEMENT_LUMBER_MILL');

-- lake city culture
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_CIVILIZATION_MER_KALEVALA', 'CCB_FINLAND_LAKE_CITY_CULTURE');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_LAKE_CITY_CULTURE', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_CITY_IN_LAKE_RING_2');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_LAKE_CITY_CULTURE', 'Amount', '5'), 
('CCB_FINLAND_LAKE_CITY_CULTURE', 'YieldType', 'YIELD_CULTURE');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_FINLAND_CITY_IN_LAKE_RING_2', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_FINLAND_CITY_IN_LAKE_RING_2', 'REQ_CCB_FINLAND_CITY_IN_LAKE_RING_2');
INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_FINLAND_CITY_IN_LAKE_RING_2', 'REQUIREMENT_PLOT_ADJACENT_TO_LAKE');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_FINLAND_CITY_IN_LAKE_RING_2', 'MaxDistance', '2'), 
('REQ_CCB_FINLAND_CITY_IN_LAKE_RING_2', 'MinDistance', '1');

-- uu replace
DELETE FROM Units WHERE UnitType='UNIT_MER_SISSI';
INSERT OR REPLACE INTO Units (UnitType, BaseMoves, Cost, StrategicResource, AdvisorType, BaseSightRange, ZoneOfControl, Domain, FormationClass, Name, Description, MandatoryObsoleteTech, PurchaseYield, PromotionClass, Maintenance, Combat, RangedCombat, AirSlots, Range, PrereqTech, PrereqCivic, TraitType, BuildCharges) SELECT
'UNIT_MER_SISSI', BaseMoves, Cost, NULL, AdvisorType, BaseSightRange, ZoneOfControl, Domain, FormationClass, 'LOC_UNIT_MER_SISSI_NAME', 'LOC_UNIT_MER_SISSI_DESCRIPTION', MandatoryObsoleteTech, PurchaseYield, PromotionClass, Maintenance, 80, 75, AirSlots, 2, PrereqTech, PrereqCivic, 'TRAIT_CIVILIZATION_UNIT_MER_SISSI', BuildCharges
FROM Units WHERE UnitType='UNIT_INFANTRY';

-- UnitUpgrades
DELETE FROM UnitUpgrades WHERE Unit='UNIT_MER_SISSI';
INSERT OR REPLACE INTO UnitUpgrades (Unit, UpgradeUnit)
SELECT 'UNIT_MER_SISSI', UpgradeUnit
FROM UnitUpgrades WHERE Unit='UNIT_INFANTRY';

-- Units_XP2
DELETE FROM Units_XP2 WHERE UnitType='UNIT_MER_SISSI';

-- TypeTags
DELETE FROM TypeTags WHERE Type='UNIT_MER_SISSI';
INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT
'UNIT_MER_SISSI', Tag
FROM TypeTags WHERE Type='UNIT_INFANTRY';

-- UnitAiInfos
DELETE FROM UnitAiInfos WHERE UnitType='UNIT_MER_SISSI';
INSERT OR REPLACE INTO UnitAiInfos (UnitType, AiType) SELECT
'UNIT_MER_SISSI', AiType
FROM UnitAiInfos WHERE UnitType='UNIT_INFANTRY';

-- UnitReplaces
DELETE FROM UnitReplaces WHERE CivUniqueUnitType='UNIT_MER_SISSI';
INSERT OR REPLACE INTO UnitReplaces (CivUniqueUnitType, ReplacesUnitType) VALUES
('UNIT_MER_SISSI', 'UNIT_INFANTRY');

-- ui
-- valid build
DELETE FROM Improvement_ValidTerrains
      WHERE TerrainType IN ('TERRAIN_GRASS', 'TERRAIN_GRASS_HILLS', 'TERRAIN_PLAINS', 'TERRAIN_PLAINS_HILLS') AND
            ImprovementType = 'IMPROVEMENT_MER_SAUNA';

-- only 1
UPDATE Improvements SET OnePerCity=1, Housing=1 WHERE ImprovementType='IMPROVEMENT_MER_SAUNA';

DELETE FROM Improvement_YieldChanges
      WHERE YieldChange = 1 AND
            ImprovementType = 'IMPROVEMENT_MER_SAUNA' AND
            YieldType = 'YIELD_PRODUCTION';
INSERT INTO Improvement_YieldChanges (ImprovementType, YieldType, YieldChange) VALUES
('IMPROVEMENT_MER_SAUNA', 'YIELD_FOOD', 2);

DELETE FROM ImprovementModifiers
      WHERE ImprovementType = 'IMPROVEMENT_MER_SAUNA' AND
            ModifierID = 'MER_SAUNA_RIVERADJACENCY_AMENITY';

INSERT INTO ImprovementModifiers (ImprovementType, ModifierId) VALUES 
('IMPROVEMENT_MER_SAUNA', 'CCB_FINLAND_UI_AMENITY');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_UI_AMENITY', 'MODIFIER_SINGLE_CITY_ADJUST_IMPROVEMENT_AMENITY', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_UI_AMENITY', 'Amount', '1');

INSERT INTO ImprovementModifiers (ImprovementType, ModifierId) VALUES 
('IMPROVEMENT_MER_SAUNA', 'CCB_FINLAND_UI_AMENITY_1');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_UI_AMENITY_1', 'MODIFIER_SINGLE_CITY_ADJUST_IMPROVEMENT_AMENITY', 0, 0, 0, NULL, 'BBG_TILE_IS_TUNDRA_OR_TUNDRA_HILL_REQSET');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_UI_AMENITY_1', 'Amount', '1');

DELETE FROM Improvement_Adjacencies
      WHERE YieldChangeId = 'Sauna_Camp' AND
            ImprovementType = 'IMPROVEMENT_MER_SAUNA';

UPDATE Adjacency_YieldChanges SET ObsoleteCivic='CIVIC_NATURAL_HISTORY' WHERE ID='Sauna_Woods';
INSERT INTO Adjacency_YieldChanges (
                                       Self,
                                       AdjacentResourceClass,
                                       AdjacentResource,
                                       ObsoleteTech,
                                       ObsoleteCivic,
                                       PrereqTech,
                                       PrereqCivic,
                                       AdjacentDistrict,
                                       AdjacentImprovement,
                                       AdjacentNaturalWonder,
                                       AdjacentWonder,
                                       AdjacentRiver,
                                       AdjacentFeature,
                                       AdjacentTerrain,
                                       AdjacentSeaResource,
                                       OtherDistrictAdjacent,
                                       TilesRequired,
                                       YieldChange,
                                       YieldType,
                                       Description,
                                       ID
                                   )
                                   VALUES (
                                       0,
                                       'NO_RESOURCECLASS',
                                       0,
                                       NULL,
                                       NULL,
                                       NULL,
                                       'CIVIC_NATURAL_HISTORY',
                                       NULL,
                                       NULL,
                                       0,
                                       0,
                                       0,
                                       'FEATURE_FOREST',
                                       NULL,
                                       0,
                                       0,
                                       1,
                                       1,
                                       'YIELD_CULTURE',
                                       'Placeholder',
                                       'Sauna_Woods_2'
                                   );
INSERT INTO Improvement_Adjacencies (ImprovementType, YieldChangeId) VALUES 
('IMPROVEMENT_MER_SAUNA', 'Sauna_Woods_2');

INSERT INTO ImprovementModifiers (ImprovementType, ModifierId) VALUES 
('IMPROVEMENT_MER_SAUNA', 'CCB_FINLAND_UI_CULTURE');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_UI_CULTURE', 'MODIFIER_SINGLE_PLOT_ADJUST_PLOT_YIELDS', 0, 0, 0, NULL, 'REQSET_CCB_FINLAND_UI_CULTURE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_UI_CULTURE', 'Amount', '2'), 
('CCB_FINLAND_UI_CULTURE', 'YieldType', 'YIELD_CULTURE');

INSERT INTO ImprovementModifiers (ImprovementType, ModifierId) VALUES 
('IMPROVEMENT_MER_SAUNA', 'CCB_FINLAND_UI_CULTURE_LATE');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_FINLAND_UI_CULTURE_LATE', 'MODIFIER_SINGLE_PLOT_ADJUST_PLOT_YIELDS', 0, 0, 0, 'BBG_UTILS_PLAYER_HAS_CIVIC_NATURAL_HISTORY_REQSET', 'REQSET_CCB_FINLAND_UI_CULTURE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_FINLAND_UI_CULTURE_LATE', 'Amount', '2'), 
('CCB_FINLAND_UI_CULTURE_LATE', 'YieldType', 'YIELD_CULTURE');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_FINLAND_UI_CULTURE', 'REQUIREMENTSET_TEST_ANY');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_FINLAND_UI_CULTURE', 'REQ_CCB_FINLAND_UI_CULTURE_LAKE'), 
('REQSET_CCB_FINLAND_UI_CULTURE', 'REQ_CCB_FINLAND_UI_CULTURE_RIVER'), 
('REQSET_CCB_FINLAND_UI_CULTURE', 'REQ_CCB_FINLAND_UI_CULTURE_DISTRICT_AQUEDUCT');
INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_FINLAND_UI_CULTURE_LAKE', 'REQUIREMENT_PLOT_ADJACENT_TO_LAKE'), 
('REQ_CCB_FINLAND_UI_CULTURE_RIVER', 'REQUIREMENT_PLOT_ADJACENT_TO_RIVER'), 
('REQ_CCB_FINLAND_UI_CULTURE_DISTRICT_AQUEDUCT', 'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_FINLAND_UI_CULTURE_LAKE', 'MaxDistance', '1'), 
('REQ_CCB_FINLAND_UI_CULTURE_LAKE', 'MinDistance', '1'), 
('REQ_CCB_FINLAND_UI_CULTURE_RIVER', 'MaxDistance', '1'), 
('REQ_CCB_FINLAND_UI_CULTURE_RIVER', 'MinDistance', '1'), 
('REQ_CCB_FINLAND_UI_CULTURE_DISTRICT_AQUEDUCT', 'DistrictType', 'DISTRICT_AQUEDUCT'), 
('REQ_CCB_FINLAND_UI_CULTURE_DISTRICT_AQUEDUCT', 'MaxRange', '1'), 
('REQ_CCB_FINLAND_UI_CULTURE_DISTRICT_AQUEDUCT', 'MinRange', '1');

-- ========================================================================
-- =                              TIBET                                   =
-- ========================================================================

-- Citizen may work mountain tiles that receives yields from districts within 2 tiles 
-- 		- Campus 1 Science, IZ 1 Prod, Theater 1 Culture, Hub & Harbor 1 Gold, HS Faith, City Center 2 Food
-- May purchase buildings with faith in specialty districts next to mountains.
-- Cities with an established governor receive +5% faith for each promotion that governor has.

-- Start bias
-- All mountains to 3
DELETE FROM StartBiasTerrains WHERE CivilizationType='CIVILIZATION_SUK_TIBET' AND TerrainType IN ('TERRAIN_DESERT_MOUNTAIN', 'TERRAIN_SNOW_MOUNTAIN', 'TERRAIN_TUNDRA_MOUNTAIN');
UPDATE StartBiasTerrains SET Tier=3 WHERE CivilizationType='CIVILIZATION_SUK_TIBET';

-- 2025/09/18 government faith purchase remove
DELETE FROM TraitModifiers
      WHERE TraitType = 'TRAIT_CIVILIZATION_SUK_DHARMA_KINGS' AND
            ModifierId = 'SUK_DHARMA_KINGS_DISTRICT_GOVERNMENT_FAITH_PURCHASE_MODIFIER';


-- ==========================================================
-- =                         DZONG                          =
-- ==========================================================

UPDATE ModifierArguments SET Value=5 WHERE ModifierId='SUK_DZONG_DEFENSE_STRENGTH';
UPDATE Districts SET Cost=30 WHERE DistrictType='DISTRICT_SUK_DZONG';
DELETE FROM District_ValidTerrains WHERE DistrictType='DISTRICT_SUK_DZONG';
UPDATE Districts SET Appeal=1 WHERE DistrictType='DISTRICT_SUK_DZONG';

-- ==========================================================
-- =                        RTA PA                          =
-- ==========================================================

-- 不吃支援加成

INSERT INTO TypeTags(Type, Tag) VALUES
    ('BBG_ABILITY_NO_SUPPORT_BONUS', 'CLASS_SUK_TIBET_RTA_PA');

-- removed old bunus from tundra
DELETE FROM TypeTags WHERE Type='ABILITY_CCB_TBCSJ_ADD_MOVEMENT' AND Tag='CLASS_SUK_TIBET_RTA_PA';

-- +1 movement and +3 combat when adjacent to montains
INSERT INTO Types(Type, Kind)
    VALUES ('CCB_ABILITY_RTA_PA_MOVEMENT', 'KIND_ABILITY');
INSERT INTO TypeTags(Type,Tag)
    VALUES ('CCB_ABILITY_RTA_PA_MOVEMENT', 'CLASS_SUK_TIBET_RTA_PA');
INSERT INTO UnitAbilities(UnitAbilityType, Name, Description)
    VALUES ('CCB_ABILITY_RTA_PA_MOVEMENT', 'LOC_CCB_ABILITY_RTA_PA_MOVEMENT_NAME','LOC_CCB_ABILITY_RTA_PA_MOVEMENT_DESCRIPTION');

INSERT INTO Types(Type, Kind)
    VALUES ('CCB_ABILITY_RTA_PA_CS', 'KIND_ABILITY');
INSERT INTO TypeTags(Type,Tag)
    VALUES ('CCB_ABILITY_RTA_PA_CS', 'CLASS_SUK_TIBET_RTA_PA');
INSERT INTO UnitAbilities(UnitAbilityType, Name, Description)
    VALUES ('CCB_ABILITY_RTA_PA_CS', 'LOC_CCB_ABILITY_RTA_PA_CS_NAME','LOC_CCB_ABILITY_RTA_PA_CS_DESCRIPTION');

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES 
('CCB_ABILITY_RTA_PA_MOVEMENT', 'CCB_RTA_PA_MOVEMENT');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_RTA_PA_MOVEMENT', 'MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT', 0, 0, 0, NULL, 'CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_RTA_PA_MOVEMENT', 'Amount', '1');

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES 
('CCB_ABILITY_RTA_PA_CS', 'CCB_RTA_PA_CS');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_RTA_PA_CS', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 0, 0, 0, NULL, 'CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_RTA_PA_CS', 'Amount', '3');

INSERT INTO ModifierStrings(ModifierId, Context, Text) VALUES
    ('CCB_RTA_PA_CS', 'Preview', 'LOC_CCB_RTA_PA_CS');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS', 'REQUIREMENTSET_TEST_ANY');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS', 'CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_DESERT_MOUNTAIN'), 
('CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS', 'CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_GRASS_MOUNTAIN'),
('CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS', 'CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_PLAINS_MOUNTAIN'),
('CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS', 'CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_SNOW_MOUNTAIN'),
('CCB_REQSET_UNIT_IS_ADJACENT_MOUNTAINS', 'CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_TUNDRA_MOUNTAIN');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_DESERT_MOUNTAIN', 'REQUIREMENT_PLOT_ADJACENT_TERRAIN_TYPE_MATCHES'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_GRASS_MOUNTAIN', 'REQUIREMENT_PLOT_ADJACENT_TERRAIN_TYPE_MATCHES'),
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_PLAINS_MOUNTAIN', 'REQUIREMENT_PLOT_ADJACENT_TERRAIN_TYPE_MATCHES'),
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_SNOW_MOUNTAIN', 'REQUIREMENT_PLOT_ADJACENT_TERRAIN_TYPE_MATCHES'),
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_TUNDRA_MOUNTAIN', 'REQUIREMENT_PLOT_ADJACENT_TERRAIN_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_DESERT_MOUNTAIN', 'TerrainType', 'TERRAIN_DESERT_MOUNTAIN'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_DESERT_MOUNTAIN', 'MinRange', '0'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_DESERT_MOUNTAIN', 'MaxRange', '1'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_GRASS_MOUNTAIN', 'TerrainType', 'TERRAIN_GRASS_MOUNTAIN'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_GRASS_MOUNTAIN', 'MinRange', '0'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_GRASS_MOUNTAIN', 'MaxRange', '1'),
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_PLAINS_MOUNTAIN', 'TerrainType', 'TERRAIN_PLAINS_MOUNTAIN'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_PLAINS_MOUNTAIN', 'MinRange', '0'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_PLAINS_MOUNTAIN', 'MaxRange', '1'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_SNOW_MOUNTAIN', 'TerrainType', 'TERRAIN_SNOW_MOUNTAIN'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_SNOW_MOUNTAIN', 'MinRange', '0'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_SNOW_MOUNTAIN', 'MaxRange', '1'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_TUNDRA_MOUNTAIN', 'TerrainType', 'TERRAIN_TUNDRA_MOUNTAIN'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_TUNDRA_MOUNTAIN', 'MinRange', '0'), 
('CCB_REQ_UNIT_IS_ADJACENT_TERRAIN_TUNDRA_MOUNTAIN', 'MaxRange', '1');

-- ========================================================================
-- =                             TRISONG                                  =
-- ========================================================================

DELETE FROM TraitModifiers WHERE ModifierId='SUK_CAPTURE_OF_CHANGAN_GREAT_GENERAL_POINTS';

-- Land combat units in cities with a temple and an encampment get a free promotion (from worship building)
-- 17/08/25: free promotion is only granted if the city has a worship building
-- INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
-- 	('BBG_CITY_HAS_TEMPLE_AND_ENCAMPMENT_REQSET', 'REQUIREMENTSET_TEST_ALL');
-- INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
-- 	('BBG_CITY_HAS_TEMPLE_AND_ENCAMPMENT_REQSET', 'SUK_CAPTURE_OF_CHANGAN_HAS_DZONG'),
-- 	('BBG_CITY_HAS_TEMPLE_AND_ENCAMPMENT_REQSET', 'REQUIRES_CITY_HAS_ENCAMPMENT'),
-- 	('BBG_CITY_HAS_TEMPLE_AND_ENCAMPMENT_REQSET', 'REQUIRES_CITY_HAS_TEMPLE');
-- UPDATE Modifiers SET SubjectRequirementSetId='BBG_CITY_HAS_TEMPLE_AND_ENCAMPMENT_REQSET' WHERE ModifierId='SUK_CAPTURE_OF_CHANGAN_FREE_PROMOTION';

-- Get 1 governor title  when funding a religion
-- 17/08/25: no longer grants a free governor title upon founding a religion
-- INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
-- 	('BBG_TRISONG_GOVERNOR_RELIGION', 'MODIFIER_PLAYER_ADJUST_GOVERNOR_POINTS', 'BBG_PLAYER_FOUNDED_RELIGION_REQSET');
-- INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
-- 	('BBG_TRISONG_GOVERNOR_RELIGION', 'Delta', 1);
-- INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
-- 	('TRAIT_LEADER_SUK_CAPTURE_OF_CHANGAN', 'BBG_TRISONG_GOVERNOR_RELIGION');
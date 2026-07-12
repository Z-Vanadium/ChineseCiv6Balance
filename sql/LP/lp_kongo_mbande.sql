-- 18/06/23 Remove old modifier for same/foreign continent
DELETE FROM TraitModifiers WHERE TraitType='TRAIT_LEADER_NZINGA_MBANDE' AND ModifierId='TRAIT_SAME_CONTINENT_YIELD';
DELETE FROM TraitModifiers WHERE TraitType='TRAIT_LEADER_NZINGA_MBANDE' AND ModifierId='TRAIT_FOREIGN_CONTINENT_YIELD';

INSERT OR IGNORE INTO Requirements(RequirementId, RequirementType) VALUES
	('REQUIRES_OBJECT_1_OR_MORE_TILES_FROM_CAPITAL','REQUIREMENT_PLOT_NEAR_CAPITAL');
INSERT OR IGNORE INTO RequirementArguments(RequirementId, Name, Value) VALUES
	('REQUIRES_OBJECT_1_OR_MORE_TILES_FROM_CAPITAL', 'MinDistance', '1');

--Disabling Mbande's effect on the capital city
INSERT INTO RequirementSetRequirements(RequirementSetId, RequirementId) VALUES
	('REQUIRES_CITY_IS_SAME_CONTINENT', 'REQUIRES_OBJECT_1_OR_MORE_TILES_FROM_CAPITAL');

-- 2026/06/02 removed
-- 18/06/23 Mbande gets +2 golds for commercial hubs adjacent to Mbanza
-- INSERT INTO Adjacency_YieldChanges (ID, Description, YieldType, YieldChange, AdjacentDistrict) VALUES
--     ('BBG_MBANDE_COMMERCIAL_HUB_MBANZA', 'BBG_LOC_MBANDE_COMMERCIAL_MBANZA', 'YIELD_GOLD', 2, 'DISTRICT_MBANZA');
-- INSERT INTO District_Adjacencies (DistrictType, YieldChangeId) VALUES
--     ('DISTRICT_COMMERCIAL_HUB', 'BBG_MBANDE_COMMERCIAL_HUB_MBANZA');
-- INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId)
--    SELECT TraitType, 'BBG_MBANDE_COMMERCIAL_HUB_MBANZA' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_KONGO' GROUP BY CivilizationType;
-- INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId) VALUES
-- 	('TRAIT_LEADER_RELIGIOUS_CONVERT', 'BBG_MBANDE_COMMERCIAL_HUB_MBANZA');

-- 18/06/23 Mbande gets +2 cultures for theatres adjacent to Mbanza
-- INSERT INTO Adjacency_YieldChanges (ID, Description, YieldType, YieldChange, AdjacentDistrict) VALUES
--     ('BBG_MBANDE_THEATRE_MBANZA', 'BBG_LOC_MBANDE_THEATRE_MBANZA', 'YIELD_CULTURE', 2, 'DISTRICT_MBANZA');
-- INSERT INTO District_Adjacencies (DistrictType, YieldChangeId) VALUES
--     ('DISTRICT_THEATER', 'BBG_MBANDE_THEATRE_MBANZA');
-- INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId)
--    SELECT TraitType, 'BBG_MBANDE_THEATRE_MBANZA' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_KONGO' GROUP BY CivilizationType;
-- INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId) VALUES
-- 	('TRAIT_LEADER_RELIGIOUS_CONVERT', 'BBG_MBANDE_THEATRE_MBANZA');
    
-- 18/06/23 Mbande gets +10% culture & gold in cities with Mbanza
INSERT INTO Requirements (RequirementId, RequirementType) VALUES
    ('BBG_REQUIREMENT_CITY_HAS_MBANZA', 'REQUIREMENT_CITY_HAS_DISTRICT');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
    ('BBG_REQUIREMENT_CITY_HAS_MBANZA', 'DistrictType', 'DISTRICT_MBANZA');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
    ('BBG_CITY_HAS_MBANZA', 'REQUIREMENTSET_TEST_ANY');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
    ('BBG_CITY_HAS_MBANZA', 'BBG_REQUIREMENT_CITY_HAS_MBANZA');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('BBG_MODIFIER_MBANZA_ADDCULTUREYIELD', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER', 'BBG_CITY_HAS_MBANZA'),
    ('BBG_MODIFIER_MBANZA_ADDGOLDYIELD', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER', 'BBG_CITY_HAS_MBANZA');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_MODIFIER_MBANZA_ADDCULTUREYIELD', 'Amount', '10'),
    ('BBG_MODIFIER_MBANZA_ADDGOLDYIELD', 'Amount', '10');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_MODIFIER_MBANZA_ADDCULTUREYIELD', 'YieldType', 'YIELD_CULTURE'),
    ('BBG_MODIFIER_MBANZA_ADDGOLDYIELD', 'YieldType', 'YIELD_GOLD');
INSERT INTO TraitModifiers(TraitType, ModifierId) VALUES
	('TRAIT_LEADER_NZINGA_MBANDE', 'BBG_MODIFIER_MBANZA_ADDCULTUREYIELD'),
	('TRAIT_LEADER_NZINGA_MBANDE', 'BBG_MODIFIER_MBANZA_ADDGOLDYIELD');

-- 05/03/2024
-- Mbande civilian units get forest and jungle free movement
INSERT INTO Modifiers(ModifierId, ModifierType) VALUES
    ('BBG_CIVILIAN_UNITS_IGNORE_WOODS', 'MODIFIER_PLAYER_UNITS_GRANT_ABILITY');
INSERT INTO ModifierArguments(ModifierId, Name, Value) VALUES
    ('BBG_CIVILIAN_UNITS_IGNORE_WOODS', 'AbilityType', 'BBG_IGNORE_WOODS_MBANDE_ABILITY');
INSERT INTO TraitModifiers(TraitType, ModifierId) VALUES
    ('TRAIT_LEADER_NZINGA_MBANDE', 'BBG_CIVILIAN_UNITS_IGNORE_WOODS');

INSERT INTO Types(Type, Kind) VALUES
    ('BBG_IGNORE_WOODS_MBANDE_ABILITY', 'KIND_ABILITY');
INSERT INTO TypeTags(Type, Tag) VALUES
    ('BBG_IGNORE_WOODS_MBANDE_ABILITY', 'CLASS_LANDCIVILIAN');

INSERT INTO UnitAbilities(UnitAbilityType, Name, Description, Inactive, ShowFloatTextWhenEarned, Permanent)  VALUES
    ('BBG_IGNORE_WOODS_MBANDE_ABILITY', 'LOC_BBG_IGNORE_WOODS_MBANDE_ABILITY_NAME', 'LOC_BBG_IGNORE_WOODS_MBANDE_ABILITY_DESCRIPTION', 1, 0, 1);
INSERT INTO UnitAbilityModifiers(UnitAbilityType, ModifierId) VALUES
    ('BBG_IGNORE_WOODS_MBANDE_ABILITY', 'RANGER_IGNORE_FOREST_MOVEMENT_PENALTY');


-- 18/06/23 Reduced archaelogist cost for Mbande
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
    ('BBG_TRAIT_ARCHAEOLOGIST_COST', 'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PURCHASE_COST');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_TRAIT_ARCHAEOLOGIST_COST', 'UnitType', 'UNIT_ARCHAEOLOGIST'),
    ('BBG_TRAIT_ARCHAEOLOGIST_COST', 'Amount', '50');
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
    ('TRAIT_LEADER_NZINGA_MBANDE', 'BBG_TRAIT_ARCHAEOLOGIST_COST');

-- 2026/06/02 market +1 gpp
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_NZINGA_MBANDE', 'CCB_KONGO_MERCHANT_GPP');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_KONGO_MERCHANT_GPP', 'MODIFIER_PLAYER_CITIES_ADJUST_GREAT_PERSON_POINT', 0, 0, 0, NULL, 'BUILDING_IS_MARKET');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_KONGO_MERCHANT_GPP', 'Amount', '1'), 
('CCB_KONGO_MERCHANT_GPP', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_MERCHANT');

-- +50% theatre gpp from civ ua
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_NZINGA_MBANDE', 'TRAIT_DOUBLE_ARTIST_POINTS'),
('TRAIT_LEADER_NZINGA_MBANDE', 'TRAIT_DOUBLE_MUSICIAN_POINTS'),
('TRAIT_LEADER_NZINGA_MBANDE', 'TRAIT_DOUBLE_WRITER_POINTS');

-- 2026/07/12 移除商业中心和剧院广场从树林或雨林获得少量相邻加成；新增商业中心和剧院广场互给+1；新增拥有姆班赞的城市，在“⻜行”科技后每个区域提供 +2 旅游业绩
INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, AdjacentDistrict) VALUES
    ('CCB_CH_Kongo_Theater', 'LOC_CCB_CH_KONGO_THEATER_ADJACENCY', 'YIELD_GOLD', 1, 'DISTRICT_THEATER'),
    ('CCB_Theater_Kongo_CH', 'LOC_CCB_THEATER_KONGO_CH_ADJACENCY', 'YIELD_CULTURE', 1, 'DISTRICT_COMMERCIAL_HUB');
INSERT INTO District_Adjacencies(DistrictType, YieldChangeId) VALUES
    ('DISTRICT_COMMERCIAL_HUB', 'CCB_CH_Kongo_Theater'),
    ('DISTRICT_THEATER', 'CCB_Theater_Kongo_CH');
INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId)
    SELECT TraitType, 'CCB_CH_Kongo_Theater' FROM LeaderTraits WHERE (LeaderType != 'LEADER_NZINGA_MBANDE' AND LeaderType != 'LEADER_DEFAULT') GROUP BY LeaderType;
INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId)
    SELECT TraitType, 'CCB_Theater_Kongo_CH' FROM LeaderTraits WHERE (LeaderType != 'LEADER_NZINGA_MBANDE' AND LeaderType != 'LEADER_DEFAULT') GROUP BY LeaderType;

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_NZINGA_MBANDE', 'CCB_MBANDE_TOURISM_PER_DISTRICT');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_MBANDE_TOURISM_PER_DISTRICT', 'MODIFIER_PLAYER_DISTRICTS_ADJUST_TOURISM_CHANGE', 0, 0, 0, 'BBG_UTILS_PLAYER_HAS_TECH_FLIGHT', 'BBG_CITY_HAS_DISTRICT_MBANZA');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_MBANDE_TOURISM_PER_DISTRICT', 'Amount', '2');
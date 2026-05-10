
UPDATE GlobalParameters SET Value=2 WHERE Name='FORTIFY_BONUS_PER_TURN';

-- 2026/02/26 loyalty after transferred by combat before occupation increased to 75 (from 50)
UPDATE GlobalParameters SET Value=75 WHERE Name='LOYALTY_AFTER_TRANSFERRED_BY_COMBAT_OWNER_BEFORE_OCCUPATION';

UPDATE GlobalParameters SET Value=0.5 WHERE Name='TRADE_ROUTE_TRANSPORTATION_EFFICIENCY_MAX_RATIO';



-- 27/02/25 Combat RNG removed (base damage was 24, and max extra 12, meaning extra damage could go from 24 to 36)
UPDATE GlobalParameters SET Value=0 WHERE Name='COMBAT_MAX_EXTRA_DAMAGE';
UPDATE GlobalParameters SET Value=30 WHERE Name='COMBAT_BASE_DAMAGE';

--==============================================================
--******				S  C  O  R  E				  	  ******
--==============================================================
-- more points for techs and civics
UPDATE ScoringLineItems SET Multiplier=4 WHERE LineItemType='LINE_ITEM_CIVICS';
UPDATE ScoringLineItems SET Multiplier=3 WHERE LineItemType='LINE_ITEM_TECHS';
-- less points for wide, more for tall
UPDATE ScoringLineItems SET Multiplier=2 WHERE LineItemType='LINE_ITEM_CITIES';
UPDATE ScoringLineItems SET Multiplier=2 WHERE LineItemType='LINE_ITEM_POPULATION';
-- Wonders Provide +4 score instead of +15
UPDATE ScoringLineItems SET Multiplier=4 WHERE LineItemType='LINE_ITEM_WONDERS';
-- Great People worth only 3 instead of 5
UPDATE ScoringLineItems SET Multiplier=3 WHERE LineItemType='LINE_ITEM_GREAT_PEOPLE';
-- converting foreign populations reduced from 2 to 1
UPDATE ScoringLineItems SET Multiplier=1 WHERE LineItemType='LINE_ITEM_ERA_CONVERTED';



--==============================================================
--******				START BIASES					  ******
--==============================================================
-- Update Start Bias
UPDATE StartBiasRivers SET Tier=3 WHERE CivilizationType='CIVILIZATION_GERMANY';

-- t1 take up essential coastal spots first
UPDATE StartBiasTerrains SET Tier=1 WHERE CivilizationType='CIVILIZATION_ENGLAND' AND TerrainType='TERRAIN_COAST';
UPDATE StartBiasTerrains SET Tier=1 WHERE CivilizationType='CIVILIZATION_NORWAY' AND TerrainType='TERRAIN_COAST';
UPDATE StartBiasTerrains SET Tier=1 WHERE CivilizationType='CIVILIZATION_JAPAN' AND TerrainType='TERRAIN_COAST';
UPDATE StartBiasTerrains SET Tier=1 WHERE CivilizationType='CIVILIZATION_RUSSIA' AND TerrainType='TERRAIN_TUNDRA_HILLS';
UPDATE StartBiasTerrains SET Tier=1 WHERE CivilizationType='CIVILIZATION_RUSSIA' AND TerrainType='TERRAIN_TUNDRA';
-- t2 must haves
UPDATE StartBiasFeatures SET Tier=2 WHERE CivilizationType='CIVILIZATION_BRAZIL' AND FeatureType='FEATURE_JUNGLE';
-- t3 identities
UPDATE StartBiasResources SET Tier=3 WHERE CivilizationType='CIVILIZATION_SCYTHIA' AND ResourceType='RESOURCE_HORSES';
-- t4 river mechanics
-- UPDATE StartBiasRivers SET Tier=4 WHERE CivilizationType='CIVILIZATION_SUMERIA';
UPDATE StartBiasRivers SET Tier=4 WHERE CivilizationType='CIVILIZATION_FRANCE';
-- t4 feature mechanics
UPDATE StartBiasFeatures SET Tier=3 WHERE CivilizationType='CIVILIZATION_KONGO' AND FeatureType='FEATURE_JUNGLE';
-- t4 terrain mechanics
UPDATE StartBiasTerrains SET Tier=4 WHERE CivilizationType='CIVILIZATION_GREECE' AND TerrainType='TERRAIN_GRASS_HILLS';
UPDATE StartBiasTerrains SET Tier=4 WHERE CivilizationType='CIVILIZATION_GREECE' AND TerrainType='TERRAIN_PLAINS_HILLS';
-- t4 resource mechanics
INSERT OR IGNORE INTO StartBiasResources (CivilizationType , ResourceType , Tier) VALUES
	('CIVILIZATION_SCYTHIA' , 'RESOURCE_SHEEP'  , 4),
	('CIVILIZATION_SCYTHIA' , 'RESOURCE_CATTLE' , 4);
-- t5 last resorts
UPDATE StartBiasFeatures SET Tier=5 WHERE CivilizationType='CIVILIZATION_KONGO' AND FeatureType='FEATURE_FOREST';
UPDATE StartBiasFeatures SET Tier=5 WHERE CivilizationType='CIVILIZATION_EGYPT' AND FeatureType='FEATURE_FLOODPLAINS';
-- Delete bad bias
DELETE FROM StartBiasTerrains WHERE CivilizationType='CIVILIZATION_GREECE' AND TerrainType IN ('TERRAIN_TUNDRA_HILLS', 'TERRAIN_DESERT_HILLS');


--==============================================================
--******				    O T H E R					  ******
--==============================================================
-- 2025/12/09 Olives, salt +1 gold; coffee, tabbaco no longer spawn without feature; amber +1 food in water (when the plot belongs to any civ)
INSERT OR REPLACE INTO Resource_YieldChanges (ResourceType, YieldType, YieldChange) VALUES
    ('RESOURCE_OLIVES', 'YIELD_GOLD', 2),
    ('RESOURCE_SALT', 'YIELD_GOLD', 2);
DELETE FROM Resource_ValidTerrains
      WHERE ResourceType = 'RESOURCE_TOBACCO' AND
            TerrainType IN ('TERRAIN_GRASS', 'TERRAIN_PLAINS');
DELETE FROM Resource_ValidTerrains
      WHERE ResourceType = 'RESOURCE_COFFEE' AND
            TerrainType = 'TERRAIN_GRASS';

INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES 
('TRAIT_LEADER_MAJOR_CIV', 'CCB_AMBER_FOOD_WATER');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_AMBER_FOOD_WATER', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_AMBER_WATER');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_AMBER_FOOD_WATER', 'Amount', '1'), 
('CCB_AMBER_FOOD_WATER', 'YieldType', 'YIELD_FOOD');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_PLOT_IS_AMBER_WATER', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_PLOT_IS_AMBER_WATER', 'REQ_CCB_PLOT_IS_AMBER'), 
('REQSET_CCB_PLOT_IS_AMBER_WATER', 'REQ_CCB_PLOT_IS_WATER');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_PLOT_IS_AMBER', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'), 
('REQ_CCB_PLOT_IS_WATER', 'REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_PLOT_IS_AMBER', 'ResourceType', 'RESOURCE_AMBER'), 
('REQ_CCB_PLOT_IS_WATER', 'TerrainType', 'TERRAIN_COAST');

-- 2025/10/05 horses can be found on tundra plain
INSERT OR IGNORE INTO Resource_ValidTerrains (ResourceType, TerrainType) VALUES
    ('RESOURCE_HORSES', 'TERRAIN_TUNDRA');

-- oil can be found on flat plains
INSERT OR IGNORE INTO Resource_ValidTerrains (ResourceType, TerrainType) VALUES
    ('RESOURCE_OIL', 'TERRAIN_PLAINS');
-- incense +1 food
-- mercury +1 food
-- spice -1 food +1 gold
-- 02/07/24 Jade +1 prod (can no longer spawn on plains)
-- 29/03/25 Cotton +4 gold Marble +1 faith (still as +1 culture)
INSERT OR IGNORE INTO Resource_YieldChanges (ResourceType, YieldType, YieldChange) VALUES
	('RESOURCE_INCENSE', 'YIELD_FOOD', 1),
	('RESOURCE_MERCURY', 'YIELD_FOOD', 1),
    ('RESOURCE_JADE', 'YIELD_PRODUCTION', 1),
	('RESOURCE_SPICES', 'YIELD_GOLD', 1),
    ('RESOURCE_TEA', 'YIELD_FOOD', 1),
    ('RESOURCE_PEARLS', 'YIELD_PRODUCTION', 1),
    ('RESOURCE_MARBLE', 'YIELD_GOLD', 2);
UPDATE Resource_YieldChanges SET YieldChange=1 WHERE ResourceType='RESOURCE_SPICES' AND YieldType='YIELD_FOOD';
UPDATE Resource_YieldChanges SET YieldChange=4 WHERE ResourceType='RESOURCE_COTTON' AND YieldType='YIELD_GOLD';
DELETE FROM Resource_ValidTerrains WHERE ResourceType='RESOURCE_JADE' AND TerrainType='TERRAIN_PLAINS';
-- 26/02/25 diamonds/cocoa to 2 gold
UPDATE Resource_YieldChanges SET YieldChange=2 WHERE ResourceType IN ('RESOURCE_COCOA', 'RESOURCE_DIAMONDS') AND YieldType='YIELD_GOLD';

-- add 1 production to fishing boat improvement
UPDATE Improvement_YieldChanges SET YieldChange=1 WHERE ImprovementType='IMPROVEMENT_FISHING_BOATS' AND YieldType='YIELD_PRODUCTION';

-- 09/03/2024 +1 housing to fishery
UPDATE Improvements SET Housing=2 WHERE ImprovementType='IMPROVEMENT_FISHERY';

-- Harbor gives 1 housing [Lighthouse loses 1]
UPDATE Buildings SET Housing=0 WHERE BuildingType='BUILDING_LIGHTHOUSE';
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('BBG_HARBOR_HOUSING', 'MODIFIER_CITY_DISTRICTS_ADJUST_DISTRICT_HOUSING', 'BBG_DISTRICT_IS_DISTRICT_HARBOR_REQSET');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_HARBOR_HOUSING', 'Amount', 1);
INSERT INTO DistrictModifiers (DistrictType, ModifierId) VALUES
    ('DISTRICT_HARBOR', 'BBG_HARBOR_HOUSING');

-- lighthouse housing only on coastal city (exclude lake)
UPDATE Modifiers SET SubjectRequirementSetId='PLOT_IS_COASTAL_LAND_REQUIREMENTS' WHERE ModifierId='LIGHTHOUSE_COASTAL_CITY_HOUSING';

-- 2026/02/26 amphitheater: prod cost reduced to 60 (from 75), culture yield increased to +3 (from +2)
UPDATE Buildings SET Cost='120' WHERE BuildingType='BUILDING_AMPHITHEATER';
UPDATE Building_YieldChanges SET YieldChange='3' WHERE BuildingType='BUILDING_AMPHITHEATER' AND YieldType='YIELD_CULTURE';

-- Citizen specialists give +1 main yield
-- 2025/12/08 CH bonus to +6/+9
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_CULTURE' AND DistrictType='DISTRICT_ACROPOLIS';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_SCIENCE' AND DistrictType='DISTRICT_CAMPUS';
UPDATE District_CitizenYieldChanges SET YieldChange=6 WHERE YieldType='YIELD_GOLD' AND DistrictType='DISTRICT_COMMERCIAL_HUB';
UPDATE District_CitizenYieldChanges SET YieldChange=2 WHERE YieldType='YIELD_PRODUCTION' AND DistrictType='DISTRICT_ENCAMPMENT';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_PRODUCTION' AND DistrictType='DISTRICT_HANSA';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_GOLD' AND DistrictType='DISTRICT_HARBOR';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_FAITH' AND DistrictType='DISTRICT_HOLY_SITE';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_PRODUCTION' AND DistrictType='DISTRICT_INDUSTRIAL_ZONE';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_FAITH' AND DistrictType='DISTRICT_LAVRA';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_GOLD' AND DistrictType='DISTRICT_ROYAL_NAVY_DOCKYARD';
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_CULTURE' AND DistrictType='DISTRICT_THEATER';

UPDATE Building_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_GOLD' AND BuildingType='BUILDING_STOCK_EXCHANGE';

-- Free amenity on new city
UPDATE GlobalParameters SET Value=1 WHERE Name='CITY_AMENITIES_FOR_FREE';
UPDATE Buildings SET Entertainment=1 WHERE BuildingType='BUILDING_PALACE';

-- 2026/04/23: fishing boats on reef after cartography
INSERT OR IGNORE INTO Improvement_ValidFeatures (ImprovementType, FeatureType, PrereqTech) VALUES
    ('IMPROVEMENT_FISHING_BOATS', 'FEATURE_REEF', 'TECH_CARTOGRAPHY');
-- Seaside Ressort buildable on hills
INSERT INTO Improvement_ValidTerrains(ImprovementType, TerrainType) VALUES
    ('IMPROVEMENT_BEACH_RESORT', 'TERRAIN_GRASS_HILLS'),
    ('IMPROVEMENT_BEACH_RESORT', 'TERRAIN_PLAINS_HILLS'),
    ('IMPROVEMENT_BEACH_RESORT', 'TERRAIN_DESERT_HILLS');
-- 12/06/23 Beach Resort can be built on appealling tiles
UPDATE Improvements SET MinimumAppeal=2 WHERE ImprovementType='IMPROVEMENT_BEACH_RESORT';
-- 15/06/23 Beach resort get gold double the appeal and tourism based on that
-- 30/09/24 from *2 to *1.5
UPDATE Improvement_Tourism SET TourismSource='TOURISMSOURCE_GOLD' WHERE ImprovementType='IMPROVEMENT_BEACH_RESORT';
UPDATE Improvements SET YieldFromAppealPercent=150 WHERE ImprovementType='IMPROVEMENT_BEACH_RESORT';


-- 12/06/23 Fix tourism at flight on some improvement
INSERT OR IGNORE INTO Improvement_Tourism(ImprovementType, TourismSource, PrereqTech)
    SELECT Improvements.ImprovementType, 'TOURISMSOURCE_CULTURE', 'TECH_FLIGHT' From Improvements WHERE ImprovementType IN ('IMPROVEMENT_FARM', 'IMPROVEMENT_QUARRY', 'IMPROVEMENT_CAMP', 'IMPROVEMENT_FISHING_BOATS', 'IMPROVEMENT_LUMBER_MILL', 'IMPROVEMENT_OIL_WELL', 'IMPROVEMENT_OFFSHORE_OIL_RIG');

-- 14/10/23 Lumber mill yield changes come earlier (steel to balistics and cybernetics to synthetics material)
UPDATE Improvement_BonusYieldChanges SET PrereqTech='TECH_BALLISTICS' WHERE Id=5;
UPDATE Technologies SET Description='BBG_LOC_TECH_BALLISTICS_DESCRIPTION' WHERE TechnologyType='TECH_BALLISTICS';
UPDATE Improvement_BonusYieldChanges SET PrereqTech='TECH_SYNTHETIC_MATERIALS' WHERE Id=227;

-- 14/10/23 Quarry yield changes come earlier (predictive systems to rocketry, so +2 rocketery, and gunpowder to military engineering)
UPDATE Improvement_BonusYieldChanges SET PrereqTech='TECH_MILITARY_ENGINEERING' WHERE Id=230;
UPDATE Technologies SET Description='BBG_LOC_TECH_MILITARY_ENGINEERING_DESCRIPTION' WHERE TechnologyType='TECH_MILITARY_ENGINEERING';
UPDATE Improvement_BonusYieldChanges SET BonusYieldChange=2 WHERE Id=13;
DELETE FROM Improvement_BonusYieldChanges WHERE Id=231;
UPDATE Technologies SET Description=NULL WHERE TechnologyType='TECH_PREDICTIVE_SYSTEMS';

--****		REQUIREMENTS		****--
INSERT OR IGNORE INTO Requirements
	(RequirementId , RequirementType)
	VALUES
	('PLAYER_HAS_MEDIEVAL_FAIRES_CPLMOD', 'REQUIREMENT_PLAYER_HAS_CIVIC'),
	('PLAYER_HAS_URBANIZATION_CPLMOD', 'REQUIREMENT_PLAYER_HAS_CIVIC'),
	('PLAYER_HAS_BANKING_CPLMOD', 'REQUIREMENT_PLAYER_HAS_TECHNOLOGY'),
	('PLAYER_HAS_ECONOMICS_CPLMOD', 'REQUIREMENT_PLAYER_HAS_TECHNOLOGY');
INSERT OR IGNORE INTO RequirementArguments
	(RequirementId , Name , Value)
	VALUES
	('PLAYER_HAS_MEDIEVAL_FAIRES_CPLMOD', 'CivicType', 'CIVIC_MEDIEVAL_FAIRES'  ),
	('PLAYER_HAS_URBANIZATION_CPLMOD', 'CivicType', 'CIVIC_URBANIZATION'),
	('PLAYER_HAS_BANKING_CPLMOD', 'TechnologyType', 'TECH_BANKING'  ),
	('PLAYER_HAS_ECONOMICS_CPLMOD', 'TechnologyType', 'TECH_ECONOMICS');

-- This is simply a visual change which makes the tech paths slighly more understandable (the dotted lines)
-- UPDATE Technologies SET UITreeRow=-3 WHERE TechnologyType='TECH_INDUSTRIALIZATION';


--Removing any Extra Yields Mechanism
/*
CREATE TABLE Numbers(Number INT NOT NULL);
INSERT INTO Numbers VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15);

INSERT INTO Requirements(RequirementId, RequirementType)
    SELECT 'REQ_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'REQUIREMENT_PLOT_PROPERTY_MATCHES'
    FROM Numbers LEFT JOIN Yields;
INSERT INTO RequirementArguments(RequirementId, Name, Value)
    SELECT 'REQ_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'PropertyName', 'EXTRA_'||Yields.YieldType
    FROM Numbers LEFT JOIN Yields;
INSERT INTO RequirementArguments(RequirementId, Name, Value)
    SELECT 'REQ_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'PropertyMinimum', Numbers.Number
    FROM Numbers LEFT JOIN Yields;
INSERT INTO RequirementSets(RequirementSetId, RequirementSetType)
    SELECT 'REQSET_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'REQUIREMENTSET_TEST_ALL'
    FROM Numbers LEFT JOIN Yields;
INSERT INTO RequirementSetRequirements(RequirementSetId, RequirementId)
    SELECT 'REQSET_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'REQ_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG'
    FROM Numbers LEFT JOIN Yields;
INSERT INTO Modifiers(ModifierId, ModifierType, SubjectRequirementSetId)
    SELECT 'MODIFIER_CITY_REMOVE_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 'REQSET_PLOT_HAS_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG'
    FROM Numbers LEFT JOIN Yields;
INSERT INTO ModifierArguments(ModifierId, Name, Value)
    SELECT 'MODIFIER_CITY_REMOVE_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'YieldType', Yields.YieldType
    FROM Numbers LEFT JOIN Yields;
INSERT INTO ModifierArguments(ModifierId, Name, Value)
    SELECT 'MODIFIER_CITY_REMOVE_'||Numbers.Number||'_EXTRA_'||Yields.YieldType||'_BBG', 'Amount', -1
    FROM Numbers LEFT JOIN Yields;
INSERT INTO Modifiers(ModifierId, ModifierType)
    SELECT 'MODIFIER_CIV_CITIES_REMOVE_EXTRA_'||Numbers.Number||'_'||Yields.YieldType||'_BBG', 'MODIFIER_PLAYER_CITIES_ATTACH_MODIFIER'
    FROM Numbers LEFT JOIN Yields;
INSERT INTO ModifierArguments(ModifierId, Name, Value)
    SELECT 'MODIFIER_CIV_CITIES_REMOVE_EXTRA_'||Numbers.Number||'_'||Yields.YieldType||'_BBG', 'ModifierId', 'MODIFIER_CITY_REMOVE_EXTRA_'||Numbers.Number||'_'||Yields.YieldType||'_BBG'
    FROM Numbers LEFT JOIN Yields;

INSERT INTO TraitModifiers(TraitType, ModifierId)
    SELECT 'TRAIT_LEADER_MAJOR_CIV', 'MODIFIER_CIV_CITIES_REMOVE_EXTRA_'||Numbers.Number||'_'||Yields.YieldType||'_BBG'
    FROM Numbers LEFT JOIN Yields;
INSERT INTO TraitModifiers(TraitType, ModifierId)
    SELECT 'MINOR_CIV_DEFAULT_TRAIT', 'MODIFIER_CIV_CITIES_REMOVE_EXTRA_'||Numbers.Number||'_'||Yields.YieldType||'_BBG'
    FROM Numbers LEFT JOIN Yields;
DROP TABLE Numbers;
*/



--=======================================================================
--******               Wonder+Terrain/Feature                      ******
--=======================================================================

INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentFeature)
	SELECT 
       'Mountain_Science'||(SELECT COUNT(*)+5
        FROM (SELECT WonderType AS t2 FROM WonderTerrainFeature_BBG  WHERE TerrainClassType = 'TERRAIN_CLASS_MOUNTAIN')
        WHERE t2<= t1.WonderType), 'LOC_CAMPUS_MOUNTAIN_WONDER_ADJACENCY_BBG', 'YIELD_SCIENCE', 1, 1, t1.WonderType
FROM WonderTerrainFeature_BBG AS t1
WHERE t1.TerrainClassType = 'TERRAIN_CLASS_MOUNTAIN'
ORDER BY WonderType;
INSERT OR IGNORE INTO District_Adjacencies
	SELECT 
       'DISTRICT_CAMPUS', 'Mountain_Science'||(SELECT COUNT(*)+5
        FROM (SELECT WonderType AS t2 FROM WonderTerrainFeature_BBG  WHERE TerrainClassType = 'TERRAIN_CLASS_MOUNTAIN')
        WHERE t2<= t1.WonderType)
FROM WonderTerrainFeature_BBG AS t1
WHERE t1.TerrainClassType = 'TERRAIN_CLASS_MOUNTAIN'
ORDER BY WonderType;

--lake
UPDATE OR IGNORE Features SET AddsFreshWater = 1, Lake = 1 
	WHERE FeatureType IN (SELECT WonderType FROM WonderTerrainFeature_BBG WHERE Other = 'LAKE');
--oasis
UPDATE OR IGNORE Features SET AddsFreshWater = 1
	WHERE FeatureType IN (SELECT WonderType FROM WonderTerrainFeature_BBG WHERE FeatureType = 'FEATURE_OASIS');
--Defense Modifier
UPDATE OR IGNORE Features SET MovementChange=1,DefenseModifier = -2
	WHERE FeatureType IN (SELECT WonderType FROM WonderTerrainFeature_BBG WHERE FeatureType = 'FEATURE_MARSH');
UPDATE OR IGNORE Features SET MovementChange=1, SightThroughModifier=1, DefenseModifier = 3
	WHERE FeatureType IN (SELECT WonderType FROM WonderTerrainFeature_BBG WHERE Other = 'HILLS');

--aqueduct/bath custom placements (for wonder terrain/feature)
INSERT INTO CustomPlacement(ObjectType, Hash, PlacementFunction)
    SELECT Types.Type, Types.Hash, 'BBG_AQUEDUCT_CUSTOM_PLACEMENT'
    FROM Types WHERE Type IN ('DISTRICT_AQUEDUCT', 'DISTRICT_BATH');

--=======================================================================
--******                       GOODY HUTS                          ******
--=======================================================================

UPDATE GoodyHutSubTypes SET Turn=30 WHERE ModifierID='GOODY_CULTURE_GRANT_ONE_RELIC';
-- 30/06/25 Governor titles delayed to turn 25. Free technology delayed to turn 31.
UPDATE GoodyHutSubTypes SET Turn=50 WHERE ModifierID='GOODY_DIPLOMACY_GRANT_GOVERNOR_TITLE';
UPDATE GoodyHutSubTypes SET Turn=62 WHERE ModifierID='GOODY_SCIENCE_GRANT_ONE_TECH';
-- 2025/12/24 Pop and Builder delayed to turn 10
UPDATE GoodyHutSubTypes SET Turn=20 WHERE ModifierID='GOODY_SURVIVORS_ADD_POPULATION';
UPDATE GoodyHutSubTypes SET Turn=20 WHERE ModifierID='GOODY_SURVIVORS_GRANT_BUILDER';

--=======================================================================
--******                       DISTRICTS                          ******
--=======================================================================

-- 14/10 discount reduced to 35% (20 for diplo quarter/gov) and unique district to 55%
UPDATE Districts SET CostProgressionParam1=20 WHERE DistrictType='DISTRICT_DIPLOMATIC_QUARTER';
UPDATE Districts SET CostProgressionParam1=35 WHERE DistrictType IN ('DISTRICT_THEATER', 'DISTRICT_INDUSTRIAL_ZONE', 'DISTRICT_ENTERTAINMENT_COMPLEX', 'DISTRICT_HOLY_SITE', 'DISTRICT_CAMPUS', 'DISTRICT_ENCAMPMENT', 'DISTRICT_HARBOR', 'DISTRICT_AERODROME', 'DISTRICT_COMMERCIAL_HUB');

UPDATE Districts SET CostProgressionParam1=35 WHERE DistrictType IN ('DISTRICT_ACROPOLIS', 'DISTRICT_STREET_CARNIVAL', 'DISTRICT_ROYAL_NAVY_DOCKYARD', 'DISTRICT_LAVRA', 'DISTRICT_HANSA');
UPDATE Districts SET Cost=20 WHERE DistrictType='DISTRICT_BATH';
UPDATE Districts SET Cost=30 WHERE DistrictType IN ('DISTRICT_MBANZA', 'DISTRICT_ACROPOLIS', 'DISTRICT_STREET_CARNIVAL', 'DISTRICT_ROYAL_NAVY_DOCKYARD', 'DISTRICT_LAVRA', 'DISTRICT_HANSA');

-- 19/12/23 entertainment complex to 2 amenities (from 1)
UPDATE Districts SET Entertainment=2 WHERE DistrictType='DISTRICT_ENTERTAINMENT_COMPLEX';

--=======================================================================
--******                       TECHS                               ******
--=======================================================================

-- 18/12/23 advanced ballistics advanced one era
UPDATE Technologies SET EraType='ERA_MODERN' WHERE TechnologyType='TECH_ADVANCED_BALLISTICS';
UPDATE Technologies SET Cost=1370 WHERE TechnologyType='TECH_ADVANCED_BALLISTICS';

-- 02/07/24 Cost of tech ahead of actual game era are now +30% instead of +20%
UPDATE GlobalParameters SET Value=30 WHERE Name='TECH_COST_PERCENT_CHANGE_AFTER_GAME_ERA';

UPDATE Technologies SET Cost=Cost*1.05 WHERE EraType NOT IN ('ERA_ANCIENT', 'ERA_CLASSICAL');

-- 2022-06-04 -- Add Scientific Theory as Prereq for Steam Power
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
    ('TECH_STEAM_POWER', 'TECH_SCIENTIFIC_THEORY');

-- 30/03/25 Robotics needs Composites
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
    ('TECH_ROBOTICS', 'TECH_COMPOSITES');
-- 08/04/25 Robotics needs TELECOMMUNICATIONS
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
    ('TECH_ROBOTICS', 'TECH_TELECOMMUNICATIONS');

-- 2026/04/34: nuclear fusion do not require guidance systems
-- 09/04/25 Guidance as prereq for Nanotech and Nuclear Fusion (swapped lasers and guidance on the tech tree so it makes more sense)
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
    ('TECH_NANOTECHNOLOGY', 'TECH_GUIDANCE_SYSTEMS');
UPDATE Technologies SET UITreeRow=0 WHERE TechnologyType='TECH_LASERS';
UPDATE Technologies SET UITreeRow=1 WHERE TechnologyType='TECH_GUIDANCE_SYSTEMS';

-- 2026/02/26 Nuclear Fusion requires Composite
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
    ('TECH_NUCLEAR_FUSION', 'TECH_COMPOSITES');

-- 2026/02/26 Composite requires Combined Arms (also moved nuclear fusion one line up)
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
    ('TECH_COMPOSITES', 'TECH_COMBINED_ARMS');
UPDATE Technologies SET UITreeRow=0 WHERE TechnologyType='TECH_NUCLEAR_FISSION';

-- 30/06/25 Military Science grant 1 Spy cap
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES
    ('TECH_MILITARY_SCIENCE', 'CIVIC_GRANT_SPY');
UPDATE Technologies SET Description='BBG_LOC_TECH_MILITARY_SCIENCE_DESCRIPTION' WHERE TechnologyType='TECH_MILITARY_SCIENCE';

--=======================================================================
--******                       AMENITIES                           ******
--=======================================================================

UPDATE Happinesses SET GrowthModifier=8, NonFoodYieldModifier=8 WHERE HappinessType='HAPPINESS_HAPPY';
UPDATE Happinesses SET GrowthModifier=16, NonFoodYieldModifier=16 WHERE HappinessType='HAPPINESS_ECSTATIC';

-- 2026/02/26 happiness unhappy removed; old unhappy renamed euphoric with the same bonus as ecstatic in range [8, +infinity)
UPDATE Happinesses SET MaximumAmenityScore=-4 WHERE HappinessType='HAPPINESS_UNREST';
UPDATE Happinesses SET MinimumAmenityScore=-3 WHERE HappinessType='HAPPINESS_DISPLEASED';

UPDATE Happinesses SET MinimumAmenityScore=8, MaximumAmenityScore=NULL, GrowthModifier=16, NonFoodYieldModifier=16 WHERE HappinessType='HAPPINESS_UNHAPPY';
UPDATE Happinesses_XP1 SET IdentityPerTurnChange=6 WHERE HappinessType='HAPPINESS_UNHAPPY';

-- 30/11/24 Pillage nerf
-- Improvement pillage value to 35/20
UPDATE Improvements SET PlunderAmount=35 WHERE PlunderType='PLUNDER_GOLD';
UPDATE Improvements SET PlunderAmount=20 WHERE PlunderType IN ('PLUNDER_SCIENCE', 'PLUNDER_CULTURE', 'PLUNDER_FAITH');
-- District pillage value to 40/20
UPDATE Districts SET PlunderAmount=40 WHERE PlunderType='PLUNDER_GOLD';
UPDATE Districts SET PlunderAmount=20 WHERE PlunderType IN ('PLUNDER_SCIENCE', 'PLUNDER_CULTURE', 'PLUNDER_FAITH');


--=======================================================================
--******                        BOOSTS                             ******
--=======================================================================


-- 14/03/24 Nationalism boost is now upgrading a land unit to level 3
UPDATE Boosts SET BoostClass='BOOST_TRIGGER_LAND_UNIT_LEVEL', NumItems=3 WHERE CivicType='CIVIC_NATIONALISM';

-- 02/07/24 Steel eureka is now "have 1 renaissance wall"
UPDATE Boosts SET Unit1Type=NULL, BoostClass='BOOST_TRIGGER_HAVE_X_BUILDINGS', BuildingType='BUILDING_STAR_FORT', ImprovementType=NULL, ResourceType=NULL WHERE TechnologyType='TECH_STEEL';

-- 30/03/25 Craftman : Improve 2 tiles [3 tiles]
UPDATE Boosts SET NumItems=2 WHERE CivicType='CIVIC_CRAFTSMANSHIP';

-- 30/03/25 Foreign Trade : Own 1 Scout [Find new Continent]
UPDATE Boosts SET Unit1Type='UNIT_SCOUT', NumItems=1, BoostClass='BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE' WHERE CivicType='CIVIC_FOREIGN_TRADE';

-- 30/03/25 Guidance Systems : Kill a unit with a Fighter [Kill a Fighter]
-- 2025/10/11 Guidance Systems : Own 3 antiair gun
UPDATE Boosts SET BoostClass='BOOST_TRIGGER_KILL_WITH' WHERE TechnologyType='TECH_GUIDANCE_SYSTEMS';
UPDATE Boosts SET Unit1Type='UNIT_ANTIAIR_GUN', NumItems=3, BoostClass='BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE' WHERE TechnologyType='TECH_GUIDANCE_SYSTEMS';

-- 30/03/25 Humanism : Own 2 Amphiteater [Recruit an Artist]
UPDATE Boosts SET Unit1Type=NULL, NumItems=2, BoostClass='BOOST_TRIGGER_HAVE_X_BUILDINGS', BuildingType='BUILDING_AMPHITHEATER' WHERE CivicType='CIVIC_HUMANISM';

-- 2025/10/11 Stealth Technology : Own 2 lab
UpDATE Boosts SET TriggerDescription='LOC_CCB_BOOST_TECH_STEALTH_TECHNOLOGY', TriggerLongDescription='LOC_CCB_BOOST_TECH_STEALTH_TECHNOLOGY', NumItems=2, BoostClass='BOOST_TRIGGER_HAVE_X_BUILDINGS', BuildingType='BUILDING_RESEARCH_LAB' WHERE TechnologyType='TECH_STEALTH_TECHNOLOGY';

--=======================================================================
--******                         BONUS                             ******
--=======================================================================

-- 2025/12/08 future techs bonus
-- advanced ai: project +20% prod
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_ADVANCED_AI', 'CCB_AA_PROJECT_PROD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_AA_PROJECT_PROD', 'MODIFIER_PLAYER_CITIES_ADJUST_PROJECT_PRODUCTION', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_AA_PROJECT_PROD', 'Amount', '20');

-- advanced power cell: all plants +6 prod
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_ADVANCED_POWER_CELLS', 'CCB_APC_PROD_COAL_POWER_PLANT');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_APC_PROD_COAL_POWER_PLANT', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_APC_PROD_COAL_POWER_PLANT', 'Amount', '6'), 
('CCB_APC_PROD_COAL_POWER_PLANT', 'BuildingType', 'BUILDING_COAL_POWER_PLANT'), 
('CCB_APC_PROD_COAL_POWER_PLANT', 'YieldType', 'YIELD_PRODUCTION');

INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_ADVANCED_POWER_CELLS', 'CCB_APC_PROD_FOSSIL_FUEL_POWER_PLANT');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_APC_PROD_FOSSIL_FUEL_POWER_PLANT', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_APC_PROD_FOSSIL_FUEL_POWER_PLANT', 'Amount', '6'), 
('CCB_APC_PROD_FOSSIL_FUEL_POWER_PLANT', 'BuildingType', 'BUILDING_FOSSIL_FUEL_POWER_PLANT'), 
('CCB_APC_PROD_FOSSIL_FUEL_POWER_PLANT', 'YieldType', 'YIELD_PRODUCTION');

INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_ADVANCED_POWER_CELLS', 'CCB_APC_PROD_POWER_PLANT');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_APC_PROD_POWER_PLANT', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_APC_PROD_POWER_PLANT', 'Amount', '6'), 
('CCB_APC_PROD_POWER_PLANT', 'BuildingType', 'BUILDING_POWER_PLANT'), 
('CCB_APC_PROD_POWER_PLANT', 'YieldType', 'YIELD_PRODUCTION');

-- cybernetics: all infomation era units +1 move
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_CYBERNETICS', 'CCB_CYB_INFO_UNIT_MOVE');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_CYB_INFO_UNIT_MOVE', 'MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT', 0, 0, 0, NULL, 'REQSET_CCB_UNIT_IS_INFO_ERA');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_CYB_INFO_UNIT_MOVE', 'Amount', '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_UNIT_IS_INFO_ERA', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_UNIT_IS_INFO_ERA', 'REQ_CCB_UNIT_IS_INFO_ERA');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_UNIT_IS_INFO_ERA', 'REQUIREMENT_UNIT_ERA_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_UNIT_IS_INFO_ERA', 'EraType', 'ERA_INFORMATION');

-- smart materials: all units +3 defense strength
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_SMART_MATERIALS', 'CCB_SM_UNITS_DEFENSE_BONUS_GIVER');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SM_UNITS_DEFENSE_BONUS_GIVER', 'MODIFIER_PLAYER_UNITS_GRANT_ABILITY', 0, 0, 0, NULL, 'REQSET_CCB_UNIT_IS_INFO_ERA');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SM_UNITS_DEFENSE_BONUS_GIVER', 'AbilityType', 'CCB_SM_UNITS_DEFENSE_BONUS');

INSERT INTO Types (Type, Kind) VALUES
    ('CCB_SM_UNITS_DEFENSE_BONUS', 'KIND_ABILITY');
INSERT INTO TypeTags (Type, Tag) VALUES
    ('CCB_SM_UNITS_DEFENSE_BONUS', 'CLASS_ALL_UNITS');

INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive) VALUES
    ('CCB_SM_UNITS_DEFENSE_BONUS', 'LOC_CCB_SM_UNITS_DEFENSE_BONUS_NAME', 'LOC_CCB_SM_UNITS_DEFENSE_BONUS_DESC', 1);

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES 
('CCB_SM_UNITS_DEFENSE_BONUS', 'CCB_SM_UNITS_DEFENSE_BONUS_MOD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SM_UNITS_DEFENSE_BONUS_MOD', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 0, 0, 0, NULL, 'REQSET_CCB_UNIT_IS_DEFENDER');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SM_UNITS_DEFENSE_BONUS_MOD', 'Amount', '3');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_UNIT_IS_DEFENDER', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_UNIT_IS_DEFENDER', 'PLAYER_IS_DEFENDER_REQUIREMENTS');

-- sea stead: farm, pasture and fishery +1 food
INSERT INTO Improvement_BonusYieldChanges (Id, ImprovementType, YieldType, BonusYieldChange, PrereqTech) VALUES
    (3060, 'IMPROVEMENT_FARM', 'YIELD_FOOD', 1, 'TECH_SEASTEADS'),
    (3061, 'IMPROVEMENT_PASTURE', 'YIELD_FOOD', 1, 'TECH_SEASTEADS'),
    (3062, 'IMPROVEMENT_FISHERY', 'YIELD_FOOD', 1, 'TECH_SEASTEADS');

-- predictive system: all cities prevent structual damage
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_PREDICTIVE_SYSTEMS', 'CCB_PS_DAMAGE_FREE_GIVER');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_PS_DAMAGE_FREE_GIVER', 'MODIFIER_PLAYER_CITIES_ATTACH_MODIFIER', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_PS_DAMAGE_FREE_GIVER', 'ModifierId', 'MODIFIER_GOVERNOR_ADJUST_PREVENET_STRUCTURAL_DAMAGE');

-- 2025/12/09 launch earth satellite: all units +3 combat strength
INSERT INTO ProjectCompletionModifiers (ProjectType, ModifierId) VALUES 
('PROJECT_LAUNCH_EARTH_SATELLITE', 'CCB_PROJECT_COMPLETION_STRENGTH_BONUS');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_PROJECT_COMPLETION_STRENGTH_BONUS', 'MODIFIER_PLAYER_UNITS_ADJUST_COMBAT_STRENGTH', 0, 0, 0, NULL, NULL);
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_PROJECT_COMPLETION_STRENGTH_BONUS', 'Amount', '3');
INSERT INTO ModifierStrings (ModifierId, Context, Text) VALUES
	('CCB_PROJECT_COMPLETION_STRENGTH_BONUS', 'Preview', 'LOC_CCB_PROJECT_COMPLETION_STRENGTH_BONUS_DESC');

UPDATE Technologies SET Description='LOC_CCB_TECH_PREDICTIVE_SYSTEMS_DESCRIPTION' WHERE TechnologyType='TECH_PREDICTIVE_SYSTEMS';

-- 2026/05/10: farm +1 prod from each farm with tech replacable part, +1 food from each farm with civic feudelism
UPDATE Adjacency_YieldChanges SET TilesRequired=1, ObsoleteTech=NULL WHERE ID="Farms_MedievalAdjacency";
UPDATE Adjacency_YieldChanges SET YieldType='YIELD_PRODUCTION' WHERE ID="Farms_MechanizedAdjacency";

-- 2026/05/10: tech military science +1 movement for military engineer
INSERT INTO TechnologyModifiers (TechnologyType, ModifierId) VALUES 
('TECH_MILITARY_SCIENCE', 'CCB_MILITARY_SCIENCE_MOVEMENT_FOR_UNIT_MILITARY_ENGINEER');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_MILITARY_SCIENCE_MOVEMENT_FOR_UNIT_MILITARY_ENGINEER', 'MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT', 0, 0, 0, NULL, 'CCB_REQSET_UNIT_IS_UNIT_MILITARY_ENGINEER');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_MILITARY_SCIENCE_MOVEMENT_FOR_UNIT_MILITARY_ENGINEER', 'Amount', '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('CCB_REQSET_UNIT_IS_UNIT_MILITARY_ENGINEER', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('CCB_REQSET_UNIT_IS_UNIT_MILITARY_ENGINEER', 'REQ_CCB_UNIT_IS_UNIT_MILITARY_ENGINEER');
INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_UNIT_IS_UNIT_MILITARY_ENGINEER', 'REQUIREMENT_UNIT_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQ_CCB_UNIT_IS_UNIT_MILITARY_ENGINEER', 'UnitType', 'UNIT_MILITARY_ENGINEER');

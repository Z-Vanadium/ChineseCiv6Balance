DELETE FROM Improvement_ValidTerrains WHERE ImprovementType = 'IMPROVEMENT_TERRACE_FARM';

INSERT INTO Improvement_ValidTerrains(ImprovementType, TerrainType) SELECT
'IMPROVEMENT_TERRACE_FARM',TerrainType
FROM Improvement_ValidTerrains WHERE ImprovementType = 'IMPROVEMENT_SKI_RESORT';

INSERT INTO Improvements_XP2(ImprovementType,BuildOnAdjacentPlot)VALUES
('IMPROVEMENT_TERRACE_FARM',1);

-- 2025/09/18 ui mountain, self and aqueduct adjacency bonus remove
DELETE FROM Improvement_Adjacencies
      WHERE YieldChangeId IN ('Terrace_GrassMountainAdjacency', 'Terrace_PlainsMountainAdjacency', 'Terrace_DesertMountainAdjacency', 'Terrace_TundraMountainAdjacency', 'Terrace_SnowMountainAdjacency', 'Terrace_MedievalAdjacency', 'Terrace_MechanizedAdjacency', 'Terrace_AqueductAdjacency') AND
            ImprovementType = 'IMPROVEMENT_TERRACE_FARM';

-- ui +1 food with irrigation, +1 food with feudalism
INSERT INTO Improvement_BonusYieldChanges (Id, PrereqCivic, PrereqTech, BonusYieldChange, YieldType, ImprovementType) VALUES
('4010', NULL, 'TECH_IRRIGATION', 1, 'YIELD_FOOD', 'IMPROVEMENT_TERRACE_FARM'),
('4013', 'CIVIC_FEUDALISM', NULL, 1, 'YIELD_FOOD', 'IMPROVEMENT_TERRACE_FARM');

-- la no domestic trade food bonus
DELETE FROM TraitModifiers
      WHERE TraitType = 'TRAIT_LEADER_PACHACUTI_QHAPAQ_NAN' AND
            ModifierId IN ('DOMESTIC_TRADE_ROUTE_FOOD_GRASS_MOUNTAIN_ORIGIN', 'DOMESTIC_TRADE_ROUTE_FOOD_PLAINS_MOUNTAIN_ORIGIN', 'DOMESTIC_TRADE_ROUTE_FOOD_DESERT_MOUNTAIN_ORIGIN', 'DOMESTIC_TRADE_ROUTE_FOOD_TUNDRA_MOUNTAIN_ORIGIN', 'DOMESTIC_TRADE_ROUTE_FOOD_SNOW_MOUNTAIN_ORIGIN');

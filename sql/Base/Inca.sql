DELETE FROM Improvement_ValidTerrains WHERE ImprovementType = 'IMPROVEMENT_TERRACE_FARM';

INSERT INTO Improvement_ValidTerrains(ImprovementType, TerrainType) SELECT
'IMPROVEMENT_TERRACE_FARM',TerrainType
FROM Improvement_ValidTerrains WHERE ImprovementType = 'IMPROVEMENT_SKI_RESORT';

INSERT INTO Improvements_XP2(ImprovementType,BuildOnAdjacentPlot)VALUES
('IMPROVEMENT_TERRACE_FARM',1);
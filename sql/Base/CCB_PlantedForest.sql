--==============================================================================================
-- CCB 人工林特征 FEATURE_CCB_PLANTED_FOREST（2026-09-19）
--   目标：让「玩家种植的森林」在视觉上与原始森林区分（Clutter 排列/大小不同，见 ArtDefs/）
--   规则层：整表复制森林——Forest=1 / Appeal=+1 / DefenseModifier=3 / MovementChange=1 /
--           SightThroughModifier=1 / Removable=1 / RemoveTech=TECH_MINING / AddCivic=CIVIC_CONSERVATION
--   本文件由脚本按 DebugGameplay 列顺序自动生成，避免手写漏列；
--   ⚠ 有独立主键的表（Adjacency_YieldChanges.ID）复制时必须改 ID，否则被 OR IGNORE 吞掉
--==============================================================================================
INSERT OR IGNORE INTO Types (Type, Kind) VALUES ('FEATURE_CCB_PLANTED_FOREST', 'KIND_FEATURE');
INSERT OR IGNORE INTO Features (FeatureType, Name, Description, Quote, Coast, NoCoast, NoRiver, NoAdjacentFeatures, RequiresRiver, MovementChange, SightThroughModifier, Impassable, NaturalWonder, RemoveTech, Removable, AddCivic, DefenseModifier, AddsFreshWater, Appeal, MinDistanceLand, MaxDistanceLand, NotNearFeature, Lake, Tiles, Adjacent, NoResource, DoubleAdjacentTerrainYield, NotCliff, MinDistanceNW, CustomPlacement, Forest, AntiquityPriority, QuoteAudio, Settlement, FollowRulesInWB, DangerValue)
SELECT 'FEATURE_CCB_PLANTED_FOREST', 'LOC_FEATURE_CCB_PLANTED_FOREST_NAME', Description, Quote, Coast, NoCoast, NoRiver, NoAdjacentFeatures, RequiresRiver, MovementChange, SightThroughModifier, Impassable, NaturalWonder, RemoveTech, Removable, AddCivic, DefenseModifier, AddsFreshWater, Appeal, MinDistanceLand, MaxDistanceLand, NotNearFeature, Lake, Tiles, Adjacent, NoResource, DoubleAdjacentTerrainYield, NotCliff, MinDistanceNW, CustomPlacement, Forest, AntiquityPriority, QuoteAudio, Settlement, FollowRulesInWB, DangerValue FROM Features WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO Features_XP2 (FeatureType, Volcano, ValidWonderPlacement, ValidDistrictPlacement, Eruptable, ValidForReplacement)
SELECT 'FEATURE_CCB_PLANTED_FOREST', Volcano, ValidWonderPlacement, ValidDistrictPlacement, Eruptable, ValidForReplacement FROM Features_XP2 WHERE FeatureType = 'FEATURE_FOREST';

-- 关联表：逐表复制（唯一约束用 OR IGNORE 保证幂等）
INSERT OR IGNORE INTO Feature_ValidTerrains (FeatureType, TerrainType)
SELECT 'FEATURE_CCB_PLANTED_FOREST', TerrainType FROM Feature_ValidTerrains WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO Feature_YieldChanges (FeatureType, YieldType, YieldChange)
SELECT 'FEATURE_CCB_PLANTED_FOREST', YieldType, YieldChange FROM Feature_YieldChanges WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO Feature_Removes (FeatureType, YieldType, Yield)
SELECT 'FEATURE_CCB_PLANTED_FOREST', YieldType, Yield FROM Feature_Removes WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO Improvement_ValidFeatures (ImprovementType, FeatureType, PrereqTech, PrereqCivic)
SELECT ImprovementType, 'FEATURE_CCB_PLANTED_FOREST', PrereqTech, PrereqCivic FROM Improvement_ValidFeatures WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO Building_RequiredFeatures (BuildingType, FeatureType)
SELECT BuildingType, 'FEATURE_CCB_PLANTED_FOREST' FROM Building_RequiredFeatures WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO District_RequiredFeatures (DistrictType, FeatureType)
SELECT DistrictType, 'FEATURE_CCB_PLANTED_FOREST' FROM District_RequiredFeatures WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO RandomEvent_Features (RandomEventType, FeatureType)
SELECT RandomEventType, 'FEATURE_CCB_PLANTED_FOREST' FROM RandomEvent_Features WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO RandomEvent_Yields (RandomEventType, YieldType, FeatureType, Percentage, ReplaceFeature, Amount, Turn)
SELECT RandomEventType, YieldType, 'FEATURE_CCB_PLANTED_FOREST', Percentage, ReplaceFeature, Amount, Turn FROM RandomEvent_Yields WHERE FeatureType = 'FEATURE_FOREST';
INSERT OR IGNORE INTO Feature_AdjacentFeatures (FeatureType, FeatureTypeAdjacent)
SELECT FeatureType, 'FEATURE_CCB_PLANTED_FOREST' FROM Feature_AdjacentFeatures WHERE FeatureTypeAdjacent = 'FEATURE_FOREST';
-- 相邻加成表的主键是独立 ID，必须改写否则与原行冲突
INSERT OR IGNORE INTO Adjacency_YieldChanges (ID, Description, YieldType, YieldChange, TilesRequired, OtherDistrictAdjacent, AdjacentSeaResource, AdjacentTerrain, AdjacentFeature, AdjacentRiver, AdjacentWonder, AdjacentNaturalWonder, AdjacentImprovement, AdjacentDistrict, PrereqCivic, PrereqTech, ObsoleteCivic, ObsoleteTech, AdjacentResource, AdjacentResourceClass, Self)
SELECT 'CCBPF_' || ID, Description, YieldType, YieldChange, TilesRequired, OtherDistrictAdjacent, AdjacentSeaResource, AdjacentTerrain, 'FEATURE_CCB_PLANTED_FOREST', AdjacentRiver, AdjacentWonder, AdjacentNaturalWonder, AdjacentImprovement, AdjacentDistrict, PrereqCivic, PrereqTech, ObsoleteCivic, ObsoleteTech, AdjacentResource, AdjacentResourceClass, Self FROM Adjacency_YieldChanges WHERE AdjacentFeature = 'FEATURE_FOREST';

-- 说明：Resource_ValidFeatures / StartBiasFeatures 属地图生成期规则，人工林是游戏中途出现，无需复制

--==============================================================================================
-- 灾害补正对齐（2026-09-20 BUG 修复 · 用户实测"火烧后人工林变原始树林，并拿到异常的粮食/生产力补正"）
--   ⚠ **加载顺序陷阱（本次 BUG 的真根因）**：
--     BBG/CCB 1.6 的灾害规则在 `sql/NFP/new_bbg_disasters.sql`，其 LoadOrder 是 **11642**，
--     而本文件是 **11615** → 上面那条 `RandomEvent_Yields` 整表复制**先执行**，拿到的是**原版**取值：
--       · 原版 FEATURE_FOREST 的火灾行 = `YIELD_PRODUCTION`
--       · BBG 1.6 才把它改成 `YIELD_FOOD`（= CCB 规则"树林新生补食物、丛林新生补生产力"）
--     → 复制出来的人工林行停留在"生产"，于是人工林着火后按 **+1 生产力** 结算，属异常。
--   修法：显式对齐成与**修正后的森林行**完全一致（食物 +1 / 持续 6 回合）。
--     一行一特征，引擎按"地块当前特征"取行 → 人工林只吃这一行，不会与森林行叠加。
--==============================================================================================
UPDATE RandomEvent_Yields SET YieldType='YIELD_FOOD', Amount=1, Turn=6
	WHERE RandomEventType='RANDOM_EVENT_FOREST_FIRE' AND FeatureType='FEATURE_CCB_PLANTED_FOREST';

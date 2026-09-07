-- ==============
-- == DISTRICT ==
-- ==============

-- Create new district traderoute yield
INSERT INTO District_TradeRouteYields(DistrictType, YieldType, YieldChangeAsOrigin, YieldChangeAsDomesticDestination, YieldChangeAsInternationalDestination) VALUES
    ('DISTRICT_AERODROME', 'YIELD_PRODUCTION', 0.0, 1.0, 1.0);

-- Preserve give ability to plant wood.
-- INSERT INTO Modifiers(ModifierId, ModifierType) VALUES
--    ('BBG_PRESERVE_PLANT_WOOD', 'MODIFIER_PLAYER_ADJUST_FEATURE_UNLOCK');
-- INSERT INTO ModifierArguments(ModifierId, Name, Value) VALUES
--    ('BBG_PRESERVE_PLANT_WOOD', 'FeatureType', 'FEATURE_FOREST'),
--    ('BBG_PRESERVE_PLANT_WOOD', 'CivicType', 'CIVIC_CODE_OF_LAWS');
-- INSERT INTO DistrictModifiers(DistrictType, ModifierId) VALUES
--    ('DISTRICT_PRESERVE', 'BBG_PRESERVE_PLANT_WOOD');

--5.2.5 buff commercial hub +1 gold on hub close to city center / -1 gold on market 
-- 2026/02/26 commercial hub: +2 gold from city center (from +1); +1 gold from river (from +2)
INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, AdjacentDistrict) VALUES
    ('BBG_COMMERCIAL_HUB_CITY_CENTER', 'LOC_DISTRICT_CITY_CENTER_GOLD', 'YIELD_GOLD', 2, 'DISTRICT_CITY_CENTER');
INSERT INTO District_Adjacencies(DistrictType, YieldChangeId) VALUES
    ('DISTRICT_COMMERCIAL_HUB', 'BBG_COMMERCIAL_HUB_CITY_CENTER');
UPDATE Building_YieldChanges SET YieldChange=2 WHERE BuildingType='BUILDING_MARKET' AND YieldType='YIELD_GOLD';

-- 2026-XX-XX（从 1.4.3 移植）Commercial Hub gets +1 production when adjacent to a river (all civs, global)
-- 参考 BBG 全局沿河加成标准结构（河神/NALANDA 同款双层）：
--   MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY 是 COLLECTION_PLAYER_CITIES 型 modifier，
--   必须由玩家持有才能展开到城市 → 外层用 MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER 挂 GameModifiers，
--   内层才是实际效果（直接挂 GameModifiers 会因找不到 owner player 而不生效）
--   ⚠ 与 1.6 自身的河流金币调整（River_Gold=1）叠加，平衡值待用户复核
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER'),
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION_EFFECT', 'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION', 'ModifierId', 'CCB_COMMERCIAL_HUB_RIVER_PRODUCTION_EFFECT'),
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION_EFFECT', 'Amount', 1),
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION_EFFECT', 'Description', 'LOC_CCB_DISTRICT_RIVER_PROD'),
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION_EFFECT', 'DistrictType', 'DISTRICT_COMMERCIAL_HUB'),
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION_EFFECT', 'YieldType', 'YIELD_PRODUCTION');
-- 全局对所有文明生效（挂外层，开局附加给每个玩家）
INSERT INTO GameModifiers (ModifierId) VALUES
    ('CCB_COMMERCIAL_HUB_RIVER_PRODUCTION');

UPDATE Adjacency_YieldChanges SET YieldChange='1' WHERE ID='River_Gold';
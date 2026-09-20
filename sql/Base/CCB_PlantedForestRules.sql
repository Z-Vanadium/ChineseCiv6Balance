--==============================================================================================
-- CCB 人工林 · 规则别名层（2026-09-19 用户反馈：人工林吃不到"森林加成"）
--   问题：人工林是新特征 FEATURE_CCB_PLANTED_FOREST，虽然列全复制了森林（Forest=1 等），
--         但原版/模组里还有一批规则是"点名 FEATURE_FOREST"来判断的，新特征天然不匹配：
--           · 米纳克希神庙 +1 信仰（CCB 自己的修正器）
--           · 毛利（库佩）"玛纳"：未改良树林/雨林 +生产力（原版，3 档：基础/重商主义/自然保护）
--           · 苏格兰高地人：树林/丘陵 +战斗力
--           · 越南（赵妪）：专业区域可建在树林上、建筑每片树林 +1 文化
--           · 挪威圣杖教堂：相邻树林 +1 信仰；生物圈：每片树林 +1 科技
--           · 圣地/拉夫拉/巨型头像：相邻树林 +信仰（相邻加成型）
--           · CCB 神圣之路：相邻树林 +1 信仰
--   解决办法（两条腿，且两条腿不会互相叠加 —— 一格只有一种特征）：
--     ① 需求层：全游戏所有"地块是森林"的判断，最终都汇总到一个共享需求
--        PLOT_IS_FOREST_REQUIREMENT（REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES + FeatureType=FEATURE_FOREST，
--        定义在原版 UnitPromotions.xml）。这里把它整体改成「特征类别 tag」判定，并给
--        FEATURE_FOREST 与人工林打上同一个 tag —— 于是所有引用该需求的需求集（含其它模组自建的需求）
--        一次性对人工林生效。
--        机制出处（原版先例）：DLC\Expansion2 里三种泛滥平原共用 tag CLASS_FLOODPLAINS +
--        REQUIREMENT_PLOT_FEATURE_TAG_MATCHES，埃及狮身人面像的 SPHINX_FLOODPLAINS_CULTURE 就是这么判的。
--     ② 参数层：少数修正器把 FEATURE_FOREST 当"参数"（不是需求），tag 改不到它们，逐个做孪生：
--        新增一个 FeatureType=人工林 的同型修正器，挂到同一个拥有者（建筑/信条/文明特性）上。
--   挂载顺序 100200：排在全部常规规则与 BBG_Expanded（100000）之后，便于"以终态为准"再同步一次表复制。
--==============================================================================================


--==============================================================================================
-- ① 特征类别 tag：CCB_CLASS_TREES（森林 + 人工林）
--==============================================================================================
INSERT OR IGNORE INTO Vocabularies (Vocabulary) VALUES ('FEATURE_CLASS');

INSERT OR IGNORE INTO Tags (Tag, Vocabulary) VALUES ('CCB_CLASS_TREES', 'FEATURE_CLASS');

INSERT OR IGNORE INTO TypeTags (Type, Tag) VALUES
    ('FEATURE_FOREST', 'CCB_CLASS_TREES'),
    ('FEATURE_CCB_PLANTED_FOREST', 'CCB_CLASS_TREES');

-- 1.1 把所有"地块特征类型 == FEATURE_FOREST"的需求改成 tag 判定
--     （覆盖原版共享需求 PLOT_IS_FOREST_REQUIREMENT，以及 BBG Expanded 芬兰等自建需求；
--       雨林/沼泽/丘陵的同类需求不受影响，它们不是 FEATURE_FOREST）
UPDATE RequirementArguments SET Name = 'Tag', Value = 'CCB_CLASS_TREES'
WHERE Name = 'FeatureType' AND Value = 'FEATURE_FOREST'
  AND RequirementId IN (SELECT RequirementId FROM Requirements WHERE RequirementType = 'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES');

-- 1.2 同步把这些需求的"需求类型"换成 tag 匹配（上一步刚改过参数的，即我们要换的那批）
UPDATE Requirements SET RequirementType = 'REQUIREMENT_PLOT_FEATURE_TAG_MATCHES'
WHERE RequirementId IN (SELECT RequirementId FROM RequirementArguments WHERE Name = 'Tag' AND Value = 'CCB_CLASS_TREES');


--==============================================================================================
-- ② 参数层：把 FEATURE_FOREST 当参数的修正器，逐个做"人工林孪生"
--==============================================================================================

-- 2.1 挪威 · 圣杖教堂：相邻树林 +1 信仰（原：STAVE_CHURCH_FAITHWOODSADJACENCY）
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
    ('CCB_PF_STAVE_CHURCH_FAITH_WOODS', 'MODIFIER_SINGLE_CITY_FEATURE_ADJACENCY');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('CCB_PF_STAVE_CHURCH_FAITH_WOODS', 'DistrictType', 'DISTRICT_HOLY_SITE'),
    ('CCB_PF_STAVE_CHURCH_FAITH_WOODS', 'FeatureType', 'FEATURE_CCB_PLANTED_FOREST'),
    ('CCB_PF_STAVE_CHURCH_FAITH_WOODS', 'YieldType', 'YIELD_FAITH'),
    ('CCB_PF_STAVE_CHURCH_FAITH_WOODS', 'Amount', '1'),
    ('CCB_PF_STAVE_CHURCH_FAITH_WOODS', 'Description', 'LOC_STAVE_CHURCH_FOREST_FAITH');
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
    ('BUILDING_STAVE_CHURCH', 'CCB_PF_STAVE_CHURCH_FAITH_WOODS');

-- 2.2 生物圈：每片树林 +1 科技（原：BIOSPHERE_GRANT_SCIENCE_PER_WOODS）
--     生物圈属 DLC（Byzantium_Gaul），加存在性守卫避免该 DLC 未启用时留下悬空行
INSERT INTO Modifiers (ModifierId, ModifierType)
SELECT 'CCB_PF_BIOSPHERE_SCIENCE_WOODS', 'MODIFIER_CITY_GRANT_YIELD_PER_FEATURE_TYPE'
WHERE EXISTS (SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_BIOSPHERE');
INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT * FROM (SELECT 'CCB_PF_BIOSPHERE_SCIENCE_WOODS', 'FeatureType', 'FEATURE_CCB_PLANTED_FOREST'
               UNION ALL SELECT 'CCB_PF_BIOSPHERE_SCIENCE_WOODS', 'YieldType', 'YIELD_SCIENCE'
               UNION ALL SELECT 'CCB_PF_BIOSPHERE_SCIENCE_WOODS', 'Amount', '100')
WHERE EXISTS (SELECT 1 FROM Modifiers WHERE ModifierId = 'CCB_PF_BIOSPHERE_SCIENCE_WOODS');
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_BIOSPHERE', 'CCB_PF_BIOSPHERE_SCIENCE_WOODS'
WHERE EXISTS (SELECT 1 FROM Modifiers WHERE ModifierId = 'CCB_PF_BIOSPHERE_SCIENCE_WOODS');

-- 2.3 越南（赵妪）：专业区域可建在树林上 + 建筑每片树林 +1 文化
--     注：TRAIT_PLANT_MEDIEVAL_WOODS（中世纪集市可植树）不需要孪生 —— 种下的仍是 FEATURE_FOREST，
--         由 scripts/ccb_planted_forest.lua 立刻替换成人工林，玩家行为不变
--     越南属 DLC（KublaiKhan_Vietnam），加存在性守卫
INSERT INTO Modifiers (ModifierId, ModifierType)
SELECT 'CCB_PF_VIETNAM_DISTRICTS_FOREST', 'MODIFIER_PLAYER_ADJUST_FEAUTE_REQUIRED_FOR_SPECIALTY_DISTRICTS'
WHERE EXISTS (SELECT 1 FROM Traits WHERE TraitType = 'TRAIT_CIVILIZATION_VIETNAM');
INSERT INTO Modifiers (ModifierId, ModifierType)
SELECT 'CCB_PF_VIETNAM_BUILDINGS_CULTURE', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_FEATURE_YIELD_CHANGE'
WHERE EXISTS (SELECT 1 FROM Traits WHERE TraitType = 'TRAIT_CIVILIZATION_VIETNAM');
INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT * FROM (SELECT 'CCB_PF_VIETNAM_DISTRICTS_FOREST', 'FeatureType', 'FEATURE_CCB_PLANTED_FOREST'
               UNION ALL SELECT 'CCB_PF_VIETNAM_BUILDINGS_CULTURE', 'FeatureType', 'FEATURE_CCB_PLANTED_FOREST'
               UNION ALL SELECT 'CCB_PF_VIETNAM_BUILDINGS_CULTURE', 'YieldType', 'YIELD_CULTURE'
               UNION ALL SELECT 'CCB_PF_VIETNAM_BUILDINGS_CULTURE', 'Amount', '1')
WHERE EXISTS (SELECT 1 FROM Modifiers WHERE ModifierId = 'CCB_PF_VIETNAM_BUILDINGS_CULTURE');
INSERT INTO TraitModifiers (TraitType, ModifierId)
SELECT 'TRAIT_CIVILIZATION_VIETNAM', 'CCB_PF_VIETNAM_DISTRICTS_FOREST'
WHERE EXISTS (SELECT 1 FROM Traits WHERE TraitType = 'TRAIT_CIVILIZATION_VIETNAM');
INSERT INTO TraitModifiers (TraitType, ModifierId)
SELECT 'TRAIT_CIVILIZATION_VIETNAM', 'CCB_PF_VIETNAM_BUILDINGS_CULTURE'
WHERE EXISTS (SELECT 1 FROM Traits WHERE TraitType = 'TRAIT_CIVILIZATION_VIETNAM');

-- 2.4 CCB 神圣之路：圣地相邻树林 +1 信仰（原：BBG_SACRED_PATH_WOODS_FAITH_ADJACENCY）
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('CCB_PF_SACRED_PATH_WOODS_FAITH', 'MODIFIER_ALL_CITIES_FEATURE_ADJACENCY', 'CITY_FOLLOWS_PANTHEON_REQUIREMENTS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('CCB_PF_SACRED_PATH_WOODS_FAITH', 'DistrictType', 'DISTRICT_HOLY_SITE'),
    ('CCB_PF_SACRED_PATH_WOODS_FAITH', 'FeatureType', 'FEATURE_CCB_PLANTED_FOREST'),
    ('CCB_PF_SACRED_PATH_WOODS_FAITH', 'YieldType', 'YIELD_FAITH'),
    ('CCB_PF_SACRED_PATH_WOODS_FAITH', 'Amount', '1'),
    ('CCB_PF_SACRED_PATH_WOODS_FAITH', 'Description', 'LOC_DISTRICT_SACREDPATH_WOODS_FAITH');
INSERT INTO BeliefModifiers (BeliefType, ModifierId) VALUES
    ('BELIEF_SACRED_PATH', 'CCB_PF_SACRED_PATH_WOODS_FAITH');

-- 2.5 泰迪·罗斯福（莽骑兵）：相邻树林或奇观 —— 原需求集 REQUIREMENTS_PLOT_ADJACENT_FORESTS_OR_WONDERS
--     是 REQUIREMENTSET_TEST_ANY（多个条件任一成立即可），所以直接往里补一条"相邻人工林"即可，
--     不需要孪生修正器，也不会与原条件叠加
INSERT INTO Requirements (RequirementId, RequirementType) VALUES
    ('CCB_PF_REQ_ADJACENT_PLANTED_FOREST', 'REQUIREMENT_PLOT_ADJACENT_FEATURE_TYPE_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
    ('CCB_PF_REQ_ADJACENT_PLANTED_FOREST', 'FeatureType', 'FEATURE_CCB_PLANTED_FOREST');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
    ('REQUIREMENTS_PLOT_ADJACENT_FORESTS_OR_WONDERS', 'CCB_PF_REQ_ADJACENT_PLANTED_FOREST');


--==============================================================================================
-- ③ 表复制"以终态为准"再同步
--    11615 那轮复制早于 BBG_Expanded（100000），会漏掉后加载内容；这里在最后重跑一遍：
--    先删掉人工林自己的行再重建，保证与森林行完全一致（含新补的 Improvement_InvalidAdjacentFeatures
--    与两张"挂载链"表 —— 缺了挂载链，相邻加成行不会生效）
--==============================================================================================
DELETE FROM Feature_ValidTerrains WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Feature_ValidTerrains (FeatureType, TerrainType)
SELECT 'FEATURE_CCB_PLANTED_FOREST', TerrainType FROM Feature_ValidTerrains WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM Feature_YieldChanges WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Feature_YieldChanges (FeatureType, YieldType, YieldChange)
SELECT 'FEATURE_CCB_PLANTED_FOREST', YieldType, YieldChange FROM Feature_YieldChanges WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM Feature_Removes WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Feature_Removes (FeatureType, YieldType, Yield)
SELECT 'FEATURE_CCB_PLANTED_FOREST', YieldType, Yield FROM Feature_Removes WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM Improvement_ValidFeatures WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Improvement_ValidFeatures (ImprovementType, FeatureType, PrereqTech, PrereqCivic)
SELECT ImprovementType, 'FEATURE_CCB_PLANTED_FOREST', PrereqTech, PrereqCivic FROM Improvement_ValidFeatures WHERE FeatureType = 'FEATURE_FOREST';

-- 新增：不得与树林相邻的改良（拉帕努伊"莫艾神像"等）
DELETE FROM Improvement_InvalidAdjacentFeatures WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Improvement_InvalidAdjacentFeatures (ImprovementType, FeatureType)
SELECT ImprovementType, 'FEATURE_CCB_PLANTED_FOREST' FROM Improvement_InvalidAdjacentFeatures WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM Building_RequiredFeatures WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Building_RequiredFeatures (BuildingType, FeatureType)
SELECT BuildingType, 'FEATURE_CCB_PLANTED_FOREST' FROM Building_RequiredFeatures WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM District_RequiredFeatures WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO District_RequiredFeatures (DistrictType, FeatureType)
SELECT DistrictType, 'FEATURE_CCB_PLANTED_FOREST' FROM District_RequiredFeatures WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM RandomEvent_Features WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO RandomEvent_Features (RandomEventType, FeatureType)
SELECT RandomEventType, 'FEATURE_CCB_PLANTED_FOREST' FROM RandomEvent_Features WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM RandomEvent_Yields WHERE FeatureType = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO RandomEvent_Yields (RandomEventType, YieldType, FeatureType, Percentage, ReplaceFeature, Amount, Turn)
SELECT RandomEventType, YieldType, 'FEATURE_CCB_PLANTED_FOREST', Percentage, ReplaceFeature, Amount, Turn FROM RandomEvent_Yields WHERE FeatureType = 'FEATURE_FOREST';

DELETE FROM Feature_AdjacentFeatures WHERE FeatureTypeAdjacent = 'FEATURE_CCB_PLANTED_FOREST';
INSERT INTO Feature_AdjacentFeatures (FeatureType, FeatureTypeAdjacent)
SELECT FeatureType, 'FEATURE_CCB_PLANTED_FOREST' FROM Feature_AdjacentFeatures WHERE FeatureTypeAdjacent = 'FEATURE_FOREST';

-- 3.1 挂载链：区域 ← 相邻加成行（圣地 / 拉夫拉 的 Forest_Faith）
DELETE FROM District_Adjacencies WHERE YieldChangeId LIKE 'CCBPF_%';
INSERT INTO District_Adjacencies (DistrictType, YieldChangeId)
SELECT DistrictType, 'CCBPF_' || YieldChangeId FROM District_Adjacencies
WHERE YieldChangeId IN (SELECT ID FROM Adjacency_YieldChanges WHERE AdjacentFeature = 'FEATURE_FOREST');

-- 3.2 挂载链：改良 ← 相邻加成行（巨型头像 ColossalHead_FaithForest* / CCB 芬兰桑拿房 Sauna_Woods*）
DELETE FROM Improvement_Adjacencies WHERE YieldChangeId LIKE 'CCBPF_%';
INSERT INTO Improvement_Adjacencies (ImprovementType, YieldChangeId)
SELECT ImprovementType, 'CCBPF_' || YieldChangeId FROM Improvement_Adjacencies
WHERE YieldChangeId IN (SELECT ID FROM Adjacency_YieldChanges WHERE AdjacentFeature = 'FEATURE_FOREST');

-- 3.3 相邻加成行本体（主键是独立 ID，必须改前缀否则与原行冲突）
DELETE FROM Adjacency_YieldChanges WHERE ID LIKE 'CCBPF_%';
INSERT INTO Adjacency_YieldChanges (ID, Description, YieldType, YieldChange, TilesRequired, OtherDistrictAdjacent, AdjacentSeaResource, AdjacentTerrain, AdjacentFeature, AdjacentRiver, AdjacentWonder, AdjacentNaturalWonder, AdjacentImprovement, AdjacentDistrict, PrereqCivic, PrereqTech, ObsoleteCivic, ObsoleteTech, AdjacentResource, AdjacentResourceClass, Self)
SELECT 'CCBPF_' || ID, Description, YieldType, YieldChange, TilesRequired, OtherDistrictAdjacent, AdjacentSeaResource, AdjacentTerrain, 'FEATURE_CCB_PLANTED_FOREST', AdjacentRiver, AdjacentWonder, AdjacentNaturalWonder, AdjacentImprovement, AdjacentDistrict, PrereqCivic, PrereqTech, ObsoleteCivic, ObsoleteTech, AdjacentResource, AdjacentResourceClass, Self
FROM Adjacency_YieldChanges WHERE AdjacentFeature = 'FEATURE_FOREST';


--==============================================================================================
-- ④ 有意不覆盖的项（记录在案，避免以后重复排查）
--   · StartBiasFeatures / Resource_ValidFeatures / AiFavoredItems：属"地图生成期"规则，
--     人工林是游戏中途才出现的地块，不参与开局生成
--   · TRAIT_PLANT_MEDIEVAL_WOODS / CCB_FINLAND_ENABLE_PLANT_FOREST / TEDDY_PLANT_MEDIEVAL_WOODS_BBG：
--     "可植树"的解锁，种下的是 FEATURE_FOREST 再被 Lua 换成人工林，行为已正确
--   · BarbarianTribe_MapConditions（蛮族部落类型地图条件）：条件集语义为 TEST_ALL/Range 组合，
--     贸然补行会让"森林/开阔地"判定互斥，风险大于收益，跳过
--   · MapConditionSet / 场景地图脚本（Tilted_Axis.lua 等）：与本模组运行环境无关
--==============================================================================================

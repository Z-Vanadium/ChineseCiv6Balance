--以下为组装modifier的部分
--============================================================================================================================
--自制modifier:给玩家所有区域地基加产--用于提供相邻产出，环数为1环
    INSERT INTO Types (Type, Kind) VALUES 
    ("RUIVO_MODIFIER_PLAYER_DISTRICTS_ADJUST_BASE_YIELD_CHANGE", "KIND_MODIFIER");
    INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType) VALUES 
    ("RUIVO_MODIFIER_PLAYER_DISTRICTS_ADJUST_BASE_YIELD_CHANGE", "COLLECTION_PLAYER_DISTRICTS", "EFFECT_ADJUST_DISTRICT_BASE_YIELD_CHANGE");
--自制modifier:区域自身相邻加成系数
    INSERT INTO Types (Type, Kind) VALUES 
    ("RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_YIELD_MODIFIER", "KIND_MODIFIER");
    INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType) VALUES 
    ("RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_YIELD_MODIFIER", "COLLECTION_OWNER", "EFFECT_ADJUST_DISTRICT_YIELD_MODIFIER");
--自制modifier:区域获得旅游业绩加成
    INSERT INTO Types (Type, Kind) VALUES
    ('RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType) VALUES
    ('RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 'EFFECT_ADJUST_DISTRICT_TOURISM_CHANGE', 'COLLECTION_OWNER');
--自制modifier:增加来自区域的住房
    INSERT INTO Types (Type, Kind) VALUES
    ('RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_DISTRICT_HOUSING', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType) VALUES
    ('RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_DISTRICT_HOUSING', 'EFFECT_ADJUST_DISTRICT_HOUSING', 'COLLECTION_OWNER');
--自制modifier:增加本城忠诚度--来自迭起兴衰
    INSERT INTO Types (Type, Kind) VALUES
    ('RUIVO_MODIFIER_OWNER_CITY_ADJUST_IDENTITY_PER_TURN', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType)
    SELECT 'RUIVO_MODIFIER_OWNER_CITY_ADJUST_IDENTITY_PER_TURN', 'EFFECT_ADJUST_CITY_IDENTITY_PER_TURN', 'COLLECTION_OWNER_CITY'
    WHERE EXISTS (SELECT 1 FROM Types WHERE Type = 'EFFECT_ADJUST_CITY_IDENTITY_PER_TURN');
--自制modifier:为本城提供清洁电力系数--来自风云变幻
    INSERT INTO Types (Type, Kind)
    VALUES
    ('RUIVO_MODIFIER_OWNER_CITIE_ADJUST_MODIFIED_FREE_POWER', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType)
    SELECT 'RUIVO_MODIFIER_OWNER_CITIE_ADJUST_MODIFIED_FREE_POWER', 'EFFECT_ADJUST_MODIFIED_FREE_POWER_IN_CITY', 'COLLECTION_OWNER_CITY'
    WHERE EXISTS (SELECT 1 FROM Types WHERE Type = 'EFFECT_ADJUST_MODIFIED_FREE_POWER_IN_CITY');
--============================================================================================================================


--============================================================================================================================
--modifier部分
    INSERT INTO Modifiers (ModifierId,              ModifierType,                                               OwnerRequirementSetId,                         SubjectRequirementSetId)
    SELECT           ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_DISTRICT_ADJUST_BASE_YIELD_CHANGE',        'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfBonus'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_PLAYER_DISTRICTS_ADJUST_BASE_YIELD_CHANGE', 'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, 'REQUIREMENT_RUIVO_ADJACENT_TO_OWNER_DISTRICT'   FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'ProvideToADJ'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_YIELD_MODIFIER',     'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfMultiplier'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE',     'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfTourism'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_SINGLE_CITY_ADJUST_FREE_POWER',                   'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfPower'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_OWNER_CITIE_ADJUST_MODIFIED_FREE_POWER',    'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfPowerModifier'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_DISTRICT_ADJUST_DISTRICT_AMENITY',         'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfAmenity'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_PLAYER_DISTRICT_ADJUST_DISTRICT_HOUSING',   'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfHousing'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_OWNER_CITY_ADJUST_IDENTITY_PER_TURN',       'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfLoyalty'    
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_ADJUST_INFLUENCE_POINTS_PER_TURN',         'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfInfluence'    
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_ADJUST_EXTRA_FAVOR_PER_TURN',              'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfFavor'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_CAPACITY',              'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfTradeRoute'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_ADJUST_GREAT_PERSON_POINTS',               'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'GreatPersonPoints'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_PLAYER_ADJUST_GREAT_PERSON_POINTS_PERCENT',       'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'GreatPersonMultiplier'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_SINGLE_CITY_ADJUST_FREE_RESOURCE_EXTRACTION',     'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfExtractResource'
    UNION SELECT     ListA.ID || '_' || ListB.Num, 'MODIFIER_SINGLE_CITY_EXTRA_DISTRICT',                      'REQUIREMENT_' || ListA.ID || '_' || ListB.Num, NULL                                             FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ProvideType = 'SelfExtraDistrictSlot'
    ;

    INSERT INTO ModifierArguments (ModifierId,                          Name,                   Value)
    SELECT           ListA.ID || '_' || ListB.Num,                     'YieldType',             ListA.YieldType         		FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0
    UNION SELECT     ListA.ID || '_' || ListB.Num,                     'Amount',                ListB.Num                       FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0
    UNION SELECT     ListA.ID || '_' || ListB.Num,                     'SourceType',           'FREE_POWER_SOURCE_MISC'         FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND  ListA.ProvideType = 'SelfPower'
    UNION SELECT     ListA.ID || '_' || ListB.Num,                     'GreatPersonClassType',  ListA.YieldType                 FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND (ListA.ProvideType = 'GreatPersonPoints' OR ListA.ProvideType = 'GreatPersonMultiplier')
    UNION SELECT     ListA.ID || '_' || ListB.Num,                     'ResourceType',          ListA.YieldType                 FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND  ListA.ProvideType = 'SelfExtractResource'
    ;
--============================================================================================================================
--REQ组装部分
--相邻几个对象
    INSERT INTO RequirementSets (RequirementSetId,                      RequirementSetType)
    SELECT          'REQUIREMENT_' || ListA.ID || '_' || ListB.Num,    'REQUIREMENTSET_TEST_ALL'                         	FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1;

    INSERT INTO RequirementSetRequirements (RequirementSetId,           RequirementId)
    SELECT          'REQUIREMENT_' || ListA.ID || '_' || ListB.Num,    'REQUIRES_' || ListA.ID || '_' || ListB.Num     		FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1;

    INSERT INTO Requirements (RequirementId,                            RequirementType)
    SELECT          'REQUIRES_' || ListA.ID || '_' || ListB.Num,       'REQUIREMENT_PLOT_PROPERTY_MATCHES'                  FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1;

    INSERT INTO RequirementArguments (RequirementId,                    Name,                 Value)
    SELECT          'REQUIRES_' || ListA.ID || '_' || ListB.Num,       'PropertyName',       ListA.ID || '_' || ListB.Num   FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1
    UNION SELECT    'REQUIRES_' || ListA.ID || '_' || ListB.Num,       'PropertyMinimum',    1                          	FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1;
--req相邻拥有者，环数为1环
    INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
    ("REQUIREMENT_RUIVO_ADJACENT_TO_OWNER_DISTRICT", "REQUIREMENTSET_TEST_ALL");
    INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
    ("REQUIREMENT_RUIVO_ADJACENT_TO_OWNER_DISTRICT", "REQUIRES_RUIVO_ADJACENT_TO_OWNER_DISTRICT");
    INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
    ("REQUIRES_RUIVO_ADJACENT_TO_OWNER_DISTRICT", "REQUIREMENT_PLOT_ADJACENT_TO_OWNER");
    INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
    ("REQUIRES_RUIVO_ADJACENT_TO_OWNER_DISTRICT", "MaxDistance", 1);
--============================================================================================================================


--以下为决定发起者的部分
--============================================================================================================================
--发起者为区域本体，modifier绑给区域部分
--有对应的区域才会在sql里加入，可以防止神秘报错
    INSERT INTO DistrictModifiers (DistrictType, ModifierId)
    SELECT                   ListA.DistrictType, ListA.ID || '_' || ListB.Num

    FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 
    WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'DistrictModifiers'
    AND EXISTS (SELECT 1 FROM Districts WHERE DistrictType = ListA.DistrictType);
--============================================================================================================================


--============================================================================================================================
--非区域本体的发起者，记得改一下ModifierId和Type的顺序！！！
--发起者为建筑
    INSERT INTO BuildingModifiers (ModifierId, BuildingType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'BuildingModifiers';
--发起者为政策卡
    INSERT INTO PolicyModifiers (ModifierId, PolicyType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'PolicyModifiers';
--发起者为科技
    INSERT INTO TechnologyModifiers (ModifierId, TechnologyType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'TechnologyModifiers';
--发起者为市政
    INSERT INTO CivicModifiers (ModifierId, CivicType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'CivicModifiers';
--发起者为政体
    INSERT INTO GovernmentModifiers (ModifierId, GovernmentType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'GovernmentModifiers';
--发起者为信仰（万神/信条）
    INSERT INTO BeliefModifiers (ModifierId, BeliefType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'BeliefModifiers';
--发起者为总督升级
    INSERT INTO GovernorPromotionModifiers (ModifierId, GovernorPromotionType) SELECT
    'ATTACH_' || ListA.ID || '_' || ListB.Num,  ListA.WhoIsTheOwner     FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner = 'GovernorPromotionModifiers';
--============================================================================================================================


--以下为作用范围的部分
--============================================================================================================================
--自制modifier:给本城的所有区域贴modifier
    INSERT INTO Types (Type, Kind) VALUES
    ('RUIVO_MODIFIER_OWNER_CITY_DISTRICTS_ATTACH_MODIFIER', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType) VALUES
    ('RUIVO_MODIFIER_OWNER_CITY_DISTRICTS_ATTACH_MODIFIER', 'EFFECT_ATTACH_MODIFIER', 'COLLECTION_CITY_DISTRICTS');
--自制modifier:给玩家的所有区域贴modifier
    INSERT INTO Types (Type, Kind) VALUES
    ('RUIVO_MODIFIER_PLAYER_ALL_DISTRICTS_ATTACH_MODIFIER', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType) VALUES
    ('RUIVO_MODIFIER_PLAYER_ALL_DISTRICTS_ATTACH_MODIFIER', 'EFFECT_ATTACH_MODIFIER', 'COLLECTION_PLAYER_DISTRICTS');
--自制modifier:给本场游戏所有区域贴modifier
    INSERT INTO Types (Type, Kind) VALUES
    ('RUIVO_MODIFIER_ALL_DISTRICTS_ATTACH_MODIFIER', 'KIND_MODIFIER');
    INSERT INTO DynamicModifiers (ModifierType, EffectType, CollectionType) VALUES
    ('RUIVO_MODIFIER_ALL_DISTRICTS_ATTACH_MODIFIER', 'EFFECT_ATTACH_MODIFIER', 'COLLECTION_ALL_DISTRICTS');
--============================================================================================================================

--============================================================================================================================
--作用目标为：本城所有区域，玩家所有区域
    INSERT INTO Modifiers         (ModifierId, ModifierType) 
    SELECT       'ATTACH_' || ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_OWNER_CITY_DISTRICTS_ATTACH_MODIFIER'   FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner != 'DistrictModifiers' AND ListA.CollectionType = 'COLLECTION_CITY_DISTRICTS'
    UNION SELECT 'ATTACH_' || ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_PLAYER_ALL_DISTRICTS_ATTACH_MODIFIER'   FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner != 'DistrictModifiers' AND ListA.CollectionType = 'COLLECTION_PLAYER_DISTRICTS'
    UNION SELECT 'ATTACH_' || ListA.ID || '_' || ListB.Num, 'RUIVO_MODIFIER_ALL_DISTRICTS_ATTACH_MODIFIER'          FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner != 'DistrictModifiers' AND ListA.CollectionType = 'COLLECTION_ALL_DISTRICTS'
    ;
    INSERT INTO ModifierArguments (ModifierId, Name, Value) SELECT
                 'ATTACH_' || ListA.ID || '_' || ListB.Num, 'ModifierId', ListA.ID || '_' || ListB.Num              FROM Ruivo_New_Adjacency ListA JOIN Ruivo_BinaryList ListB ON 1=1 WHERE ListA.FreeCompose = 0 AND ListA.ModifierOwner != 'DistrictModifiers';
--============================================================================================================================



--============================================================================================================================
--补充给UD：
    INSERT OR IGNORE INTO Ruivo_New_Adjacency
    (                                        ID,             DistrictType,     TraitType, ApplyForUniqueDistricts,       ProvideType,       YieldType,       YieldChange,       AdjacencyType,       CustomAdjacentObject,       Rings,       ModifierOwner,       WhoIsTheOwner,       CollectionType,       Only,       FreeCompose) SELECT 
    DR.CivUniqueDistrictType || "_" || Ruivo.ID, DR.CivUniqueDistrictType, Dis.TraitType,                       0, Ruivo.ProvideType, Ruivo.YieldType, Ruivo.YieldChange, Ruivo.AdjacencyType, Ruivo.CustomAdjacentObject, Ruivo.Rings, Ruivo.ModifierOwner, Ruivo.WhoIsTheOwner, Ruivo.CollectionType, Ruivo.Only, Ruivo.FreeCompose

    FROM Districts AS d                                                     --遍历区域表   
    JOIN DistrictReplaces DR ON d.DistrictType = DR.ReplacesDistrictType    --取代区域为对应区域
    JOIN Ruivo_New_Adjacency Ruivo ON d.DistrictType = Ruivo.DistrictType   --将全新系列加成表映射给取代的特色区域
    JOIN Districts Dis ON DR.CivUniqueDistrictType = Dis.DistrictType       --再次回到区域表，取出数值
    WHERE Ruivo.TraitType IS NULL                                           --排除需要由特质发起的行
    AND Ruivo.ApplyForUniqueDistricts = 1                                   --应用于特色区域的相邻加成
    ;
--============================================================================================================================

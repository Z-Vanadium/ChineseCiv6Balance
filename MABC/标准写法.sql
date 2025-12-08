--============================================================================================================================
/*  提供类型ProvideType  产出类型YieldType
    SelfBonus           ——>给自己相邻加成(6种基础产出)
    SelfMultiplier      ——>给自己系数而不是产出 (6种基础产出)
                        YIELD_FOOD          ——>食物
                        YIELD_PRODUCTION    ——>生产力
                        YIELD_GOLD          ——>金币
                        YIELD_SCIENCE       ——>科技
                        YIELD_CULTURE       ——>文化
                        YIELD_FAITH         ——>信仰
                        YIELD_NONE          ——>无产出
    
    注：ProvideToADJ无法显示，且会导致AI倾向扭曲！！！
    
    SelfPower               YIELD_POWER             ——>给自己清洁电力
    SelfPowerModifier       YIELD_POWER             ——>给本城清洁电力系数
    SelfTourism             YIELD_TOURISM           ——>给自己旅游业绩
    SelfAmenity             YIELD_AMENITY           ——>给自己宜居度
    SelfHousing             YIELD_HOUSING           ——>给自己住房
    SelfLoyalty             YIELD_LOYALTY           ——>给自己忠诚度
    SelfInfluence           YIELD_INFLUENCE         ——>给自己影响力
    SelfFavor               YIELD_FAVOR             ——>给自己外交支持点
    SelfTradeRoute          YIELD_TRADE_ROUTE       ——>给自己贸易路线容量
    SelfExtraDistrictSlot   YIELD_DISTRICT_SLOT     ——>给自己额外区域位

    SelfExtractResource     RESOURCE_SUCH_AS_STRATEGIC ——>给自己可累计的资源产出（比如战略资源）

    GreatPersonPoints       ——>伟人点
    GreatPersonMultiplier   ——>伟人点系数
    填伟人类型即可，比如  GREAT_PERSON_CLASS_PROPHET 大预言家

                        YIELD_NONE          ——>无产出

    TriggerFunction ——>激活函数（使用此类型时请打开FreeCompose = 1 ）
*/


/*  相邻类型AdjacencyType
    在 “NEW_ADJACENCY_BONUS_BY_RUIVO_CORE_TABLE.sql” 文件的
    Ruivo_AdjacencyType表里
*/


/*  自定义相邻目标CustomAdjacentObject
    
    ======================================================
    6种基本产出：        YIELD_FOOD          ——>食物
                        YIELD_PRODUCTION    ——>生产力
                        YIELD_GOLD          ——>金币
                        YIELD_SCIENCE       ——>科技
                        YIELD_CULTURE       ——>文化
                        YIELD_FAITH         ——>信仰

        FROM_CITY_CAO_YIELD         ——>来自城市产出：
        FROM_HIGHEST_HUMAN_YIELD    ——>来自最高人类玩家产出
    ======================================================
*/


/*  发起者类型ModifierOwner
    DistrictModifiers   区域 COLLECTION_CITY_DISTRICTS
    BuildingModifiers   建筑 COLLECTION_CITY_DISTRICTS COLLECTION_PLAYER_DISTRICTS
    PolicyModifiers     政策                           COLLECTION_PLAYER_DISTRICTS
    TechnologyModifiers 科技                           COLLECTION_PLAYER_DISTRICTS
    CivicModifiers      市政                           COLLECTION_PLAYER_DISTRICTS
    GovernmentModifiers 政体                           COLLECTION_PLAYER_DISTRICTS
    BeliefModifiers     信仰 COLLECTION_ALL_DISTRICTS

    GovernorPromotionModifiers（WIP）（没做完不要用）
                        总督升级 COLLECTION_CITY_DISTRICTS COLLECTION_PLAYER_DISTRICTS
*/


/*  仅AI或仅人类Only
    Only TEXT NOT NULL CHECK (Only IN ('Human&AI', 'OnlyHuman', 'OnlyAI')) DEFAULT 'Human&AI'
    'Human&AI'
    'OnlyHuman'
    'OnlyAI'
*/


/*  标准写法
    ID一定是不重复的，建议命名规则：某个前缀_区域_产出类型_相邻来源
    这个意思很直白，就是XX区域获得XX产出来自XX相邻对象
    特色区域不一定需要填trait，但是为了性能考虑，建议补上

    示例语句：
    （注：SQL语言编译只读逗号和分号，随便换行和空格皆可）

    INSERT INTO Ruivo_New_Adjacency 
    (ID, DistrictType,                              -->ID和区域（注意，一定要以区域为主体，ID是主键，不要重复）
    ProvideType, YieldType, YieldChange,            -->提供的产出分类、产出类型、产出量（产出类型一定要严格对应产出分类，比如商路对应商路大类）
    AdjacencyType, CustomAdjacentObject,            -->相邻类型、自定义指定相邻目标（指定相邻目标依赖于相邻类型）
    DistrictModifiers, TraitType,                   -->是否为区域通用（0/1） 是否来自于特质（填了这个可以不填前面那个）      
    ModifierOwner, WhoIsTheOwner, CollectionType,   -->实际来源类型、来源目标、作用目标
    Only,                                           -->是否为人类/AI独享
    FreeCompose)                                    -->自由组装模式

    VALUES 
    ('RUIVO_DISTRICT_DAM_YIELD_FOOD_FROM_RIVER_CROSSING', 'DISTRICT_DAM', 
    'SelfBonus', 'YIELD_FOOD', 1.0, 
    'FROM_RIVER_CROSSING', 'NONE', 
    1, NULL, 
    'DistrictModifiers', NULL, 'COLLECTION_CITY_DISTRICTS', 
    'Human&AI', 
    0);
*/


/*  自定义相邻文本

    INSERT INTO Ruivo_New_Adjacency_Text (ID, Tooltip) VALUES
    ('RUIVO_DISTRICT_DAM_YIELD_FOOD_FROM_RIVER_CROSSING','LOC_RUIVO_DISTRICT_DAM_YIELD_FOOD_FROM_RIVER_CROSSING');

	<Row Tag="LOC_RUIVO_DISTRICT_DAM_YIELD_FOOD_FROM_RIVER_CROSSING" Language="zh_Hans_CN">
		<Text>+{1_iBonus} {2_YieldIcon} 食物产出来自相邻 {3_AdjacentSubjectNum} 段河流</Text>
	</Row>
*/
--============================================================================================================================
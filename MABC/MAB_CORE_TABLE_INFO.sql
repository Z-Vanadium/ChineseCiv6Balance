--============================================================================================================================
--全局参数，判断开没开马良相邻
    INSERT INTO GlobalParameters (Name, Value) VALUES 
    ('RUIVO_MODULAR_ADJACENCY_BONUS_ABLED', '1');
--============================================================================================================================


--============================================================================================================================
--相邻类型表
    CREATE TABLE Ruivo_AdjacencyType (
        --相邻类型
        AdjacencyType TEXT PRIMARY KEY NOT NULL,

        --属性来源类型
        AttributeType TEXT NOT NULL,

        --是否存在指定相邻对象
        HasCustomAdjacentObject BOOLEAN NOT NULL CHECK (HasCustomAdjacentObject IN (0, 1)),

        --游戏环境
        Environment TEXT NOT NULL CHECK (Environment IN ("GamePlay", "UserInterface")),

        --能否显示（也就是是否为 GamePlay Only 独占）
        CanDisplay BOOLEAN NOT NULL CHECK (CanDisplay IN (0, 1)),

        --相邻显示文本
        Tooltip TEXT NOT NULL
    );
    INSERT INTO Ruivo_AdjacencyType 
(AdjacencyType, AttributeType, HasCustomAdjacentObject, Environment, CanDisplay, Tooltip) VALUES
    --全局无条件加成
    ('FROM_UNCONDITIONAL_BONUS',         'General', 0, 'GamePlay', 1, '无条件加成'),
    ('FROM_STORM_HAPPEND',               'General', 0, 'GamePlay', 1, '本局风暴发生次数'),
    ('FROM_STANDARDIZE_TURNS',           'General', 0, 'GamePlay', 1, '标准化回合数（当前回合/速度系数）'),

    --全局UI无条件加成
    ('FROM_UI_SEA_LEVEL',                'General', 0, 'UserInterface', 1, '本局游戏的气候变化点数'),

    --全局自定义相邻对象
    ('FROM_HIGHEST_HUMAN_YIELD',         'General', 1, 'GamePlay', 1, '指定产出类型的最高人类玩家产出值，可填6种基本产出'),
    

    --property体系！！！
    ('FROM_GAME_PROPERTY',                  'Game', 1, 'GamePlay', 1, '游戏property（通常来自lua）'),
    ('FROM_GAME_PROPERTY_HASHED',           'Game', 1, 'GamePlay', 1, '哈希化的游戏property（通常来自modifier）'),

    ('FROM_PLOT_PROPERTY',                  'Plot', 1, 'GamePlay', 1, '单元格property（通常来自lua）'),
    ('FROM_PLOT_PROPERTY_HASHED',           'Plot', 1, 'GamePlay', 1, '哈希化的单元格property（通常来自modifier）'),

    ('FROM_CITY_PROPERTY',                  'City', 1, 'GamePlay', 1, '城市property（通常来自lua）'),
    ('FROM_CITY_PROPERTY_HASHED',           'City', 1, 'GamePlay', 1, '哈希化的城市property（通常来自modifier）'),

    ('FROM_PLAYER_PROPERTY',              'Player', 1, 'GamePlay', 1, '玩家property（通常来自lua）'),
    ('FROM_PLAYER_PROPERTY_HASHED',       'Player', 1, 'GamePlay', 1, '哈希化的玩家property（通常来自modifier）'),


    --单元格属性
    --原版基本相邻，并且带环数
    ('FROM_RINGS_TYPETAG_RESOURCE',         'plot', 1, 'GamePlay', 1, '环数内的指定tag对应的资源'),
    ('FROM_RINGS_CAO_RESOURCE',             'plot', 1, 'GamePlay', 1, '环数内的指定资源'),
    ('FROM_RINGS_CAO_IMPROVEMENT',          'plot', 1, 'GamePlay', 1, '环数内的指定改良'),
    ('FROM_RINGS_CAO_DISTRICT',             'plot', 1, 'GamePlay', 1, '环数内的指定区域'),
    ('FROM_RINGS_CAO_FEATURE',              'plot', 1, 'GamePlay', 1, '环数内的指定地貌'),
    ('FROM_RINGS_CAO_TERRAIN_SETS',         'plot', 1, 'GamePlay', 1, '环数内的指定函数地形（注：这个的CAO是地形判断函数）'),
    ('FROM_RINGS_CAO_TERRAIN',              'plot', 1, 'GamePlay', 1, '环数内的指定地形（这个可以正常填地形）'),

    --其他相邻，带环数
    ('FROM_RINGS_NATIONALPARK',             'plot', 0, 'GamePlay', 1, '环数内的国家公园'),

    --其他相邻，无环数
    ('FROM_LAND_WATER_PAIR',                'plot', 0, 'GamePlay', 1, '相邻每对水陆地势（最高3对）'),
    ('FROM_RIVER_CROSSING',                 'plot', 0, 'GamePlay', 1, '相邻河流每个面'),
    ('FROM_ADJACENT_ROUTE',                 'plot', 0, 'GamePlay', 1, '相邻每个等级的道路'),
    ('FROM_SELF_ROUTE',                     'plot', 0, 'GamePlay', 1, '本格道路等级'),
    ('FROM_ADJACENT_WORKER',                'plot', 0, 'GamePlay', 1, '相邻在岗公民'),
    ('FROM_SELF_WORKER',                    'plot', 0, 'GamePlay', 1, '本区域内在岗公民'),
    ('FROM_ADJACENT_UNIT',                  'plot', 0, 'GamePlay', 1, '相邻单位'),
    ('FROM_ADJACENT_DISTRICT',              'plot', 0, 'GamePlay', 1, '相邻区域'),
    ('FROM_ADJACENT_DISTRICT_AND_WONDER',   'plot', 0, 'GamePlay', 1, '相邻区域和人造奇观（即使未建成）'),
    ('FROM_CLIFF',                          'plot', 0, 'GamePlay', 1, '单元格有无悬崖'),
    ('FROM_LATITUDE',                       'plot', 0, 'GamePlay', 1, '从宇航标准线到赤道距离的百分比'),
    ('FROM_POLE',                           'plot', 0, 'GamePlay', 1, '从宇航标准线到极地距离的百分比'),
    ('FROM_ADJACENT_LAKE',                  'plot', 0, 'GamePlay', 1, '相邻淡水湖数量'),
    ('FROM_ADJACENT_WATER_LEVEL',           'plot', 0, 'GamePlay', 1, '相邻淡水等级（无水0，咸水1，淡水3）'),
    ('FROM_SELF_WATER_LEVEL',               'plot', 0, 'GamePlay', 1, '本格淡水等级（无水0，咸水1，淡水3）'),
    ('FROM_ADJACENT_RESOURCE',              'plot', 0, 'GamePlay', 1, '相邻资源数量（即使不可见）'),
    ('FROM_ADJACENT_WONDERS',               'plot', 0, 'GamePlay', 1, '相邻已完工的人造奇观数量'),
    --UI单元格属性
    ('FROM_UI_SELF_UNIT_LEVELS',            'plot', 0, 'UserInterface', 1, '本格的单位等级总和'),
    ('FROM_UI_ADJACENT_UNIT_LEVELS',        'plot', 0, 'UserInterface', 1, '相邻的单位等级总和'),
    ('FROM_UI_SELF_APPEAL',                 'plot', 0, 'UserInterface', 1, '本单元格的魅力'),
    ('FROM_UI_ADJACENT_APPEAL',             'plot', 0, 'UserInterface', 1, '相邻单元格的魅力'),
    ('FROM_UI_ADJACENT_YIELD_FOOD',         'plot', 0, 'UserInterface', 1, '相邻单元格的食物'),
    ('FROM_UI_ADJACENT_YIELD_PRODUCTION',   'plot', 0, 'UserInterface', 1, '相邻单元格的生产力'),
    ('FROM_UI_ADJACENT_YIELD_GOLD',         'plot', 0, 'UserInterface', 1, '相邻单元格的金币'),
    ('FROM_UI_ADJACENT_YIELD_SCIENCE',      'plot', 0, 'UserInterface', 1, '相邻单元格的科技'),
    ('FROM_UI_ADJACENT_YIELD_CULTURE',      'plot', 0, 'UserInterface', 1, '相邻单元格的文化'),
    ('FROM_UI_ADJACENT_YIELD_FAITH',        'plot', 0, 'UserInterface', 1, '相邻单元格的信仰'),


    --城市属性
    ('FROM_CITY_POPULATION',                'City', 0, 'GamePlay', 1, '城市人口总数'),
    ('FROM_CITY_TOTAL_HOUSING',             'City', 0, 'GamePlay', 1, '城市住房总数'),
    ('FROM_CITY_SURPLUS_HOUSING',           'City', 0, 'GamePlay', 1, '城市剩余住房数'),
    ('FROM_CITY_DISTRICTS_NUM',             'City', 0, 'GamePlay', 1, '城市区域总数（不包括市中心和奇观）'),
    ('FROM_CITY_SURPLUS_FOOD',              'City', 0, 'GamePlay', 1, '城市余粮数量'),
    ('FROM_CITY_SURPLUS_AMENITIES',         'City', 0, 'GamePlay', 1, '城市溢出宜居度'),
    ('FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS','City', 0, 'GamePlay', 1, '城市超过顶级幸福度部分的宜居度'),
    ('FROM_CITY_DEFENSE_STRENGTH',          'City', 0, 'GamePlay', 1, '城市防御力'),
    --城市属性：自定义相邻对象
    ('FROM_CITY_CAO_YIELD',                 'City', 1, 'GamePlay', 1, '城市对应产出，可填6种基本产出'),
    --城市UI属性
    ('FROM_UI_CITY_DISTRICT_SLOT',          'City', 0, 'UserInterface', 1, '城市区域位'),
    ('FROM_UI_CITY_SURPLUS_DISTRICT_SLOT',  'City', 0, 'UserInterface', 1, '城市剩余区域位'),

    ('FROM_UI_CITY_FREE_POWER',             'City', 0, 'UserInterface', 1, '城市清洁电力'),
    ('FROM_UI_CITY_TEMPORARY_POWER',        'City', 0, 'UserInterface', 1, '城市临时电力'),
    ('FROM_UI_CITY_REQUIRED_POWER',         'City', 0, 'UserInterface', 1, '城市需求电力'),
    ('FROM_UI_CITY_CURRENT_POWER',          'City', 0, 'UserInterface', 1, '城市总电力'),
    ('FROM_UI_CITY_SURPLUS_POWER',          'City', 0, 'UserInterface', 1, '城市溢出电力'),
    ('FROM_UI_CITY_POWER_RATIO',            'City', 0, 'UserInterface', 1, '城市供电率'),
    ('FROM_UI_CITY_LOYALTY_PERTURN',        'City', 0, 'UserInterface', 1, '城市忠诚度'),
    ('FROM_UI_CITY_LOYALTY_PERCENT',        'City', 0, 'UserInterface', 1, '城市忠诚率'),


    --玩家属性
    ('FROM_PLAYER_TECHS_NUM',             'Player', 0, 'GamePlay', 1, '玩家科技种类（不包括循环科技）'),
    ('FROM_PLAYER_CIVICS_NUM',            'Player', 0, 'GamePlay', 1, '玩家市政种类（不包括循环市政）'),
    ('FROM_OUTGOING_ROUTES',              'Player', 0, 'GamePlay', 1, '玩家经营的商路数量'),
    ('FROM_SLOT_MILITARY',                'Player', 0, 'GamePlay', 1, '玩家军事卡数量'),
    ('FROM_SLOT_ECONOMIC',                'Player', 0, 'GamePlay', 1, '玩家经济卡数量'),
    ('FROM_SLOT_DIPLOMATIC',              'Player', 0, 'GamePlay', 1, '玩家外交卡数量'),
    ('FROM_SLOT_GREAT_PERSON',            'Player', 0, 'GamePlay', 1, '玩家伟人卡数量'),
    ('FROM_SLOT_WILDCARD',                'Player', 0, 'GamePlay', 1, '玩家通配卡数量'),
    ('FROM_PLAYER_TOTAL_UNITS',           'Player', 0, 'GamePlay', 1, '玩家总单位数量'),
    ('FROM_PLAYER_RESOURCES_TYPES',       'Player', 0, 'GamePlay', 1, '玩家持有资源类型总数'),
    ('FROM_CAO_IMPROVEMENT_RESOURCE_TYPES','Player', 1, 'GamePlay', 1, '玩家持有资源类型总数（对应改良的）'),

    --玩家UI属性
    ('FROM_UI_MILITARY_STRENGTH',         'Player', 0, 'UserInterface', 1, '玩家总军事战力'),



    --不可显示的属性
    --宗教属性
    ('FROM_RELIGION_FAITH_YIELD',           'Religion', 0, 'GamePlay', 0, '总信仰产出'),
    ('FROM_RELIGION_BELIEFS_COUNT',         'Religion', 0, 'GamePlay', 0, '信条数量'),
    ('FROM_RELIGION_TOTAL_FOLLOWERS',       'Religion', 0, 'GamePlay', 0, '总信徒数量'),
    ('FROM_RELIGION_FOREIGN_FOLLOWERS',     'Religion', 0, 'GamePlay', 0, '国外信徒数量'),
    ('FROM_RELIGION_DOMESTIC_FOLLOWERS',    'Religion', 0, 'GamePlay', 0, '国内信徒数量'),
    ('FROM_RELIGION_TOTAL_CITIES_FOLLOWING','Religion', 0, 'GamePlay', 0, '总信仰城市数量'),
    ('FROM_RELIGION_CITIES_WITH_WONDER',    'Religion', 0, 'GamePlay', 0, '总信仰城市数量（拥有人造奇观）'),
    ('FROM_RELIGION_FOREIGN_CITIES',        'Religion', 0, 'GamePlay', 0, '国外信仰城市数量'),
    ('FROM_RELIGION_DOMESTIC_CITIES',       'Religion', 0, 'GamePlay', 0, '国内信仰城市数量'),
    ('FROM_RELIGION_CITY_PLAYER_FOLLOWERS', 'Religion', 0, 'GamePlay', 0, '本城的信仰玩家宗教信徒数量（即使不是本城主流宗教）'),
    
    
    --区域自身产出
    ('FROM_SELF_YIELD_FOOD',                    'plot', 0, 'GamePlay', 0, '区域自身粮食'),
    ('FROM_SELF_YIELD_PRODUCTION',              'plot', 0, 'GamePlay', 0, '区域自身生产力'),
    ('FROM_SELF_YIELD_GOLD',                    'plot', 0, 'GamePlay', 0, '区域自身金币'),
    ('FROM_SELF_YIELD_SCIENCE',                 'plot', 0, 'GamePlay', 0, '区域自身科技'),
    ('FROM_SELF_YIELD_CULTURE',                 'plot', 0, 'GamePlay', 0, '区域自身文化'),
    ('FROM_SELF_YIELD_FAITH',                   'plot', 0, 'GamePlay', 0, '区域自身信仰');
--============================================================================================================================


--============================================================================================================================
--地形函数（FROM_RINGS_CAO_TERRAIN_SETS）
    CREATE TABLE Ruivo_Terrain_Function (
        FunctionType TEXT PRIMARY KEY NOT NULL, 
        Name TEXT NOT NULL
    );

    INSERT INTO Ruivo_Terrain_Function (FunctionType, Name) VALUES
    ("IsMountain",       "LOC_RUIVO_ISMOUNTAIN"),
    ("IsHills",          "LOC_RUIVO_ISHILLS"),
    ("IsFlatlands",      "LOC_RUIVO_ISFLATLANDS"),
    ("IsWater",          "LOC_RUIVO_ISWATER"),
    ("IsShallowWater",   "LOC_RUIVO_ISSHALLOWWATER"),
    ("IsLake",           "LOC_RUIVO_ISLAKE"),
    ("IsCanyon",         "LOC_RUIVO_ISCANYON"),
    ("IsCoastalLand",    "LOC_RUIVO_ISCOASTALLAND"),
    ("IsRiverCrossing",  "LOC_RUIVO_ISRIVERCROSSING"),
    ("IsOpenGround",     "LOC_RUIVO_ISOPENGROUND"),
    ("IsRoughGround",    "LOC_RUIVO_ISROUGHGROUND");
--============================================================================================================================


--============================================================================================================================
--相邻对象的文本（CustomAdjacentObject）
    CREATE TABLE Ruivo_CAO (
        CustomAdjacentObject TEXT PRIMARY KEY NOT NULL, 
        Name TEXT NOT NULL
    );

    INSERT INTO Ruivo_CAO (CustomAdjacentObject, Name) VALUES
        ("CLASS_FOOD",                "LOC_RUIVO_CLASS_FOOD"),
        ("CLASS_CULTURE",             "LOC_RUIVO_CLASS_CULTURE"),
        ("CLASS_GOLD",                "LOC_RUIVO_CLASS_GOLD"),
        ("CLASS_PRODUCTION",          "LOC_RUIVO_CLASS_PRODUCTION"),
        ("CLASS_SCIENCE",             "LOC_RUIVO_CLASS_SCIENCE"),
        ("CLASS_ORAL_TRADITION",      "LOC_RUIVO_CLASS_ORAL_TRADITION"),
        ("CLASS_GODDESS_OF_FESTIVALS","LOC_RUIVO_CLASS_GODDESS_OF_FESTIVALS"),
        ("CLASS_SEA",                 "LOC_RUIVO_CLASS_SEA");
--============================================================================================================================


--============================================================================================================================
--产出类型的图标和名称
    CREATE TABLE Ruivo_Yield_IconString (
        YieldType   TEXT PRIMARY KEY NOT NULL,
        Name        TEXT NOT NULL,
        IconString  TEXT NOT NULL,
        TextColor   TEXT NOT NULL
    );
    INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor) VALUES
    ("HealRings", "LOC_RUIVO_HealRings", "[ICON_DAMAGED]", "[COLOR_GREEN]");
--============================================================================================================================


--============================================================================================================================
--二进制折叠矩阵表（1-512 → 1023）
    CREATE TABLE Ruivo_BinaryList (
        Num INTEGER PRIMARY KEY
    );
    INSERT INTO Ruivo_BinaryList (Num)
    VALUES (1), (2), (4), (8), (16), (32), (64), (128), (256), (512); --上限1023
--============================================================================================================================
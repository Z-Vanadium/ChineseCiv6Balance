--============================================================================================================================
--核心表
    CREATE TABLE Ruivo_New_Adjacency (
        --加成modifier的ID，用于property，modifier和req的命名
        ID TEXT PRIMARY KEY NOT NULL, 

        --区域类型
        DistrictType TEXT NOT NULL,

        --提供的加成类型
        ProvideType TEXT NOT NULL DEFAULT 'SelfBonus',

        --产出类型
        YieldType TEXT NOT NULL,

        --每个相邻对象提供的加成量
        YieldChange FLOAT NOT NULL DEFAULT 0,

        --相邻类型
        AdjacencyType TEXT NOT NULL,

        --自定义相邻目标
        CustomAdjacentObject TEXT NOT NULL DEFAULT 'NONE',

        --环数
        Rings INTEGER NOT NULL DEFAULT 1,

        --是否要把加成绑在DistrictModifiers上？与TraitType互斥，在lua中进行检测和排除，增强健壮性
        DistrictModifiers BOOLEAN NOT NULL CHECK (DistrictModifiers IN (0, 1)) DEFAULT 0,

        --是否应用于特色区域
        ApplyForUniqueDistricts BOOLEAN NOT NULL CHECK (ApplyForUniqueDistricts IN (0, 1)) DEFAULT 0,

        --是否要把加成绑在TraitModifiers上？默认NULL/nil，有文本视为true
        TraitType TEXT DEFAULT NULL,

        --Modifier发起者
        ModifierOwner TEXT NOT NULL DEFAULT 'DistrictModifiers',

        --实际发起对象：例如某个信条或建筑
        WhoIsTheOwner TEXT DEFAULT NULL,

        --作用对象
        CollectionType TEXT NOT NULL DEFAULT 'COLLECTION_CITY_DISTRICTS',

        --仅人类还是仅AI
        Only TEXT NOT NULL CHECK (Only IN ('Human&AI', 'OnlyHuman', 'OnlyAI')) DEFAULT 'Human&AI',

        --自由组装模式，开启后只保留REQ
        FreeCompose BOOLEAN NOT NULL CHECK (FreeCompose IN (0, 1)) DEFAULT 0
    );
--============================================================================================================================

--============================================================================================================================
--自定义tooltip表
    CREATE TABLE Ruivo_New_Adjacency_Text(
        ID TEXT PRIMARY KEY NOT NULL, 
        Tooltip TEXT NOT NULL
    );
--============================================================================================================================
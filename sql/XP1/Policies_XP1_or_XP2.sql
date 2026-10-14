--==============================================================
--******				    POLICIES					  ******
--==============================================================
-- Monks: Cards
INSERT INTO TypeTags(Type, Tag) VALUES
    ('ABILITY_FASCISM_ATTACK_BUFF', 'CLASS_WARRIOR_MONK'),
    ('ABILITY_FASCISM_LEGACY_ATTACK_BUFF', 'CLASS_WARRIOR_MONK'),
    ('ABILITY_TWILIGHT_VALOR_ATTACK_BONUS', 'CLASS_WARRIOR_MONK');

-- 2020/12/20 Pundit proposal accepted to revert Rationalism requirement to +3 (from +4)
UPDATE RequirementArguments SET Value=3 WHERE RequirementId='REQUIRES_CAMPUS_HAS_HIGH_ADJACENCY' AND Name='Amount';
UPDATE RequirementArguments SET Value=3 WHERE RequirementId='REQUIRES_HOLY_SITE_HAS_HIGH_ADJACENCY' AND Name='Amount';
UPDATE RequirementArguments SET Value=3 WHERE RequirementId='REQUIRES_THEATER_SQUARE_HAS_HIGH_ADJACENCY' AND Name='Amount';

-- 2021/08/24 Rationnalism at 13 population
-- /!\ AFFECT FOLLOWING MODIFIERS :
-- FREEMARKET_BUILDING_YIELDS_HIGH_POP, GRANDOPERA_BUILDING_YIELDS_HIGH_POP
-- RATIONALISM_BUILDING_YIELDS_HIGH_POP, SIMULTANEUM_BUILDING_YIELDS_HIGH_POP
UPDATE RequirementArguments SET Value=13 WHERE RequirementId='REQUIRES_CITY_HAS_HIGH_POPULATION' AND Name='Amount';

--5.2.5 buff autocracy (extend bonus to plaza/diplo quarter district AND diplo quarter buildings) -- moved from base
INSERT INTO PolicyModifiers (PolicyType, ModifierId) VALUES
    ('POLICY_GOV_AUTOCRACY', 'AUTOCRACY_PLAZA_DISTRICT'),
    ('POLICY_GOV_AUTOCRACY', 'AUTOCRACY_DIPLOMATIC_DISTRICT');

--5.2.6 CCB 2026/10/14：独裁传承卡完整继承「宫殿 / 市政广场区 / 外交区 / 其中的建筑」四类产出
--   （用户需求：二级卡未完全继承一级独裁卡全部效果，少了外交区、市政广场区本身的产出）
--   ⚠ 本段必须留在【本文件】（action BBG_XP1_OR_XP2，LoadOrder 11614）：
--     AUTOCRACY_* 修正器在同批的 Government_XP1_or_XP2.sql 内创建，晚于 Base 的 LegacyCards.sql（11600 段）；
--     若把挂载写进 LegacyCards.sql，执行时修正器尚不存在 → `Invalid Reference on PolicyModifiers.ModifierId`。
--   ⚠ 三级卡也不能靠 LegacyCards.sql §6.2 的「拷贝二级卡全部挂载」子查询继承 —— 那条在 11614 之前已执行完毕，
--     所以此处用一条 CROSS JOIN 一次覆盖全部 12 张独裁传承卡（3 张二级 + 9 张三级）。
--   ① 宫殿：原版一级卡本就带 AUTOCRACY_CAPITAL（Expansion1_Governments.xml 的 PolicyModifiers），
--      被 LegacyCards.sql:122 删除后重建时漏掉（当时建筑改用 30 条「6 产出」版，宫殿未重建）→ 此处补回。
--      注：处于独裁政体时引擎会隐藏该一级卡（RequiresGovernmentUnlock=1），故不会与政体固有双计。
INSERT INTO PolicyModifiers (PolicyType, ModifierId) VALUES
    ('POLICY_GOV_AUTOCRACY', 'AUTOCRACY_CAPITAL');

--   ② 宫殿 + 市政广场区本身 + 外交区本身：二级 3 张 + 三级 9 张
--      （30 条 CCB_AUTOCRACY_BONUS_* 已覆盖「9 个市政广场建筑 + 领事馆 + 大法官厅」，此处补齐另三类）
INSERT INTO PolicyModifiers (PolicyType, ModifierId)
SELECT P.PolicyType, M.ModifierId
FROM (SELECT PolicyType FROM Policies WHERE PolicyType LIKE 'POLICY_CCB_GOV_AUTOCRACY_%') P
CROSS JOIN (SELECT 'AUTOCRACY_CAPITAL' AS ModifierId
            UNION ALL SELECT 'AUTOCRACY_PLAZA_DISTRICT'
            UNION ALL SELECT 'AUTOCRACY_DIPLOMATIC_DISTRICT') M;

--==============================================================================================
--5.2.7 CCB 2026/10/14：独裁政体内「政体固有 × 传承升级卡」双计 → Lua 负向对冲
--   用户需求：独裁政体内挂二级/三级独裁传承卡，不应吃到两次独裁效果（沿用既有"Lua 反向对冲"方案）
--   口径 = 两侧真正重叠的 8 类，每类扣掉重复的一份（政体那侧照常生效 → 净额仍是"只算一次独裁"）：
--     PALACE    : AUTOCRACY_CAPITAL             ↔ 宫殿 +1 全产出
--     PLAZA     : AUTOCRACY_PLAZA_DISTRICT      ↔ 市政广场区本身
--     DQ        : AUTOCRACY_DIPLOMATIC_DISTRICT ↔ 外交区本身
--     GOVT1/2/3 : AUTOCRACY_TIER1/2/3           ↔ 卡内 30 条建筑奖励里的 GOVT1/2/3
--     CONSULATE : CONSULATE_TIER1               ↔ 卡内 30 条里的 CONSULATE
--     CHANCERY  : CHANCERY_TIER2                ↔ 卡内 30 条里的 CHANCERY
--   口径等价性已核实（2026-10-14 查调试库）：BUILDING_IS_TIER1/2/3 与 CCB_REQSET_CITY_HAS_GOVT1/2/3 同为
--     那 3 个市政广场建筑；BUILDING_IS_CONSULATE/CHANCERY 与 CCB_REQSET_CITY_HAS_CONSULATE/CHANCERY 同建筑
--     → 既不会漏扣（某城仍 +2），也不会多扣（某城被扣成 0）
--   纪念碑那对粮/锤（BBG_MONUMENT_* ↔ CCB_AUTOCRACY_BASE_*）由既有的 CCB_AUT_OFFSET_*_FOOD/_PROD 负责
--   ⚠ 修正器类型用单产出 MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE：与既有 CCB_AUT_OFFSET_*_FOOD/_PROD
--     同款，该类型的运行时 AttachModifierByID 已被 2026-10-10 探针矩阵验证可用；
--     不用 ADJUST_CITY_ALL_YIELDS_CHANGE 版是为了不引入"运行时挂载未验证"的新类型（16 条 vs 96 条不是理由）
--   ⚠ 必须「NEG −1 / POS +1」成对：引擎没有 detach，靠正负池对冲（见 scripts/ccb_legacycards.lua 的 OFFSET_LINES）
--   ⚠ 命名 CCB_AUT_OFFSET_{NEG|POS}_{类别}_{产出} 必须与 Lua 侧拼出的 ID 完全一致
--==============================================================================================
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT 'CCB_AUT_OFFSET_' || D.Dir || '_' || C.Cat || '_' || Y.YieldType,
       'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE', C.ReqSet
FROM (SELECT 'NEG' AS Dir UNION ALL SELECT 'POS') D
CROSS JOIN (
	SELECT 'PALACE' AS Cat, 'BUILDING_IS_PALACE' AS ReqSet UNION ALL
	SELECT 'PLAZA', 'CITY_HAS_GOV_DISTRICT_BBG_REQSET' UNION ALL
	SELECT 'DQ', 'CITY_HAS_DIPLOMATIC_DISTRICT_BBG_REQSET' UNION ALL
	SELECT 'GOVT1', 'CCB_REQSET_CITY_HAS_GOVT1' UNION ALL
	SELECT 'GOVT2', 'CCB_REQSET_CITY_HAS_GOVT2' UNION ALL
	SELECT 'GOVT3', 'CCB_REQSET_CITY_HAS_GOVT3' UNION ALL
	SELECT 'CONSULATE', 'CCB_REQSET_CITY_HAS_CONSULATE' UNION ALL
	SELECT 'CHANCERY', 'CCB_REQSET_CITY_HAS_CHANCERY'
) C
CROSS JOIN (
	SELECT 'YIELD_FOOD' AS YieldType UNION ALL SELECT 'YIELD_PRODUCTION' UNION ALL SELECT 'YIELD_GOLD' UNION ALL
	SELECT 'YIELD_SCIENCE' UNION ALL SELECT 'YIELD_CULTURE' UNION ALL SELECT 'YIELD_FAITH'
) Y;

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'CCB_AUT_OFFSET_' || D.Dir || '_' || C.Cat || '_' || Y.YieldType, 'YieldType', Y.YieldType
FROM (SELECT 'NEG' AS Dir UNION ALL SELECT 'POS') D
CROSS JOIN (
	SELECT 'PALACE' AS Cat UNION ALL SELECT 'PLAZA' UNION ALL SELECT 'DQ' UNION ALL SELECT 'GOVT1' UNION ALL
	SELECT 'GOVT2' UNION ALL SELECT 'GOVT3' UNION ALL SELECT 'CONSULATE' UNION ALL SELECT 'CHANCERY'
) C
CROSS JOIN (
	SELECT 'YIELD_FOOD' AS YieldType UNION ALL SELECT 'YIELD_PRODUCTION' UNION ALL SELECT 'YIELD_GOLD' UNION ALL
	SELECT 'YIELD_SCIENCE' UNION ALL SELECT 'YIELD_CULTURE' UNION ALL SELECT 'YIELD_FAITH'
) Y;

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'CCB_AUT_OFFSET_' || D.Dir || '_' || C.Cat || '_' || Y.YieldType, 'Amount', D.Amt
FROM (SELECT 'NEG' AS Dir, -1 AS Amt UNION ALL SELECT 'POS', 1) D
CROSS JOIN (
	SELECT 'PALACE' AS Cat UNION ALL SELECT 'PLAZA' UNION ALL SELECT 'DQ' UNION ALL SELECT 'GOVT1' UNION ALL
	SELECT 'GOVT2' UNION ALL SELECT 'GOVT3' UNION ALL SELECT 'CONSULATE' UNION ALL SELECT 'CHANCERY'
) C
CROSS JOIN (
	SELECT 'YIELD_FOOD' AS YieldType UNION ALL SELECT 'YIELD_PRODUCTION' UNION ALL SELECT 'YIELD_GOLD' UNION ALL
	SELECT 'YIELD_SCIENCE' UNION ALL SELECT 'YIELD_CULTURE' UNION ALL SELECT 'YIELD_FAITH'
) Y;

/*--5.2. Disable:
--5.2.5 Communism -- moved from base
INSERT INTO PolicyModifiers(PolicyType, ModifierId)
    SELECT 'POLICY_GOV_COMMUNISM', Modifiers.ModifierId
    FROM Modifiers WHERE ModifierId LIKE 'COMMUNISM%MODIFIER_BBG';
*/


-- Praeorium give +4 Loyalty (from +2)
UPDATE ModifierArguments SET Value='4' WHERE ModifierId='PRAETORIUM_GOVERNORIDENTITY' AND Name='Amount';

-- 28/11/24 Praetorium give +10% production on conquered cities with a gov
-- 15/12/24 20% without gov
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
    ('BBG_CITY_NOT_FOUNDED_REQSET', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
    ('BBG_CITY_NOT_FOUNDED_REQSET', 'REQUIRES_CITY_WAS_NOT_FOUNDED');

INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('BBG_PRAETORIUM_PRODUCTION_TO_CONQUERED_CITIES', 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER', 'BBG_CITY_NOT_FOUNDED_REQSET');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_PRAETORIUM_PRODUCTION_TO_CONQUERED_CITIES', 'YieldType', 'YIELD_PRODUCTION'),
    ('BBG_PRAETORIUM_PRODUCTION_TO_CONQUERED_CITIES', 'Amount', 20);
INSERT INTO PolicyModifiers (PolicyType, ModifierId) VALUES
    ('POLICY_PRAETORIUM', 'BBG_PRAETORIUM_PRODUCTION_TO_CONQUERED_CITIES');
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
--=========
--Mongolia
--=========
-- 23/04/2021 : Fixed by Firaxis
--INSERT OR IGNORE INTO TypeTags VALUES ('ABILITY_GENGHIS_KHAN_CAVALRY_BONUS', 'CLASS_MONGOLIAN_KESHIG');
-- No longer receives +1 diplo visibility for trading post
DELETE FROM TraitModifiers WHERE ModifierId='TRAIT_TRADING_POST_DIPLO_VISIBILITY';
DELETE FROM DiplomaticVisibilitySources WHERE VisibilitySourceType='SOURCE_TRADING_POST_TRAIT';
DELETE FROM DiplomaticVisibilitySources_XP1 WHERE VisibilitySourceType='SOURCE_TRADING_POST_TRAIT';
DELETE FROM ModifierArguments WHERE ModifierId='TRAIT_TRADING_POST_DIPLO_VISIBILITY';
DELETE FROM Modifiers WHERE ModifierId='TRAIT_TRADING_POST_DIPLO_VISIBILITY';
-- Keshig
UPDATE Units SET RangedCombat=40, Cost=180 WHERE UnitType='UNIT_MONGOLIAN_KESHIG';

INSERT OR IGNORE INTO RequirementSetRequirements VALUES
    ('BUILDING_IS_BARRACKS_STABLE_MILITARITIC_CITY_STATE', 'REQUIRES_CITY_HAS_ORDU_BBG');
INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType) VALUES
    ('REQUIRES_CITY_HAS_ORDU_BBG', 'REQUIREMENT_CITY_HAS_BUILDING');
INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value) VALUES
    ('REQUIRES_CITY_HAS_ORDU_BBG', 'BuildingType', 'BUILDING_ORDU');

-- 30/09/24 Ordu cost 45 prod (online)
UPDATE Buildings SET Cost=90 WHERE BuildingType='BUILDING_ORDU';

UPDATE Building_YieldChanges SET YieldChange=2 WHERE BuildingType='BUILDING_ORDU';


-- 08/04/25 Ordu movement now only works if unit starts turn on flat terrain
UPDATE Modifiers SET SubjectRequirementSetId='BBG_PLOT_IS_FLAT' WHERE ModifierId='ORDU_ADJUST_MOVEMENT';

-- 2026/02/27 cs for keshig removed
DELETE FROM TypeTags WHERE Type='ABILITY_GENGHIS_KHAN_CAVALRY_BONUS' AND Tag='CLASS_RANGED_CAVALRY';

-- 2026/09/09 怯薛歹（Keshig，中世纪 UU，马镫解锁）重新获得领袖 +3 力
--   CCB 2026/02/27 移除"远程骑兵类"共享后怯薛歹失去 +3；现按需求仅补怯薛歹专属标签
--   （其余远程骑兵类仍不享受；俘获机制范围不变）
INSERT OR IGNORE INTO TypeTags (Type, Tag) VALUES
('ABILITY_GENGHIS_KHAN_CAVALRY_BONUS', 'CLASS_MONGOLIAN_KESHIG');

-- 2026/09/09 俘获链加固（对照原版代码显式重建，缺则补、在则跳过，幂等）
--   原版组成：TraitModifiers(TRAIT_LEADER_GENGHIS_KHAN_ABILITY) →
--     TRAIT_COMBAT_BONUS_FOR_CAVALRY(+3 授予) + TRAIT_CAVALRY_CAPTURE_CAVALRY(俘获 attach)
--     俘获目标单位 = REQUIREMENTS_UNIT_IS_MONGOLIAN_CAVALRY（轻骑/重骑/怯薛歹）；
--     条件 = 主动攻击并消灭敌方轻/重/远程骑兵（ATTACKER_OPPONENT_IS_CAVALRY_UNIT_REQUIREMENTS）
--   ⚠ 引擎限制：远程击杀不触发俘获（怯薛歹为远程单位，其击杀不产生俘获属引擎行为）
INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
('TRAIT_LEADER_GENGHIS_KHAN_ABILITY', 'TRAIT_COMBAT_BONUS_FOR_CAVALRY'),
('TRAIT_LEADER_GENGHIS_KHAN_ABILITY', 'TRAIT_CAVALRY_CAPTURE_CAVALRY');
INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
('TRAIT_CAVALRY_CAPTURE_CAVALRY', 'MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER', 'REQUIREMENTS_UNIT_IS_MONGOLIAN_CAVALRY'),
('TRAIT_CAVALRY_CAPTURE_CAVALRY_MODIFIER', 'MODIFIER_UNIT_ADJUST_COMBAT_UNIT_CAPTURE', 'ATTACKER_OPPONENT_IS_CAVALRY_UNIT_REQUIREMENTS');
INSERT OR IGNORE INTO ModifierArguments (ModifierId, Name, Value) VALUES
('TRAIT_CAVALRY_CAPTURE_CAVALRY', 'ModifierId', 'TRAIT_CAVALRY_CAPTURE_CAVALRY_MODIFIER'),
('TRAIT_CAVALRY_CAPTURE_CAVALRY_MODIFIER', 'CanCapture', 'true');

-- 2026/09/09 战斗预览提示行（仿海猎犬/雄鹰战士的可视化；只加显示不改机制）
--   挂在内层俘获修饰器上：其需求 = 主动攻击 + 敌方为骑兵 → 仅在打骑兵时预览出现该行
INSERT OR IGNORE INTO ModifierStrings (ModifierId, Context, Text) VALUES
('TRAIT_CAVALRY_CAPTURE_CAVALRY_MODIFIER', 'Preview', 'LOC_CCB_GENGHIS_CAPTURE_PREVIEW_TEXT');
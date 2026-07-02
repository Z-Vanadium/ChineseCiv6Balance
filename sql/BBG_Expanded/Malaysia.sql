-- la
-- remove
DELETE FROM TraitModifiers WHERE ModifierId LIKE 'MODIFIER_CVS_ISKANDAR_UA_ATTACH_%' AND TraitType='MINOR_CIV_DEFAULT_TRAIT';

-- need early empire
UPDATE Modifiers SET OwnerRequirementSetId='BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET' WHERE ModifierId='MODIFIER_CVS_ISKANDAR_UA_ADJUST_POPULATION';

-- ca
-- bias
DELETE FROM StartBiasFeatures
      WHERE Tier = 3 AND
            CivilizationType = 'CIVILIZATION_CVS_MALAYSIA' AND
            FeatureType = 'FEATURE_JUNGLE';
DELETE FROM StartBiasResources
      WHERE ResourceType IN ('RESOURCE_FISH', 'RESOURCE_CRABS') AND
            Tier = 3 AND
            CivilizationType = 'CIVILIZATION_CVS_MALAYSIA';

-- uu 55+4, cost to 290 from 240
UPDATE Units SET Combat=58, Cost=290 WHERE UnitType='UNIT_CVS_MALAYSIA_UU';

-- healing nurfed to 20
UPDATE ModifierArguments SET Value=20 WHERE ModifierId='MODIFIER_CVS_MALAYSIA_UU_KILL_HEAL' AND Name='Amount';

DELETE FROM UnitAbilityModifiers WHERE ModifierId='MODIFIER_CVS_MALAYSIA_UU_KILL_GPP' AND UnitAbilityType='ABILITY_CVS_MALAYSIA_UU';

-- ud
-- 2026/07/02 半价港口，不提供伟人点数，不占用区域名额；科技只提供给改良单元格，新增湖泊
UPDATE Districts SET Cost=30, RequiresPopulation=0 WHERE DistrictType='DISTRICT_CVS_MALAYSIA_UI';
UPDATE District_GreatPersonPoints SET PointsPerTurn=0 WHERE DistrictType='DISTRICT_CVS_MALAYSIA_UI' AND GreatPersonClassType='GREAT_PERSON_CLASS_ADMIRAL';

INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQ_CCB_MALAYSIA_PLOT_HAS_ANY_IMPROVEMENT', 'REQUIREMENT_PLOT_HAS_ANY_IMPROVEMENT');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CVS_MALAYSIA_UI_PLOT_IS_COAST', 'REQ_CCB_MALAYSIA_PLOT_HAS_ANY_IMPROVEMENT');
DELETE FROM RequirementSetRequirements
      WHERE RequirementSetId = 'REQSET_CVS_MALAYSIA_UI_PLOT_IS_COAST' AND
            RequirementId = 'REQ_CVS_MALAYSIA_UI_PLOT_IS_NOT_LAKE';

-- from ccb
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_GOLD' AND DistrictType='DISTRICT_CVS_MALAYSIA_UI';
INSERT OR IGNORE INTO DistrictModifiers (DistrictType, ModifierId) VALUES
('DISTRICT_CVS_MALAYSIA_UI', 'BBG_HARBOR_HOUSING');

-- remove
DELETE FROM ImprovementModifiers WHERE ModifierId IN ('MODIFIER_CVS_MALAYSIA_UA_TRADE_CULTURE', 'MODIFIER_CVS_MALAYSIA_UA_TRADE_GOLD');

-- science
UPDATE ModifierArguments SET Value='YIELD_SCIENCE' WHERE ModifierId='MODIFIER_CVS_MALAYSIA_UI_COASTAL_CULTURE' AND Name='YieldType';
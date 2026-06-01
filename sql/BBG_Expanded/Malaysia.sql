-- la
-- remove
DELETE FROM TraitModifiers WHERE ModifierId LIKE 'MODIFIER_CVS_ISKANDAR_UA_ATTACH_%' AND TraitType='MINOR_CIV_DEFAULT_TRAIT';

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

-- uu 55+4
UPDATE Units SET Combat=59 WHERE UnitType='UNIT_CVS_MALAYSIA_UU';

DELETE FROM UnitAbilityModifiers WHERE ModifierId='MODTYPE_CVS_MALAYSIA_UU_KILL_GPP' AND UnitAbilityType='ABILITY_CVS_MALAYSIA_UU';

-- ud
-- from ccb
UPDATE District_CitizenYieldChanges SET YieldChange=3 WHERE YieldType='YIELD_GOLD' AND DistrictType='DISTRICT_CVS_MALAYSIA_UI';
INSERT OR IGNORE INTO DistrictModifiers (DistrictType, ModifierId) VALUES
('DISTRICT_CVS_MALAYSIA_UI', 'BBG_HARBOR_HOUSING');

-- remove
DELETE FROM ImprovementModifiers WHERE ModifierId IN ('MODIFIER_CVS_MALAYSIA_UA_TRADE_CULTURE', 'MODIFIER_CVS_MALAYSIA_UA_TRADE_GOLD');

-- science
UPDATE ModifierArguments SET Value='YIELD_SCIENCE' WHERE ModifierId='MODIFIER_CVS_MALAYSIA_UI_COASTAL_CULTURE' AND Name='YieldType';
--==========
-- EGYPT (xp2)
--==========
-- INSERT INTO Requirements (RequirementId, RequirementType) VALUES
--     ('REQUIRES_PLOT_HAS_GRASS_FLOODPLAINS', 'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES'),
--     ('REQUIRES_PLOT_HAS_PLAINS_FLOODPLAINS', 'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES');
-- INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
--     ('REQUIRES_PLOT_HAS_GRASS_FLOODPLAINS', 'FeatureType', 'FEATURE_FLOODPLAINS_GRASSLAND'),
--     ('REQUIRES_PLOT_HAS_PLAINS_FLOODPLAINS', 'FeatureType', 'FEATURE_FLOODPLAINS_PLAINS');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
    ('BBG_REQUIRES_PLOT_HAS_FLOODPLAINS', 'REQUIRES_PLOT_HAS_GRASS_FLOODPLAINS'),
    ('BBG_REQUIRES_PLOT_HAS_FLOODPLAINS', 'REQUIRES_PLOT_HAS_PLAINS_FLOODPLAINS');

--30/09/24 Maryanus cost 5 horses
UPDATE Units SET StrategicResource='RESOURCE_HORSES' WHERE UnitType='UNIT_EGYPTIAN_CHARIOT_ARCHER';
INSERT INTO Units_XP2 (UnitType, ResourceCost) VALUES
    ('UNIT_EGYPTIAN_CHARIOT_ARCHER', 10);

--==========
-- SPHINX
--==========
-- +1 food on plains and +1 prod on grass (including hills)
INSERT INTO ImprovementModifiers (ImprovementType, ModifierId) VALUES 
('IMPROVEMENT_SPHINX', 'CCB_SPHINX_FOOD');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SPHINX_FOOD', 'MODIFIER_SINGLE_PLOT_ADJUST_PLOT_YIELDS', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_PLAINS_CLASS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SPHINX_FOOD', 'Amount', '1'), 
('CCB_SPHINX_FOOD', 'YieldType', 'YIELD_FOOD');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_PLOT_IS_PLAINS_CLASS', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_PLOT_IS_PLAINS_CLASS', 'REQSET_CCB_PLOT_IS_PLAINS_CLASS');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQSET_CCB_PLOT_IS_PLAINS_CLASS', 'REQUIREMENT_PLOT_TERRAIN_CLASS_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQSET_CCB_PLOT_IS_PLAINS_CLASS', 'TerrainClass', 'TERRAIN_CLASS_PLAINS');


INSERT INTO ImprovementModifiers (ImprovementType, ModifierId) VALUES 
('IMPROVEMENT_SPHINX', 'CCB_SPHINX_PRODUCTION');
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, NewOnly, OwnerRequirementSetId, SubjectRequirementSetId) VALUES 
('CCB_SPHINX_PRODUCTION', 'MODIFIER_SINGLE_PLOT_ADJUST_PLOT_YIELDS', 0, 0, 0, NULL, 'REQSET_CCB_PLOT_IS_GRASS_CLASS');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES 
('CCB_SPHINX_PRODUCTION', 'Amount', '1'), 
('CCB_SPHINX_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES 
('REQSET_CCB_PLOT_IS_GRASS_CLASS', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES 
('REQSET_CCB_PLOT_IS_GRASS_CLASS', 'REQSET_CCB_PLOT_IS_GRASS_CLASS');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES 
('REQSET_CCB_PLOT_IS_GRASS_CLASS', 'REQUIREMENT_PLOT_TERRAIN_CLASS_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES 
('REQSET_CCB_PLOT_IS_GRASS_CLASS', 'TerrainClass', 'TERRAIN_CLASS_GRASS');

-- 由于加载顺序的问题，需要一个单独的文件来排除某些相邻加成。否则，会漏掉排除的相邻加成，导致拓展文明出错

-- sql\Base\Arabia.sql
INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
    SELECT TraitType, 'BBG_Campus_Arabia_HS' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_ARABIA' GROUP BY CivilizationType;
INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
    SELECT TraitType, 'BBG_HS_Arabia_Campus' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_ARABIA' GROUP BY CivilizationType;

-- sql\BBG_Expanded\Argentina.sql
INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
SELECT TraitType, 'CCB_Campus_Argentina_Pasture' FROM CivilizationTraits WHERE CivilizationType!='CIVILIZATION_LEU_ARGENTINA' GROUP BY CivilizationType;

INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
SELECT TraitType, 'CCB_Theater_Argentina_Pasture' FROM CivilizationTraits WHERE CivilizationType!='CIVILIZATION_LEU_ARGENTINA' GROUP BY CivilizationType;

INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
SELECT TraitType, 'CCB_IndustrialZone_Argentina_Pasture' FROM CivilizationTraits WHERE CivilizationType!='CIVILIZATION_LEU_ARGENTINA' GROUP BY CivilizationType;

INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
SELECT TraitType, 'CCB_HolySite_Argentina_Pasture' FROM CivilizationTraits WHERE CivilizationType!='CIVILIZATION_LEU_ARGENTINA' GROUP BY CivilizationType;

-- sql\LP\lp_kongo_mbande.sql
INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
    SELECT TraitType, 'CCB_CH_Kongo_Theater' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_KONGO';

INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
    SELECT TraitType, 'CCB_Theater_Kongo_CH' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_KONGO';

-- sql\LP\VictoriaSteam.sql
INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
   SELECT TraitType, 'BBG_AOS_ADJENCY_IZ_RND' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_ENGLAND' GROUP BY CivilizationType;

-- sql\XP1\Korea.sql
INSERT OR IGNORE INTO ExcludedAdjacencies(TraitType, YieldChangeId)
   SELECT TraitType, 'BBG_Seowon_Culture' FROM CivilizationTraits WHERE CivilizationType != 'CIVILIZATION_KOREA' GROUP BY CivilizationType;



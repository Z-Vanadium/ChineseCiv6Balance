-- 2025/9/14 CCB 1.0.3 新盖提商路加成人口信仰由1->0.5
UPDATE ModifierArguments SET Value=0.5 WHERE ModifierId='MINOR_CIV_CHINGUETTI_FAITH_FOLLOWERS' AND Name='Amount';
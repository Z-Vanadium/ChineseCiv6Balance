------------------------------------------------------------------------------
--	FILE:   CCB_AllianceTuning.sql
--	PURPOSE: CCB 同盟机制调参（2026-09 用户确认，基于实测口径：展示点数=引擎/8）
--	1) 三级同盟门槛：展示 120 → 100（累计）；引擎 ALLIANCE_LEVEL_THREE_XP 960 → 800
--	   （一级升二级不变：40 展示 / 引擎 320）
--	2) 二级科研同盟[研究协议]：每 30 回合 → 每 10 回合（标准速度；引擎按速度缩放）
--	3) 三级科研同盟[共享盟友科技]：+10% → +25% 科技
--	4) 三级文化同盟[共享旅游]：20% → 100%；[共享文化]：10% → 25%
--	5) 三级宗教同盟[信奉盟友宗教公民]：+1 → +5 信仰/回合
--	⚠ 仅改数值，不改结构；对应描述文本见 lang（LOC_ALLIANCE_LV*_EFFECT_* 覆盖）
------------------------------------------------------------------------------
UPDATE GlobalParameters SET Value='800' WHERE Name='ALLIANCE_LEVEL_THREE_XP';

UPDATE ModifierArguments SET Value='10' WHERE ModifierId='ALLIANCE_RESEARCH_AGREEMENT' AND Name='Amount';
UPDATE ModifierArguments SET Value='25' WHERE ModifierId='ALLIANCE_SCIENCE_SHARING_FROM_ALLY' AND Name='Amount';
UPDATE ModifierArguments SET Value='100' WHERE ModifierId='ALLIANCE_TOURISM_SHARING_FROM_ALLY' AND Name='Amount';
UPDATE ModifierArguments SET Value='25' WHERE ModifierId='ALLIANCE_CULTURE_SHARING_FROM_ALLY' AND Name='Amount';
UPDATE ModifierArguments SET Value='5' WHERE ModifierId='ALLIANCE_YIELDS_FROM_FOLLOWING_ALLY_RELIGION' AND Name='Amount';

-- 6) 删除民主主义政体的同盟点数效果（DEMOCRACY_ALLIANCEPOINTS，Amount=1 ≈ 展示 +0.25/回合）
--    该效果已迁入传承卡三级升级（民主补正 +5/回合，见 LegacyCards.sql T3 段），
--    政体/卡面不再发放，避免叠加；对应文本见 lang 覆盖（去掉"同盟点数额外增加0.25"句）
DELETE FROM GovernmentModifiers WHERE ModifierId='DEMOCRACY_ALLIANCEPOINTS';
DELETE FROM PolicyModifiers WHERE ModifierId='DEMOCRACY_ALLIANCEPOINTS';
DELETE FROM ModifierArguments WHERE ModifierId='DEMOCRACY_ALLIANCEPOINTS';
DELETE FROM Modifiers WHERE ModifierId='DEMOCRACY_ALLIANCEPOINTS';

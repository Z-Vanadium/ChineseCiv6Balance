-- ===========================================================================
-- [探针·临时 2026-09-22] 新科技树面板 · 数据层（验证完必须整段删除）
--
-- 目的：验证「自定义科技树面板」路线甲是否成立 ——
--   ① mod 能否新增一条**节点科技**当作"解锁旗标"（本探针用 HiddenUntilPrereqComplete 尝试隐藏）
--   ② 效果能否用**数据层**表门控在该旗标上（= 效果类型不受运行时挂载限制）
--   ③ 面板 → 花金币 → 授予科技 → 效果生效 的全链路
--
-- 写法出处（勿改）：
--   · 效果行先例 = 原版封建主义「种植园 +1 食物」：
--       DLC\Expansion2\Data\Expansion2_Improvements.xml:286
--       <Row Id="224" ImprovementType="IMPROVEMENT_PLANTATION" YieldType="YIELD_FOOD"
--            BonusYieldChange="1" PrereqCivic="CIVIC_FEUDALISM"/>
--     → 本探针同表同写法，只把 YieldType 换成 YIELD_PRODUCTION、门控换成 PrereqTech
--   · 科技行字段 = Base\Assets\Gameplay\Data\Technologies.xml 的 TECH_IRRIGATION 行
--     <Row TechnologyType="TECH_IRRIGATION" Name="LOC_TECH_IRRIGATION_NAME"
--          Description="LOC_TECH_IRRIGATION_DESCRIPTION" Cost="50"
--          AdvisorType="ADVISOR_GENERIC" EraType="ERA_ANCIENT" UITreeRow="-1"/>
--   · Technologies_XP2.HiddenUntilPrereqComplete 原版用法见
--       DLC\Expansion2\Data\Expansion2_Technologies.xml:249-256（未来科技等，均为 true）
--
-- ⚠ 探针刻意取 Cost=999999：万一隐藏失败、节点出现在真科技树里，玩家也无法用科研点出它
--   （只能通过我们的面板花金币解锁）。观感问题由本次实测判定，正式版再决定隐藏策略。
-- ===========================================================================

INSERT INTO Types (Type, Kind) VALUES
	('TECH_CCB_PROBE_PLANTATION', 'KIND_TECHNOLOGY');

INSERT INTO Technologies (TechnologyType, Name, Description, Cost, Repeatable, EraType, UITreeRow, AdvisorType) VALUES
	('TECH_CCB_PROBE_PLANTATION', 'LOC_TECH_CCB_PROBE_PLANTATION_NAME', 'LOC_TECH_CCB_PROBE_PLANTATION_DESC',
	 999999, 0, 'ERA_INFORMATION', -1, 'ADVISOR_GENERIC');

-- 尝试让它在真科文树里保持隐藏（语义待本次实测确认）
INSERT INTO Technologies_XP2 (TechnologyType, RandomPrereqs, HiddenUntilPrereqComplete) VALUES
	('TECH_CCB_PROBE_PLANTATION', 0, 1);

-- 节点前置：灌溉（面板里也会再查一次，双保险）
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
	('TECH_CCB_PROBE_PLANTATION', 'TECH_IRRIGATION');

-- 效果：所有种植园 +1 生产力，门控在节点科技上（= 拥有该科技才生效）
INSERT INTO Improvement_BonusYieldChanges (Id, ImprovementType, YieldType, BonusYieldChange, PrereqTech) VALUES
	(990001, 'IMPROVEMENT_PLANTATION', 'YIELD_PRODUCTION', 1, 'TECH_CCB_PROBE_PLANTATION');

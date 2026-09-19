--==============================================================================================
-- CCB 后期单位远程能力（2026-09-10 用户需求）
--   现代 / 原子能 / 信息时代 的【近战 · 抗骑 · 海军近战 · 轻骑 · 重骑】获得远程攻击：
--     射程 1、远程力 = 自身 Combat - 10
--   · 只补不削：已有更高远程/射程的单位保持不变（例：芬兰西西山兵 75/射程1 不会被降到 70）
--   · 时代判定：Units 表没有 Era 列 → 经 PrereqTech / PrereqCivic 关联 Technologies / Civics 的 EraType
--   · 特色替代单位（DLC 澳大利亚挖掘兵、BBG 扩展 西西山兵/高乔人）同样带 PromotionClass → 自动纳入
--   · 复制模板式单位（Finland/Argentina 用 INSERT..SELECT 从步兵复制）在本文件执行时已存在 → 一并覆盖
--   ⚠ 必须排在 BBG_Expanded（LoadOrder 100000）之后执行，扩展单位才已存在
--   预期命中：步兵 / 机械化步兵 / 反坦克小组 / 现代反坦克 / 坦克 / 现代装甲 / 直升机 / 驱逐舰
--             + 挖掘兵(澳洲) / 西西山兵(芬兰) / 高乔人(阿根廷)
--==============================================================================================
DROP TABLE IF EXISTS CCB_LATE_RANGED;

CREATE TEMP TABLE CCB_LATE_RANGED (UnitType TEXT PRIMARY KEY);

INSERT OR IGNORE INTO CCB_LATE_RANGED (UnitType)
SELECT u.UnitType
FROM Units u
LEFT JOIN Technologies t ON t.TechnologyType = u.PrereqTech
LEFT JOIN Civics       c ON c.CivicType     = u.PrereqCivic
WHERE u.PromotionClass IN (
		'PROMOTION_CLASS_MELEE',
		'PROMOTION_CLASS_ANTI_CAVALRY',
		'PROMOTION_CLASS_NAVAL_MELEE',
		'PROMOTION_CLASS_LIGHT_CAVALRY',
		'PROMOTION_CLASS_HEAVY_CAVALRY')
	AND (t.EraType IN ('ERA_MODERN', 'ERA_ATOMIC', 'ERA_INFORMATION')
	  OR c.EraType IN ('ERA_MODERN', 'ERA_ATOMIC', 'ERA_INFORMATION'));

UPDATE Units
SET RangedCombat = MAX(COALESCE(RangedCombat, 0), COALESCE(Combat, 0) - 10),
    Range        = MAX(COALESCE(Range, 0), 1)
WHERE UnitType IN (SELECT UnitType FROM CCB_LATE_RANGED);

DROP TABLE CCB_LATE_RANGED;

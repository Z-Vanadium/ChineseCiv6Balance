--==============================================================================================
-- CCB：地图搜索面板（MapSearchPanel）覆盖 —— 2026-10-14
--
-- 为什么需要：原版 `GetPlotSearchTerms()` 里有一句
--     local pFormationClass = FormationClassNameMap[pUnitInfo.FormationClass]
--     pAdditionalTerms[pFormationClass] = true;
--   而 `FormationClassNameMap` 只登记了原版 5 个队形类别（LAND_COMBAT / SUPPORT / CIVILIAN / NAVAL / AIR）。
--   本 MOD 给军事工程师新开了 `FORMATION_CLASS_CCB_MILITARY_ENGINEER`
--   （`sql/Base/CCB_ReinforcedFort.sql` ⑥），查表得到 nil，随后 `t[nil] = true`
--   在 Lua 里是**运行时错误**（table index is nil）→ 会对整张地图的搜索词条构建抛错。
--
-- 处理：把 `GetPlotSearchTerms` 包一层 pcall。出错时返回空表 —— 语义上等于"这一格不匹配任何搜索词"，
--   搜索面板其余部分照常工作，也不会往 Lua.log 里刷错误。
--   （原版函数是全局的，`include` 之后按名字覆盖即可。）
-- ⚠ 代价：**那一格**上的单位名/单位类别不再参与文本搜索（其余地块、其余词条都不受影响）。
--   以后若想连这格也能搜，需要把原版的 `FormationClassNameMap` 与 `GetPlotSearchTerms` 整段复制过来改写
--   （该函数约 300 行且引用多个文件级 local 表，成本高；当前选择轻量兜底）。
--==============================================================================================

include "MapSearchPanel";

local fVanillaGetPlotSearchTerms = GetPlotSearchTerms;

function GetPlotSearchTerms( data )
	local bOK, pSearchTerms = pcall( fVanillaGetPlotSearchTerms, data );
	if bOK then
		return pSearchTerms;
	end
	-- 未知队形类别（CCB 新类别等）会让原版函数报错 → 返回空表，让搜索面板继续工作
	return {};
end

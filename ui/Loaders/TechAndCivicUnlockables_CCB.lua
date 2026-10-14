--==============================================================================================
-- CCB：科技树解锁条目过滤的**官方挂载点**（UI Loaders hook）—— 2026-10-15
--
-- 【问题】堡垒 IMPROVEMENT_FORT 在科技树的「工程（TECH_ENGINEERING）」栏**看不到**。
--
-- 【根因】原版 `Base\Assets\UI\TechAndCivicUnlockables.lua` 的条目过滤规则（L90）：
--     function CanEverUnlock(playerTraitMap, item)
--         return item.TraitType ~= "TRAIT_BARBARIAN" and
--                ((item.TraitType == nil) or (playerTraitMap == nil) or playerTraitMap[item.TraitType]);
--     end
--   即：**带 TraitType 的条目必须"玩家拥有该 trait"才会被列出来**；
--   而 `GetTraitMapForPlayer()` 只读 `LeaderTraits` / `CivilizationTraits` **静态表**，
--   **既不看运行时授予的 trait，也不认内部 trait**（InternalOnly=1）。
--   CCB 的 ④「弹道学后强化堡垒取代堡垒」（`sql/Base/CCB_ReinforcedFort.sql` ④）正是靠
--   内部 trait `CCB_TRAIT_LEGACY_FORT` 让堡垒默认不可建、再由授权链在
--   "**已研究工程 且 尚未研究弹道学**"时放行 → 堡垒被这条规则**连带从科技树隐藏**。
--
-- 【处理】**数据机制一字不改**（授权链照旧：弹道学一到手，堡垒即从**建造列表**消失），
--   只在本挂载点给 CCB 自己的内部 trait 开一个白名单，让它在**科技树 / 市政树**里照常列出。
--   白名单只含 CCB 自建 trait → 原版条目行为零改动；未装本 MOD 时本文件根本不会被加载。
--
-- 【为什么放在这里】原版库文件末尾（L264）有一句：
--     include("TechAndCivicUnlockables_", true);
--   引擎按**文件名前缀**扫描 VFS，把所有 `TechAndCivicUnlockables_*.lua` 依次 include 进来
--   —— 这是 Firaxis 留给 DLC / 模组覆盖**共享 UI 库函数**的官方钩子。原版自身用法：
--     · Base\Assets\UI\Loaders\CivicsTreeIconLoader_EnvoyAwarded.lua      （后缀是"功能名"，不是包名）
--     · DLC\Expansion2\UI\Loaders\TechAndCivicUnlockables_Expansion2.lua
--     · DLC\Ethiopia\UI\Loaders\TechAndCivicUnlockables_Ethiopia.lua      （只覆盖 RemoveReplacedUnlockables）
--   好处（相对 `<ReplaceUIScript>` 整份替换）：
--     ① 不必照抄原版文件 → 没有"版本漂移"维护负担（原版 264 行只借用、不复制）；
--     ② 不受 LuaContext 限制 → TechTree / CivicsTree / ToolTipHelper / WorldTracker /
--        TechCivicCompletedPopup / Civilopedia 等**所有**引用了该库的界面同时生效；
--     ③ 不会和其它模组的整份替换互相覆盖。
--
-- ⚠ 维护提醒：文件名必须保持 `TechAndCivicUnlockables_<后缀>.lua`，并且要在 CCB.modinfo 的
--   `<Files>` 与 `<ImportFiles>` **两处**登记（登记处见 modinfo 内 `CCB_UI_Loaders` 段）；
--   只登记一处或改名 → 引擎扫不到 → 本文件静默失效（堡垒又会从科技树消失）。
--==============================================================================================

-- 允许在科技树 / 市政树里正常列出的 CCB **内部 trait**（"内部"＝没有任何领袖 / 文明静态拥有）
local CCB_TREE_VISIBLE_INTERNAL_TRAITS:table = {
	["CCB_TRAIT_LEGACY_FORT"] = true,	-- 堡垒：工程解锁；弹道学后由「强化堡垒」取代（CCB_ReinforcedFort.sql ④）
};

-- 原版定义（库文件 L90；本文件在库文件末尾 L264 被 include，此刻必然已存在）
local kBase_CanEverUnlock = CanEverUnlock;

function CanEverUnlock(playerTraitMap, item)
	if item.TraitType ~= nil and CCB_TREE_VISIBLE_INTERNAL_TRAITS[item.TraitType] then
		return true;
	end
	if kBase_CanEverUnlock ~= nil then
		return kBase_CanEverUnlock(playerTraitMap, item);
	end
	-- 兜底：理论上到不了（原版定义一定先于本文件）
	return item.TraitType ~= "TRAIT_BARBARIAN";
end

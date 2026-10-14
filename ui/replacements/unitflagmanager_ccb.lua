--==============================================================================================
-- CCB：单位旗帜管理（UnitFlagManager）覆盖 —— 2026-10-14
--
-- 为什么需要：原版 `CreateUnitFlag()` 里判断旗帜**样式**的那段是硬编码的 5 个队形类别
--   （LAND_COMBAT/AIR → 军事旗；NAVAL → 海军旗；SUPPORT → 支援旗；CIVILIAN → 平民旗），
--   **且没有 else 分支** → 任何未列出的 FormationClass 都**不会被创建旗帜**，
--   单位在地图上等于"没有图标"，基本无法选中/操作。
--
-- 本 MOD 给军事工程师新开了队形类别 `FORMATION_CLASS_CCB_MILITARY_ENGINEER`
--   （`sql/Base/CCB_ReinforcedFort.sql` ⑥，目的是让它能与观测气球/补给车队/无人机同格），
--   因此必须在这里兜底：① 我们的新类别按"支援"样式画旗；② 再加一个 else 兜底，
--   以后别的模组新增队形类别时也不会变成"没有旗帜"。
--
-- 写法：`include` 原版文件拿到全部代码与事件注册，然后**只覆盖需要改的那个函数**
--   （原版 `CreateUnitFlag` 是全局函数，事件回调在调用时才查找全局名 → 覆盖有效）。
--   与工程内既有 `ui/replacements/unitpanel_bbg.lua`（include "UnitPanel_Expansion2" 后覆盖函数）同构。
-- ⚠ 覆盖函数里不能直接用原版的**文件级 local**（如 `m_UnitFlagInstances`），
--   所以"是否已有旗帜"的判断改用原版提供的全局函数 `GetUnitFlag()`。
-- ⚠ 原版其余用到 FormationClass 的地方（多单位旗帜错位 L1284-1341）自带 else 兜底
--   （未知类别 → 偏移 (0,0)，只是多单位同格时旗帜略微重叠）→ 不需要改。
--==============================================================================================

include "UnitFlagManager";

function CreateUnitFlag( playerID: number, unitID : number, unitX : number, unitY : number )
	-- 已经有旗帜就直接返回（原版用文件级 local 表判断，这里改用全局函数）
	if (GetUnitFlag( playerID, unitID ) ~= nil) then
		return;
	end

	local pPlayer	:table = Players[playerID];
	local pUnit		:table = pPlayer:GetUnits():FindID(unitID);
	if pUnit ~= nil and pUnit:GetUnitType() ~= -1 then
		local formationClassType = GameInfo.Units[pUnit:GetUnitType()].FormationClass;
		if		(formationClassType == "FORMATION_CLASS_LAND_COMBAT" or formationClassType == "FORMATION_CLASS_AIR") then
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_MILITARY );
		elseif	(formationClassType == "FORMATION_CLASS_NAVAL") then
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_NAVAL );
		elseif	(formationClassType == "FORMATION_CLASS_CCB_MILITARY_ENGINEER" or formationClassType == "FORMATION_CLASS_SUPPORT") then
			-- ★ CCB 新增：军事工程师的队形类别按"支援"样式显示（它本来就是支援单位，只是堆叠格位不同）
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_SUPPORT );
		elseif	(formationClassType == "FORMATION_CLASS_CIVILIAN") then
			if	(GameInfo.Units[pUnit:GetUnitType()].MakeTradeRoute) then
				UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_TRADE );
			elseif (pUnit:GetReligiousStrength() > 0) then
				UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_RELIGION );
			else
				UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_CIVILIAN );
			end
		else
			-- ★ CCB 兜底：未知队形类别也给一面支援旗（原版这里没有 else → 会完全没有旗帜）
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_SUPPORT );
		end
	end
end

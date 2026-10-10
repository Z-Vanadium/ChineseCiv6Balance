------------------------------------------------------------------------------
--	FILE:   ccb_probetree.lua
--	PURPOSE: [探针·临时 2026-09-22] 新科技树面板 · Gameplay 侧（验证完必须整段删除）
--	         接收 UI 的"解锁节点"请求 → 校验（前置科技 + 金币 + 未解锁）→ 扣金币
--	         → 授予节点科技（数据层 Improvement_BonusYieldChanges 随即生效）
--	桥：UI.RequestPlayerOperation(EXECUTE_SCRIPT, {OnStart="OnPlayerCommandSetObjectState", ...})
--	    → GameEvents.OnPlayerCommandSetObjectState（工程内先例 scripts/ccb_tajmahal.lua）
--	日志前缀：[CCB-Probe-Tree]（探针专用，便于事后 grep 与删除）
--	⚠ 只读 + 单次写（扣钱/授予），不做每回合扫描 → MP 下无额外同步负担；日志为只读取证
------------------------------------------------------------------------------

local PROP_UNLOCKED  = 'CCB_PROBE_TREE_UNLOCKED';
local NODE_TECH      = 'TECH_CCB_PROBE_PLANTATION';
local PREREQ_TECH    = 'TECH_IRRIGATION';
local PLANTATION     = 'IMPROVEMENT_PLANTATION';
local COST_GOLD      = 150;

local function TechIndex(techType)
	local row = GameInfo.Technologies[techType];
	if row == nil then return -1; end
	return row.Index;
end

local function ImprovementIndex(improvementType)
	local row = GameInfo.Improvements[improvementType];
	if row == nil then return -1; end
	return row.Index;
end

-- 遍历容器（Civ6 里 GetCities()/GetOwnedPlots() 有的实现走 Members()、有的直接是数组）
local function EachIn(list, fn)
	if list == nil then return 0; end
	local n = 0;
	local ok = pcall(function()
		for _, item in list:Members() do
			if item ~= nil then n = n + fn(item); end
		end
	end);
	if ok and n > 0 then return n; end
	n = 0;
	pcall(function()
		for _, item in ipairs(list) do
			if item ~= nil then n = n + fn(item); end
		end
	end);
	return n;
end

-- [取证] 统计本国种植园数量与其生产力产出合计（只读）
local function ScanPlantations(player, tag)
	local impIdx  = ImprovementIndex(PLANTATION);
	local prodIdx = YieldTypes.PRODUCTION;
	local count, total, cityCount = 0, 0, 0;

	EachIn(player:GetCities(), function(city)
		cityCount = cityCount + 1;
		local ok, plots = pcall(function() return city:GetOwnedPlots(); end);
		if ok and plots ~= nil then
			EachIn(plots, function(plot)
				local okImp, impType = pcall(function() return plot:GetImprovementType(); end);
				if okImp and impType == impIdx then
					count = count + 1;
					local okY, y = pcall(function() return plot:GetYield(prodIdx); end);
					if okY and y ~= nil then total = total + y; end
				end
				return 0;
			end);
		end
		return 1;
	end);

	print(string.format('[CCB-Probe-Tree] %s：城市=%d 种植园=%d 种植园生产力合计=%.1f', tag, cityCount, count, total));
	return count, total;
end

local function ReadGold(player)
	local ok, gold = pcall(function() return player:GetTreasury():GetGoldBalance(); end);
	if ok and gold ~= nil then return gold, true; end
	return -1, false;
end

function OnCCBProbeTreeCommand(ePlayer, params)
	if params == nil or params.ccbProbeCommand ~= 'UNLOCK_NODE' then return; end

	local playerID = params.playerID;
	if playerID == nil then return; end
	local player = Players[playerID];
	if player == nil then return; end

	local nodeIdx   = TechIndex(NODE_TECH);
	local prereqIdx = TechIndex(PREREQ_TECH);
	local techs     = player:GetTechs();

	if nodeIdx < 0 or prereqIdx < 0 then
		print(string.format('[CCB-Probe-Tree] 拒绝：科技行缺失（node=%d prereq=%d）——检查 sql/Base/CCB_Probe_TreePanel.sql 是否加载成功', nodeIdx, prereqIdx));
		return;
	end

	local hasPrereq = techs:HasTech(prereqIdx);
	local unlocked  = (player:GetProperty(PROP_UNLOCKED) ~= nil);
	local gold, goldOk = ReadGold(player);

	print(string.format('[CCB-Probe-Tree] 收到解锁请求：玩家=%d 前置(灌溉)=%s 已解锁=%s 金币=%s(读取成功=%s) 花费=%d 节点科技已拥有=%s',
		playerID, tostring(hasPrereq), tostring(unlocked), tostring(gold), tostring(goldOk), COST_GOLD, tostring(techs:HasTech(nodeIdx))));

	if unlocked then
		print('[CCB-Probe-Tree] 拒绝：本玩家已解锁过该节点');
		return;
	end
	if not hasPrereq then
		print('[CCB-Probe-Tree] 拒绝：前置科技「灌溉」未完成');
		return;
	end
	if not goldOk then
		print('[CCB-Probe-Tree] 拒绝：无法读取金币余额（gameplay 侧 GetGoldBalance 不可用），为避免误扣已中止');
		return;
	end
	if gold < COST_GOLD then
		print(string.format('[CCB-Probe-Tree] 拒绝：金币不足（%d < %d）', gold, COST_GOLD));
		return;
	end

	ScanPlantations(player, '解锁前');

	-- ① 扣金币（gameplay 侧原生可用，先例：DLC\AustraliaScenario\Scripts\AustraliaScenario.lua:764/847）
	player:GetTreasury():ChangeGoldBalance(-COST_GOLD);
	local goldAfter = ReadGold(player);

	-- ② 授予节点科技（= 完成它；先例：Base\Assets\Scenarios\NapoleonScenario\NapoleonScenario_StartScript.lua:15-21）
	local researchCost = techs:GetResearchCost(nodeIdx);
	techs:SetResearchProgress(nodeIdx, researchCost);

	-- ③ 记录解锁状态（Player Property 会进存档）
	player:SetProperty(PROP_UNLOCKED, 1);

	print(string.format('[CCB-Probe-Tree] 解锁完成：金币 %s -> %s；节点科技 HasTech=%s（本次设置进度=%s）',
		tostring(gold), tostring(goldAfter), tostring(techs:HasTech(nodeIdx)), tostring(researchCost)));

	-- ④ 效果取证：数据层 Improvement_BonusYieldChanges（PrereqTech=节点科技）应即刻对本国种植园生效
	ScanPlantations(player, '解锁后(同回合)');
end

GameEvents.OnPlayerCommandSetObjectState.Add(OnCCBProbeTreeCommand);

print('[CCB-Probe-Tree] gameplay probe loaded.');

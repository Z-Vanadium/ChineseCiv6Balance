------------------------------------------------------------------------------
--	FILE:   ccb_probetree.lua
--	PURPOSE: [探针·临时] 新科技树面板 · Gameplay 侧
--	         ① 节点解锁：校验（前置=灌溉 + 150 金币 + 未解锁）→ 扣金币 → 记录 Property
--	            → **运行时挂载** CCB_PROBE_NODE_EFFECT（不新增任何科技行）
--	         ② 效果矩阵：接收 UI 请求，逐个 AttachModifierByID 挂载 CCB_PROBE_M1..M13
--	            并把成功/失败/报错原文写进 Lua.log，供"可用效果清单"判定
--	桥：UI.RequestPlayerOperation(EXECUTE_SCRIPT, {OnStart="OnPlayerCommandSetObjectState", ...})
--	日志前缀：[CCB-Probe-Tree]
------------------------------------------------------------------------------

local PROP_UNLOCKED = 'CCB_PROBE_TREE_UNLOCKED';
local PREREQ_TECH   = 'TECH_IRRIGATION';
local COST_GOLD     = 150;
local NODE_EFFECT   = 'CCB_PROBE_NODE_EFFECT';

local MATRIX = {
	M1  = '帝国+1科技（PLAYER_ADJUST_YIELD_CHANGE）',
	M2  = '帝国+1文化（PLAYER_ADJUST_YIELD_CHANGE）',
	M3  = '帝国+2金币（PLAYER_ADJUST_YIELD_CHANGE）',
	M4  = '全城+2生产（CITIES_ADJUST_CITY_YIELD_CHANGE）',
	M5  = '全城+10%生产（CITIES_ADJUST_CITY_YIELD_MODIFIER）',
	M6  = '全城+1宜居（CITIES_ADJUST_TRAIT_AMENITY）',
	M7  = '全城+1住房（CITIES_ADJUST_BUILDING_HOUSING）',
	M8  = '全城+15%发展（CITIES_ADJUST_CITY_GROWTH）',
	M9  = '每人口+1科技（CITIES_ADJUST_CITY_YIELD_PER_POPULATION）',
	M10 = '所有单位+5战斗力（PLAYER_UNITS_ADJUST_COMBAT_STRENGTH）',
	M11 = '所有单位+1移动（PLAYER_UNITS_ADJUST_MOVEMENT）',
	M12 = '所有单位+1射程（PLAYER_UNITS_ADJUST_ATTACK_RANGE）',
	M13 = '授予能力（PLAYER_UNITS_GRANT_ABILITY，对照项）',
};

local function TechIndex(techType)
	local row = GameInfo.Technologies[techType];
	if row == nil then return -1; end
	return row.Index;
end

-- 遍历容器（GetCities() 有的走 Members()、有的直接是数组）
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

-- [取证] 打印各城市的生产力（验证 M4/节点效果用；只读）
local function ScanCityProduction(player, tag)
	local prodIdx = YieldTypes.PRODUCTION;
	local parts = {};
	EachIn(player:GetCities(), function(city)
		local ok, y = pcall(function() return city:GetYield(prodIdx); end);
		local okN, name = pcall(function() return Locale.Lookup(city:GetName()); end);
		parts[#parts + 1] = string.format('%s=%.1f', okN and name or '?', ok and y or -1);
		return 1;
	end);
	print(string.format('[CCB-Probe-Tree] %s：城市生产力 %s', tag, table.concat(parts, ' ')));
end

local function ReadGold(player)
	local ok, gold = pcall(function() return player:GetTreasury():GetGoldBalance(); end);
	if ok and gold ~= nil then return gold, true; end
	return -1, false;
end

-- 统一封装"运行时挂载"并打印真实结果（探针核心动作）
local function AttachAndReport(player, modifierId, label)
	local ok, err = pcall(function()
		player:AttachModifierByID(modifierId);
	end);
	if not ok then
		print(string.format('[CCB-Probe-Tree] ✗ 挂载失败 %s（%s）：%s', modifierId, label, tostring(err)));
		return false;
	end
	print(string.format('[CCB-Probe-Tree] ✓ 已挂载 %s（%s）—— 请在游戏内核对对应面板数值是否变化', modifierId, label));
	return true;
end

function OnCCBProbeTreeCommand(ePlayer, params)
	if params == nil then return; end

	local playerID = params.playerID;
	if playerID == nil then return; end
	local player = Players[playerID];
	if player == nil then return; end

	-- ===== ① 节点解锁 =====
	if params.ccbProbeCommand == 'UNLOCK_NODE' then
		local techs     = player:GetTechs();
		local prereqIdx = TechIndex(PREREQ_TECH);
		local hasPrereq = (prereqIdx >= 0) and techs:HasTech(prereqIdx);
		local unlocked  = (player:GetProperty(PROP_UNLOCKED) ~= nil);
		local gold, goldOk = ReadGold(player);

		print(string.format('[CCB-Probe-Tree] 收到解锁请求：玩家=%d 前置(灌溉)=%s 已解锁=%s 金币=%s(读取=%s) 花费=%d（本版**不含任何科技旗标**）',
			playerID, tostring(hasPrereq), tostring(unlocked), tostring(gold), tostring(goldOk), COST_GOLD));

		if unlocked then
			print('[CCB-Probe-Tree] 拒绝：已解锁过（不可重复激活）');
			return;
		end
		if not hasPrereq then
			print('[CCB-Probe-Tree] 拒绝：前置科技「灌溉」未完成');
			return;
		end
		if not goldOk then
			print('[CCB-Probe-Tree] 拒绝：无法读取金币余额，为避免误扣已中止');
			return;
		end
		if gold < COST_GOLD then
			print(string.format('[CCB-Probe-Tree] 拒绝：金币不足（%d < %d）', gold, COST_GOLD));
			return;
		end

		ScanCityProduction(player, '解锁前');
		player:GetTreasury():ChangeGoldBalance(-COST_GOLD);
		player:SetProperty(PROP_UNLOCKED, 1);
		AttachAndReport(player, NODE_EFFECT, '节点效果：全城+1生产');
		local goldAfter = ReadGold(player);
		print(string.format('[CCB-Probe-Tree] 解锁完成：金币 %s -> %s（节点无科技行，科技树/研究下拉/百科应完全看不到）',
			tostring(gold), tostring(goldAfter)));
		ScanCityProduction(player, '解锁后(同回合)');
		return;
	end

	-- ===== ② 效果矩阵 =====
	if params.ccbProbeCommand == 'MATRIX' then
		local key = params.effectKey;
		if key == nil or MATRIX[key] == nil then
			print('[CCB-Probe-Tree] ✗ 矩阵请求缺 effectKey 或键名非法: ' .. tostring(key));
			return;
		end
		local modifierId = 'CCB_PROBE_' .. key;
		print(string.format('[CCB-Probe-Tree] 矩阵请求 %s = %s', modifierId, MATRIX[key]));
		AttachAndReport(player, modifierId, MATRIX[key]);
		return;
	end
end

GameEvents.OnPlayerCommandSetObjectState.Add(OnCCBProbeTreeCommand);

print('[CCB-Probe-Tree] gameplay probe loaded.');

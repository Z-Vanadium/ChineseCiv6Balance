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
	-- 第二轮：单位战斗力其它通道 / 单位类 / 区域类 / ★Trait 通道
	R2  = '单位+5防御时战斗力（UNITS_ADJUST_STRENGTH_WHEN_DEFENDING）',
	R3  = '单位+5本国领土战斗力（UNITS_ADJUST_FRIENDLY_TERRITORY_COMBAT）',
	R4  = '单位每回合+10治疗（UNITS_ADJUST_HEAL_PER_TURN）',
	R5  = '建造者+100%生产力（UNITS_ADJUST_UNIT_PRODUCTION）',
	R6  = '所有区域+1大工程师点（DISTRICTS_ADJUST_GREAT_PERSON_POINTS）',
	R7  = '每区域+1文化（CITIES_ADJUST_CITY_YIELD_PER_DISTRICT）',
	R8  = '★授予 Trait A（Trait 效果=帝国+1科技）',
	R9  = '★授予 Trait B（Trait 效果=授予能力→单位+5战斗力）',
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

-- [客观读数] 打印"会被效果改变的数值"，用于点击前后对比判定是否真的生效
--   科技/回合 = PlayerTechs:GetScienceYield()（原版 TopPanel.lua:107 同款）
--   文化/回合 = PlayerCulture:GetCultureYield()（原版 ARXManager.lua:155 同款）
--   金币      = PlayerTreasury:GetGoldBalance()
--   样本单位   = Unit:GetCombat() / Unit:GetMovesRemaining()
--   单位取样走 3 条路：容器 Members() → ipairs/pairs → **地图扫描兜底**
--     （2026-10-14 实测：容器路径一直取不到单位（读数始终 单位[无]），故加诊断与兜底，
--       地图扫描写法取自本工程 scripts/ccb_planted_forest.lua:73 Map.GetPlotCount()）
local function Readout(player, tag)
	local parts = {};
	local turn = -1;
	local okTurn, t = pcall(function() return Game.GetCurrentGameTurn(); end);
	if okTurn and t ~= nil then turn = t; end

	local okSci, sci = pcall(function() return player:GetTechs():GetScienceYield(); end);
	local okCul, cul = pcall(function() return player:GetCulture():GetCultureYield(); end);
	local gold, goldOk = ReadGold(player);
	parts[#parts + 1] = 'T' .. tostring(turn);
	parts[#parts + 1] = '科技/回合=' .. (okSci and string.format('%.1f', sci) or 'ERR');
	parts[#parts + 1] = '文化/回合=' .. (okCul and string.format('%.1f', cul) or 'ERR');
	parts[#parts + 1] = '金币=' .. (goldOk and tostring(gold) or 'ERR');

	local prodIdx = YieldTypes.PRODUCTION;
	local cityParts = {};
	EachIn(player:GetCities(), function(city)
		local ok, y = pcall(function() return city:GetYield(prodIdx); end);
		cityParts[#cityParts + 1] = ok and string.format('%.1f', y) or 'ERR';
		return 1;
	end);
	parts[#parts + 1] = '各城生产=[' .. table.concat(cityParts, ',') .. ']';

	-- ---- 单位取样 ----
	local unitParts = {};
	local diag = {};
	local myID = player:GetID();
	local function Consider(u)
		if #unitParts >= 3 or u == nil or u.GetUnitType == nil then return; end
		local okCS, cs = pcall(function() return u:GetCombat(); end);
		if not okCS or cs == nil or cs <= 0 then return; end
		local okMV, mv = pcall(function() return u:GetMovesRemaining(); end);
		local okT, tp = pcall(function() return u:GetUnitType(); end);
		unitParts[#unitParts + 1] = string.format('%s CS=%d 移动=%s', tostring(okT and tp or '?'), cs,
			okMV and string.format('%.0f', mv) or '?');
	end

	local units = player:GetUnits();
	diag[#diag + 1] = 'GetUnits=' .. ((units ~= nil) and 'ok' or 'nil');
	if units ~= nil then
		if units.Members ~= nil then
			local ok1, err1 = pcall(function() for _, u in units:Members() do Consider(u); end end);
			if not ok1 then diag[#diag + 1] = 'MembersErr=' .. tostring(err1); end
		else
			diag[#diag + 1] = 'Members=nil';
		end
		if #unitParts == 0 then
			local ok2, err2 = pcall(function() for _, u in ipairs(units) do Consider(u); end end);
			if not ok2 then diag[#diag + 1] = 'ipairsErr=' .. tostring(err2); end
		end
		if #unitParts == 0 then
			local ok3, err3 = pcall(function() for _, u in pairs(units) do Consider(u); end end);
			if not ok3 then diag[#diag + 1] = 'pairsErr=' .. tostring(err3); end
		end
	end

	-- 兜底：地图扫描（保证能取到单位，同时便于判断容器路径为何失败）
	local scanned = 0;
	if #unitParts == 0 then
		local count = Map.GetPlotCount();
		for i = 0, count - 1 do
			local plot = Map.GetPlotByIndex(i);
			if plot ~= nil then
				local okU, u = pcall(function() return plot:GetUnit(); end);
				if okU and u ~= nil then
					local okO, owner = pcall(function() return u:GetOwner(); end);
					if okO and owner == myID then
						scanned = scanned + 1;
						Consider(u);
					end
				end
			end
		end
		diag[#diag + 1] = 'mapScan=' .. tostring(scanned);
	end

	parts[#parts + 1] = '单位[' .. ((#unitParts > 0) and table.concat(unitParts, ' | ') or '无') .. ']';
	if #unitParts == 0 then
		parts[#parts + 1] = '诊断{' .. table.concat(diag, ',') .. '}';
	end

	print(string.format('[CCB-Probe-Tree] 读数(%s)：%s', tag, table.concat(parts, '  ')));
end

-- 统一封装"运行时挂载"：挂载前读数 → 挂载 → 挂载后读数（据此客观判定效果是否生效）
local function AttachAndReport(player, modifierId, label)
	Readout(player, '挂载前 ' .. modifierId);
	local ok, err = pcall(function()
		player:AttachModifierByID(modifierId);
	end);
	if not ok then
		print(string.format('[CCB-Probe-Tree] ✗ 挂载失败 %s（%s）：%s', modifierId, label, tostring(err)));
		return false;
	end
	print(string.format('[CCB-Probe-Tree] ✓ 已挂载 %s（%s）', modifierId, label));
	Readout(player, '挂载后 ' .. modifierId);
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

	-- ===== ③ 手动打印读数（不确定时随时点） =====
	if params.ccbProbeCommand == 'READOUT' then
		Readout(player, '手动');
		return;
	end
end

GameEvents.OnPlayerCommandSetObjectState.Add(OnCCBProbeTreeCommand);

-- [每回合读数] 记录数值随时间的变化，用于判定"效果何时开始生效"
--   （本次要回答的问题：R9 授予 Trait B 的 +5 战斗力是立即生效、还是过回合/其它操作后才生效；
--     以及用户观察到的"点 M10 才 +5"到底是 M10 的功劳还是 R9 早已生效）
local function ProbeTurnReadout(turn)
	for _, pid in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local p = Players[pid];
		if p ~= nil and p:IsHuman() then
			Readout(p, '回合开始');
		end
	end
end
GameEvents.OnGameTurnStarted.Add(ProbeTurnReadout);

print('[CCB-Probe-Tree] gameplay probe loaded.');

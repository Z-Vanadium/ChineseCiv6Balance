-------------------------------------------------------------------------------
--	FILE:   ccb_legacycards.lua
--	PURPOSE: CCB 传承卡升级状态机（v1.4.4 事件驱动版）
--	机制（用户确认版，docs/传承卡体系设计.md）：
--	1) 一级类市政广场建筑完成（普通Tier1三选一 / 瑞典女王图书馆）→
--	   按【当前一级政体】记录该政体的一级传承卡（可多张：如寡头+共和）
--	2) 二级政体建筑完成（城邦/间谍/信仰办公室三座）且处于二级政体 →
--	   对玩家【当时拥有的全部未升级一级卡】分别升级为对应二级升级卡
--	3) 迟来的一级卡（升级后才获得）保持一级，等待市政广场重建后再次升级
--	4) 商共线升级 → 被动 +2 商路容量（永久 Attach，仅一次）
--	✅ 引擎 API（探针实测，2026-09）：
--	   Events.GovernmentChanged(pID, govtIndex)  ← Gameplay 可用！govtIndex 是 Index（数字）
--	   Events.GovDistrictPolicyUnlocked(pID, policyIndex) ← Gameplay 可用
--	   GameEvents.BuildingConstructed(pID,cID,bIdx,...)  ← 建筑完成（Events 表里没有它！）
--	   GameEvents.OnGameTurnStarted(turn)  ← 参数是回合数，不是玩家ID！
--	   Player:GetCulture() → PlayerCulture
--	   PlayerCulture:UnlockPolicy(idx) / RequestPolicyChanges / GetSlotPolicy
--	   ⚠ Gameplay 层无法读当前政体（GetCurrentGovernment 是 UI-only）→ 用 GovernmentChanged 记录
--	   ⚠ 不存在：player:GetPolicies() / AddPolicy / SetPolicy / Player:GetGovernment()
-------------------------------------------------------------------------------

-- ===========================================================================
-- 常量
-- ===========================================================================
local PROP_T1_CARDS    = 'CCB_LEGACY_T1_CARDS';      -- 已获一级卡政体集合（逗号分隔）
local PROP_UPGRADED    = 'CCB_LEGACY_UPGRADED_CARDS'; -- 已升级政体集合（逗号分隔）
local PROP_TRADE_BONUS = 'CCB_LEGACY_TRADE_BONUS';   -- 商路+2 是否已发（1/0）
local PROP_CURRENT_GOVT = 'CCB_LEGACY_CURRENT_GOVT'; -- 最近一次政体（存 GovernmentType 字符串）
local PROP_ENVOY_MAX  = 'CCB_LEGACY_ENVOY_MAX_TIER'; -- 旧单向棘轮档位（仅作存档迁移读取）
local PROP_ENVOY_POS  = 'CCB_LEGACY_ENVOY_POS';      -- 使者产出已挂正向增量数
local PROP_ENVOY_NEG  = 'CCB_LEGACY_ENVOY_NEG';      -- 使者产出已挂负向增量数
local PROP_FF_NET     = 'CCB_LEGACY_FF_NET';         -- 神权卡"外国信徒"当前净档位（= 已产生的文化/信仰/回合）

-- 一级类建筑（普通 Tier1 三选一 + 瑞典女王图书馆 —— 均生成一级传承卡）
local T1_BUILDINGS = {
	['BUILDING_GOV_TALL'] = true,
	['BUILDING_GOV_WIDE'] = true,
	['BUILDING_GOV_CONQUEST'] = true,
	['BUILDING_QUEENS_BIBLIOTHEQUE'] = true,
};
-- 二级政体建筑（仅三座普通 Tier2；女王图书馆不属于此类）
local T2_BUILDINGS = {
	['BUILDING_GOV_CITYSTATES'] = true,
	['BUILDING_GOV_SPIES'] = true,
	['BUILDING_GOV_FAITH'] = true,
};
-- 三级政体建筑（三座普通 Tier3：军事/文化/科学学院，一生一次）
local T3_BUILDINGS = {
	['BUILDING_GOV_MILITARY'] = true,
	['BUILDING_GOV_CULTURE'] = true,
	['BUILDING_GOV_SCIENCE'] = true,
};

-- 一级政体（key=集合键, card=原版一级传承卡）
local T1_MAP = {
	['GOVERNMENT_OLIGARCHY']          = { key = 'OLIGARCHY', card = 'POLICY_GOV_OLIGARCHY' },
	['GOVERNMENT_CLASSICAL_REPUBLIC'] = { key = 'REPUBLIC',  card = 'POLICY_GOV_CLASSICAL_REPUBLIC' },
	['GOVERNMENT_AUTOCRACY']          = { key = 'AUTOCRACY', card = 'POLICY_GOV_AUTOCRACY' },
};
-- 一级政体反向：key → GovernmentType
local T1_KEY_TO_GOVT = {
	['OLIGARCHY'] = 'GOVERNMENT_OLIGARCHY',
	['REPUBLIC']  = 'GOVERNMENT_CLASSICAL_REPUBLIC',
	['AUTOCRACY'] = 'GOVERNMENT_AUTOCRACY',
};

-- 二级政体判断（君主/神权/商共）
local function IsT2Government(govt)
	return govt == 'GOVERNMENT_MONARCHY'
		or govt == 'GOVERNMENT_THEOCRACY'
		or govt == 'GOVERNMENT_MERCHANT_REPUBLIC';
end

-- 三级政体判断（法西斯/共产/民主，2026-09 T3 升级用）
local T3_GOVT_TO_SUFFIX = {
	['GOVERNMENT_FASCISM']    = 'FASCISM',
	['GOVERNMENT_COMMUNISM']  = 'COMMUNISM',
	['GOVERNMENT_DEMOCRACY']  = 'DEMOCRACY',
};
local function IsT3Government(govt)
	return T3_GOVT_TO_SUFFIX[govt] ~= nil;
end

-- ===========================================================================
-- 属性键（T3 升级记录）
-- ===========================================================================
local PROP_T3_UPGRADED = 'CCB_LEGACY_T3_UPGRADED'; -- 已升三级卡集合（逗号分隔 t1Key 列表，与 PROP_UPGRADED 同键空间）

-- ===========================================================================
-- 集合工具（Property 存逗号分隔字符串）
-- ===========================================================================
local function SplitList(s)
	if s == nil or s == '' then return {}; end
	local out = {};
	for v in string.gmatch(s, '[^,]+') do table.insert(out, v); end
	return out;
end
local function JoinList(list)
	return table.concat(list, ',');
end
local function ListContains(list, v)
	for _, x in ipairs(list) do if x == v then return true; end end
	return false;
end

-- ===========================================================================
-- Index → GovernmentType（引擎 GameInfo.Governments[index] 直接可用 Index）
-- ===========================================================================
local function GovtIndexToType(govtIndex)
	if govtIndex == nil then return nil; end
	local row = GameInfo.Governments[govtIndex];
	if row ~= nil then return row.GovernmentType; end
	-- 兜底遍历
	for r in GameInfo.Governments() do
		if r.Index == govtIndex then return r.GovernmentType; end
	end
	return nil;
end

-- ===========================================================================
-- 升级映射：一级政体 × 当前二级政体 → (二级升级卡, 是否商共线)
-- ===========================================================================
local function GetUpgradeTarget(t1Key, currentGovt)
	if t1Key == 'OLIGARCHY' then
		if currentGovt == 'GOVERNMENT_MONARCHY' or currentGovt == 'GOVERNMENT_THEOCRACY' then
			return 'POLICY_CCB_GOV_OLIGARCHY_MELEE', false;
		elseif currentGovt == 'GOVERNMENT_MERCHANT_REPUBLIC' then
			-- 寡头×商共 = 海权卡（+4 + 海军经验50%），**无 +2 商路**（商路被动仅限共和/独裁×商共 TRADE 线）
			return 'POLICY_CCB_GOV_OLIGARCHY_NAVAL', false;
		end
	elseif t1Key == 'REPUBLIC' then
		if currentGovt == 'GOVERNMENT_MONARCHY' then return 'POLICY_CCB_GOV_REPUBLIC_DIPLO', false;
		elseif currentGovt == 'GOVERNMENT_THEOCRACY' then return 'POLICY_CCB_GOV_REPUBLIC_FAITH', false;
		elseif currentGovt == 'GOVERNMENT_MERCHANT_REPUBLIC' then return 'POLICY_CCB_GOV_REPUBLIC_TRADE', true; end
	elseif t1Key == 'AUTOCRACY' then
		if currentGovt == 'GOVERNMENT_MONARCHY' then return 'POLICY_CCB_GOV_AUTOCRACY_DIPLO', false;
		elseif currentGovt == 'GOVERNMENT_THEOCRACY' then return 'POLICY_CCB_GOV_AUTOCRACY_FAITH', false;
		elseif currentGovt == 'GOVERNMENT_MERCHANT_REPUBLIC' then return 'POLICY_CCB_GOV_AUTOCRACY_TRADE', true; end
	end
	return nil, false;
end

-- ===========================================================================
-- 玩家文化对象
-- ===========================================================================
local function GetCulture(player)
	if player ~= nil and player.GetCulture ~= nil then
		local c = player:GetCulture();
		if c ~= nil then return c; end
	end
	return nil;
end

-- 解锁一张卡（ExplicitUnlock 卡必须显式解锁才进入可用池）
local function UnlockCard(culture, cardType)
	if culture == nil or culture.UnlockPolicy == nil then return false; end
	local info = GameInfo.Policies[cardType];
	if info == nil then return false; end
	local ok = pcall(function() culture:UnlockPolicy(info.Index); end);
	return ok;
end

-- 找某张卡当前所在的槽索引（返回槽 i；-1 未装备）
local function FindCardSlot(culture, cardType)
	if culture == nil or culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil then return -1; end
	local nSlots = culture:GetNumPolicySlots();
	for i = 0, nSlots - 1 do
		local policyHash = culture:GetSlotPolicy(i);
		if policyHash ~= -1 then
			local pInfo = GameInfo.Policies[policyHash];
			if pInfo ~= nil and pInfo.PolicyType == cardType then return i; end
		end
	end
	return -1;
end

-- 换卡：解锁升级卡并原位替换旧一级卡槽位
local function SwapCards(player, t1CardType, upgradeCardType)
	local culture = GetCulture(player);
	if culture == nil then return; end
	UnlockCard(culture, upgradeCardType);
	if culture.RequestPolicyChanges == nil then return; end
	local oldSlot = FindCardSlot(culture, t1CardType);
	if oldSlot < 0 then return; end
	local upInfo = GameInfo.Policies[upgradeCardType];
	local tInfo = GameInfo.Types[upgradeCardType];
	if upInfo == nil or tInfo == nil then return; end
	local addList = {};
	addList[oldSlot] = tInfo.Hash;
	pcall(function() culture:RequestPolicyChanges({ oldSlot }, addList); end);
end

-- 防回插：把"已升级一级卡"移出槽（防叠加）
local function PurgeUpgradedT1Cards(player)
	local culture = GetCulture(player);
	if culture == nil then return; end
	local upList = SplitList(player:GetProperty(PROP_UPGRADED));
	if #upList == 0 then return; end
	if culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil
		or culture.RequestPolicyChanges == nil then return; end
	local nSlots = culture:GetNumPolicySlots();
	local clearList = {};
	for i = 0, nSlots - 1 do
		local policyHash = culture:GetSlotPolicy(i);
		if policyHash ~= -1 then
			local pInfo = GameInfo.Policies[policyHash];
			if pInfo ~= nil then
				local pType = pInfo.PolicyType;
				for _, u in ipairs(upList) do
					local t1Key = string.match(u, '^([^:]+)');
					local t1Govt = T1_KEY_TO_GOVT[t1Key];
					if t1Govt ~= nil then
						local m = T1_MAP[t1Govt];
						if m ~= nil and m.card == pType then
							table.insert(clearList, i);
							break;
						end
					end
				end
			end
		end
	end
	if #clearList > 0 then
		pcall(function() culture:RequestPolicyChanges(clearList, {}); end);
		print('[CCB-Legacy] purge upgraded T1 cards from slots: '
			.. table.concat(clearList, ',') .. ' (player ' .. tostring(player:GetID()) .. ')');
	end
end

-- ===========================================================================
-- 事件A：政体切换 → 记录玩家当前政体
-- Events.GovernmentChanged(pID, govtIndex) —— govtIndex 是 Index（数字）
-- ===========================================================================
-- ===========================================================================
-- [探针·临时 2026-09-10] 政体卡"动态隐藏"可行性验证（验证完必须整段删除）
--   背景：寡头政体内「政体自带 +4」与「传承卡 +4」同项双计 → +8
--   目标方案 D：处于某 T1 政体时，把该线全部传承卡（T1/二级/三级）隐藏
--   引擎已知：政策可用性 = IsPolicyUnlocked and not IsPolicyObsolete（GovernmentScreen.lua）
--            过时由静态表 ObsoletePolicies 驱动；原版 Lua 未使用任何 setter
--   本探针回答两个问题：
--     ① PlayerCulture 是否存在"设置过时/锁定"类 API（有则最简实现）
--     ② 对"已解锁"的卡重复调用 UnlockPolicy，是否会重新触发过时重算
--        （若会 → 可用"解锁触发卡"实现动态隐藏；若不会 → 需换实现路径）
--   ⚠ 副作用：会重新解锁寡头 T1 卡（可能临时清除其过时状态）→ 只跑专用测试档
-- ===========================================================================
local PROBE_METHODS = {
	'SetPolicyObsolete', 'SetPolicyUnlocked', 'LockPolicy', 'UnlockPolicy',
	'IsPolicyObsolete', 'IsPolicyUnlocked', 'MakePolicyObsolete',
	'SetPolicyAvailable', 'SetPolicyLocked', 'RemovePolicy',
};
local function RunLegacyProbe(player, govtType)
	local culture = GetCulture(player);
	if culture == nil then
		print('[CCB-PROBE] culture nil, player=' .. tostring(player:GetID()));
		return;
	end
	local methodReport = {};
	for _, name in ipairs(PROBE_METHODS) do
		local ok, v = pcall(function() return culture[name]; end);
		table.insert(methodReport, name .. '=' .. (ok and tostring(v) or 'ERR'));
	end
	print('[CCB-PROBE] govt=' .. tostring(govtType) .. ' methods: ' .. table.concat(methodReport, ' '));

	local t1 = GameInfo.Policies['POLICY_GOV_OLIGARCHY'];
	local t2 = GameInfo.Policies['POLICY_CCB_GOV_OLIGARCHY_MELEE'];
	local t3 = GameInfo.Policies['POLICY_CCB_GOV_OLIGARCHY_MELEE_FASCISM'];
	if t1 == nil or t2 == nil then
		print('[CCB-PROBE] policy rows missing (t1=' .. tostring(t1) .. ' t2=' .. tostring(t2) .. ')');
		return;
	end
	print('[CCB-PROBE] state: T1 obsolete=' .. tostring(culture:IsPolicyObsolete(t1.Hash))
		.. ' unlocked=' .. tostring(culture:IsPolicyUnlocked(t1.Hash))
		.. ' | T2 obsolete=' .. tostring(culture:IsPolicyObsolete(t2.Hash))
		.. ' unlocked=' .. tostring(culture:IsPolicyUnlocked(t2.Hash))
		.. ' | T3 unlocked=' .. tostring(t3 ~= nil and culture:IsPolicyUnlocked(t3.Hash) or false));

	if not culture:IsPolicyUnlocked(t2.Hash) then
		print('[CCB-PROBE] T2 (寡头二级卡) 尚未解锁 → 跳过重算测试（避免污染存档）；请用"已升级过寡头线"的档再试');
		return;
	end

	-- 步骤1：重新解锁 T1 卡 → 预期清除其过时状态（= 你观察到的漏洞机制）
	pcall(function() culture:UnlockPolicy(t1.Index); end);
	print('[CCB-PROBE] step1 re-unlock T1 → T1 obsolete=' .. tostring(culture:IsPolicyObsolete(t1.Hash))
		.. ' unlocked=' .. tostring(culture:IsPolicyUnlocked(t1.Hash)));

	-- 步骤2【关键】：对已解锁的 T2 再调一次 UnlockPolicy → 过时是否被重新置起？
	pcall(function() culture:UnlockPolicy(t2.Index); end);
	print('[CCB-PROBE] step2 re-unlock T2 → T1 obsolete=' .. tostring(culture:IsPolicyObsolete(t1.Hash)));

	-- 步骤3：同样对 T3（若已解锁）试一次，观察是否影响 T2 的过时
	if t3 ~= nil and culture:IsPolicyUnlocked(t3.Hash) then
		pcall(function() culture:UnlockPolicy(t3.Index); end);
		print('[CCB-PROBE] step3 re-unlock T3 → T2 obsolete=' .. tostring(culture:IsPolicyObsolete(t2.Hash)));
	end
end

-- ===========================================================================
-- 事件A：政体切换 → 记录玩家当前政体
-- Events.GovernmentChanged(pID, govtIndex) —— govtIndex 是 Index（数字）
-- ===========================================================================
function OnGovernmentChanged(playerID, govtIndex)
	local player = Players[playerID];
	if player == nil then return; end
	local govtType = GovtIndexToType(govtIndex);
	print('[CCB-Legacy] GovernmentChanged p' .. tostring(playerID)
		.. ' idx=' .. tostring(govtIndex) .. ' type=' .. tostring(govtType));
	if govtType ~= nil then
		player:SetProperty(PROP_CURRENT_GOVT, govtType);
		-- 政体已切换 → 立刻重算"重复结算抵消"（否则要多算一整回合双份）
		-- 注：本函数定义在文件后段（全局函数），此处按调用期解析；加载期事件不触发，已加 nil 保护
		if UpdateGovernmentDoubleOffset ~= nil then
			UpdateGovernmentDoubleOffset(player);
		end
	end
	-- [探针·临时 2026-09-10 · 任务已挂起] 方案 D（T1 政体内隐藏该线传承卡）可行性验证
	--   挂起原因：当前改验其它内容；探针会改写 T1 卡的过时状态 → 污染存档，勿在正式测试档启用
	--   恢复验证时：取消下面 3 行注释，重启游戏并切换一次 T1 政体即可
	-- if govtType ~= nil and T1_MAP[govtType] ~= nil then
	-- 	RunLegacyProbe(player, govtType);
	-- end
end
Events.GovernmentChanged.Add(OnGovernmentChanged);

-- ===========================================================================
-- 事件B：建筑完成 → 记录/升级传承卡
-- GameEvents.BuildingConstructed(pID, cID, bIdx, plotIdx, bOriginal)
-- ===========================================================================
function OnBuildingConstructed(playerID, cityID, buildingID)
	local player = Players[playerID];
	if player == nil then return; end

	local buildingType = GameInfo.Buildings[buildingID];
	if buildingType == nil then return; end
	buildingType = buildingType.BuildingType;
	print('[CCB-Legacy] BuildingConstructed p' .. tostring(playerID) .. ' b=' .. tostring(buildingType));

	-- 读最近记录的政体（Gameplay 层无法实时读政体，GovernmentChanged 已维护）
	local govtType = player:GetProperty(PROP_CURRENT_GOVT);

	-- 一级类建筑：记录"该政体已拥有一级传承卡"
	if T1_BUILDINGS[buildingType] then
		print('[CCB-Legacy] T1 building, govt=' .. tostring(govtType));
		if govtType == nil then return; end
		local t1 = T1_MAP[govtType];
		if t1 ~= nil then
			local list = SplitList(player:GetProperty(PROP_T1_CARDS));
			if not ListContains(list, t1.key) then
				table.insert(list, t1.key);
				player:SetProperty(PROP_T1_CARDS, JoinList(list));
				print('[CCB-Legacy] T1 recorded: ' .. t1.key .. ' -> cards=' .. JoinList(list));
			else
				print('[CCB-Legacy] T1 already recorded: ' .. t1.key);
			end
		else
			print('[CCB-Legacy] govt not in T1_MAP, skip');
		end
		return;
	end

	-- 二级政体建筑完成：升级全部未升级的一级传承卡
	if T2_BUILDINGS[buildingType] then
		print('[CCB-Legacy] T2 building, govt=' .. tostring(govtType));
		if govtType == nil or not IsT2Government(govtType) then
			print('[CCB-Legacy] not T2 govt, skip upgrade');
			return;
		end

		local t1List = SplitList(player:GetProperty(PROP_T1_CARDS));
		local upList = SplitList(player:GetProperty(PROP_UPGRADED));
		print('[CCB-Legacy] t1Cards=' .. JoinList(t1List) .. ' | upgraded=' .. JoinList(upList));

		for _, t1Key in ipairs(t1List) do
			local alreadyUpgraded = false;
			for _, u in ipairs(upList) do
				local k = string.match(u, '^([^:]+)');
				if k == t1Key then alreadyUpgraded = true; break; end
			end
			if not alreadyUpgraded then
				local t1Card = nil;
				local t1Govt = T1_KEY_TO_GOVT[t1Key];
				if t1Govt ~= nil then t1Card = T1_MAP[t1Govt].card; end
				if t1Card ~= nil then
					local target, bTrade = GetUpgradeTarget(t1Key, govtType);
					print('[CCB-Legacy] upgrade ' .. t1Key .. '(' .. tostring(t1Card) .. ') -> ' .. tostring(target));
					if target ~= nil then
						SwapCards(player, t1Card, target);
						if bTrade and player:GetProperty(PROP_TRADE_BONUS) ~= 1 then
							player:AttachModifierByID('CCB_UPG_TRADE_ROUTE_CAP');
							player:SetProperty(PROP_TRADE_BONUS, 1);
						end
						table.insert(upList, t1Key .. ':' .. target);
						print('[CCB-Legacy] upgraded: ' .. t1Key .. ':' .. target);
					end
				end
			end
		end

		player:SetProperty(PROP_UPGRADED, JoinList(upList));
		PurgeUpgradedT1Cards(player);
		return;
	end

	-- 三级政体建筑完成：升级已升二级卡为三级卡（按当时三级政体方向）
	-- ⚠ 2026-09 用户决策：一生最多升 1 张三卡（瑞典女王图书馆双卡场景平衡）
	--   → 只升 PROP_UPGRADED 顺序第一条未升三的二级卡（=最早完成二级升级的线），
	--     其余二级卡保持二级、可装备（对应线三卡未解锁 → Obsolete 不触发，天然保留）
	if T3_BUILDINGS[buildingType] then
		print('[CCB-Legacy] T3 building, govt=' .. tostring(govtType));
		if govtType == nil or not IsT3Government(govtType) then
			print('[CCB-Legacy] not T3 govt, skip T3 upgrade');
			return;
		end
		local suffix = T3_GOVT_TO_SUFFIX[govtType];
		local upList = SplitList(player:GetProperty(PROP_UPGRADED));
		local t3List = SplitList(player:GetProperty(PROP_T3_UPGRADED));
		print('[CCB-Legacy] T3 candidates: ' .. JoinList(upList) .. ' | alreadyT3=' .. JoinList(t3List));

		-- 一生上限 1：已有任一三卡则不再升（重建市政广场再触发也不升第二条）
		if #t3List > 0 then
			print('[CCB-Legacy] T3 cap reached (1), skip');
			return;
		end

		for _, u in ipairs(upList) do
			local t1Key = string.match(u, '^([^:]+)');
			local t2Card = string.match(u, ':([^:]+)');
			if t1Key ~= nil and t2Card ~= nil then
				local t3Card = t2Card .. '_' .. suffix; -- POLICY_CCB_GOV_*_DIPLO -> *_DIPLO_FASCISM 等
				if GameInfo.Policies[t3Card] ~= nil then
					print('[CCB-Legacy] T3 upgrade ' .. t1Key .. '(' .. t2Card .. ') -> ' .. t3Card);
					SwapCards(player, t2Card, t3Card);
					table.insert(t3List, t1Key .. ':' .. t3Card);
					print('[CCB-Legacy] T3 upgraded: ' .. t1Key .. ':' .. t3Card);
					break; -- 只升第一条未升三的线；其余二级卡保留
				else
					print('[CCB-Legacy] T3 card not found: ' .. tostring(t3Card));
				end
			end
		end

		player:SetProperty(PROP_T3_UPGRADED, JoinList(t3List));
		PurgeUpgradedT1Cards(player); -- 防回插兜底（含已升三的线：一级卡仍不该装回）
		return;
	end
end
GameEvents.BuildingConstructed.Add(OnBuildingConstructed);

-- ===========================================================================
-- 事件C：每回合 → 防回插 + 使者产出双向棘轮（严格挂卡版）
-- 使者产出机制（LegacyCards.sql 2.4，引擎实测定稿 + 用户确认）：
--   ⚠ 引擎无 detach；PER_USED_INFLUENCE_TOKEN 只支持金币；MinimumTokens 需求不生效 →
--     正向池 FLAT(+1) / 负向池 NEG(-1) 平面产出（MODIFIER_PLAYER_ADJUST_YIELD_CHANGE），
--     目标档 T =（DIPLO 卡当前装备中）? ⌊使者/2⌋封顶10 : 0；T>净档 → 补挂正向，
--     T<净档 → 补挂负向对冲 → 严格"挂卡才生效 + 随使者数双向动态"。
--     ⚠ 已知限制：Lua 动态效果无法显示在卡面（静态文本描述）。
-- ===========================================================================
-- 卡名是否 DIPLO 线（二级 POLICY_CCB_GOV_*_DIPLO 与三级 *_DIPLO_* 均含 '_DIPLO' 段）
local function IsDiploLineCard(cardType)
	return cardType ~= nil and string.find(cardType, '_DIPLO', 1, true) ~= nil;
end

-- 读玩家数值属性（空值安全：GetProperty 对未设置属性返回空，不能直接塞 tonumber）
local function PropNum(player, prop)
	local v = player:GetProperty(prop);
	if v == nil then return 0; end
	if type(v) == 'number' then return v; end
	local ok, n = pcall(function() return tonumber(v); end);
	if ok and n ~= nil then return n; end
	return 0;
end

-- DIPLO 卡是否正装备在政策槽中
local function IsDiploCardEquipped(culture)
	if culture == nil or culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil then return false; end
	local nSlots = culture:GetNumPolicySlots();
	for i = 0, nSlots - 1 do
		local policyHash = culture:GetSlotPolicy(i);
		if policyHash ~= -1 then
			local info = GameInfo.Policies[policyHash];
			if info ~= nil and IsDiploLineCard(info.PolicyType) then return true; end
		end
	end
	return false;
end

-- FAITH 线升级卡（二级 POLICY_CCB_GOV_*_FAITH 与三级 *_FAITH_FASCISM / _COMMUNISM / _DEMOCRACY）是否正装备
local function IsFaithCardEquipped(culture)
	if culture == nil or culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil then return false; end
	local nSlots = culture:GetNumPolicySlots();
	for i = 0, nSlots - 1 do
		local policyHash = culture:GetSlotPolicy(i);
		if policyHash ~= nil and policyHash ~= -1 then
			local info = GameInfo.Policies[policyHash];
			if info ~= nil and string.find(info.PolicyType, '_FAITH', 1, true) ~= nil then return true; end
		end
	end
	return false;
end

-- ===========================================================================
-- 神权升级卡「外国信徒 → 文化/信仰」产出（LegacyCards.sql 2.6，2026-09-19 改为 Lua 自算）
--
-- 为什么不走引擎原生修正器（三次实测全部失败，详见 LegacyCards.sql 2.6 注释）：
--   · 0.5 小数被取整为 0；换类型后 2 个信徒给 +15；再换"教会天下同款类型"后变成每信徒 +7
--   ★ 根因：原版"信徒类"信条产出是【逐城结算】的 → 等于「每座信奉城市 × ⌊外国信徒÷2⌋」，
--     城市越多越离谱；引擎原生类型无法表达"帝国级、每 2 个外国信徒 +1"。
--
-- 现方案：每回合自算目标档 T，用【二进制档位】正负对冲（引擎无 detach）：
--   目标 T =（装了 FAITH 卡 且 已创立宗教）? ⌊引擎口径外国信徒 ÷ 2⌋ : 0   （上限 511）
--   升档 → 按 T−net 的二进制补挂 CCB_FF_POS_*；降档 → 按 net−T 的二进制补挂 CCB_FF_NEG_* 对冲
--   → 任意 T 最多挂 9 个修正器；卸卡即归零；信徒升降双向跟随；不封顶（1~256 档位）
--
-- 引擎 API（出处已实证）：
--   player:GetStats():GetNumForeignFollowers() —— MABC\RUIVO_STAT_MODULE_GP.lua:1990
--   player:GetReligion():GetReligionTypeCreated() —— 原版 ReligionScreen.lua:123（-1 = 未创立宗教）
-- ===========================================================================
local CCB_FF_TIERS = { 256, 128, 64, 32, 16, 8, 4, 2, 1 };   -- 从大到小，便于二进制拆分
local CCB_FF_MAX = 511;

local function UpdateForeignFollowerYield(player)
	local culture = GetCulture(player);
	local equipped = IsFaithCardEquipped(culture);
	local followers = 0;
	local target = 0;
	if equipped then
		local okRel, pReligion = pcall(function() return player:GetReligion(); end);
		if okRel and pReligion ~= nil and pReligion.GetReligionTypeCreated ~= nil then
			local iReligion = pReligion:GetReligionTypeCreated();
			if iReligion ~= nil and iReligion >= 0 then
				local okN, n = pcall(function() return player:GetStats():GetNumForeignFollowers(); end);
				if okN and n ~= nil and n > 0 then
					followers = n;
				elseif not okN then
					-- 读不到就让日志说话（下一次会据此加备用算法）
					print('[CCB-Legacy] p' .. tostring(player:GetID())
						.. ' GetNumForeignFollowers 失败: ' .. tostring(n));
				end
				target = math.floor(followers / 2);
				if target > CCB_FF_MAX then target = CCB_FF_MAX; end
			end
		end
	end
	local net = PropNum(player, PROP_FF_NET);
	if target == net then return; end
	local delta = target - net;
	local sign = (delta > 0) and 'POS' or 'NEG';
	local remain = math.abs(delta);
	for _, v in ipairs(CCB_FF_TIERS) do
		if remain >= v then
			remain = remain - v;
			player:AttachModifierByID('CCB_FF_' .. sign .. '_CUL_' .. v);
			player:AttachModifierByID('CCB_FF_' .. sign .. '_FAI_' .. v);
		end
	end
	player:SetProperty(PROP_FF_NET, target);
	print('[CCB-Legacy] p' .. tostring(player:GetID()) .. ' foreign-follower tier ' .. tostring(net)
		.. ' -> ' .. tostring(target) .. ' (' .. sign .. ' ' .. tostring(math.abs(delta))
		.. ' | followers=' .. tostring(followers) .. ' equipped=' .. tostring(equipped) .. ')');
end

-- ===========================================================================
-- 政体固有 × 传承卡基础效果 的「重复结算抵消」（方案 B，2026-09-20 用户确认）
--
-- 问题：引擎原生"处于该政体时隐藏该政体传承卡"只覆盖 Governments.PolicyToUnlock 绑定的那张【一级卡】；
--       我们自建的二级/三级升级卡不在规则内 → 在该政体内仍可装备 → 政体固有与卡片基础同项双计：
--         寡头 +4→+8 战斗力｜古典共和 宜居/住房 +1→+2｜独裁 粮/锤 +1→+2
-- 修法：Lua 每回合判断「当前处于该线政体 且 槽里有该线传承卡」→ 挂【负向抵消】扣掉重复那一份；
--       状态解除 → 挂【正向抵消】还原（引擎无 detach → 正负池对冲，净额恒为"只算一次"）。
--       升级卡的其它附加效果（+1 移速 / 海军经验 / T3 方向效果）不在抵消范围，照常生效。
-- 口径：抵消范围必须等于"两份效果真正重叠的范围"（详见 LegacyCards.sql §6 注释）
--   · 寡头   → 同兵种（近战/抗骑/海军近战）+ ±4 战斗力能力
--   · 共和   → 按【政体口径】CITY_HAS_1_SPECIALTY_DISTRICT（卡片是全城市，政体只给有区域的城市）
--   · 独裁   → 按【卡片口径】CCB_REQSET_AUTOCRACY_MONUMENT_SPECIALTY
-- 当前政体读取：player:GetGovernment() 不存在（见本文件顶部 API 备注）→ 用 PROP_CURRENT_GOVT
-- （由 Events.GovernmentChanged 维护；政体变更当场也会调用本函数，避免多算一整回合）
-- ===========================================================================
local OFFSET_LINES = {
	{ prop = 'CCB_LEGACY_OFF_NET_OLI', govt = 'GOVERNMENT_OLIGARCHY', tag = 'OLIGARCHY',
	  neg = { 'CCB_OLI_OFFSET_GRANT_NEG' }, pos = { 'CCB_OLI_OFFSET_GRANT_POS' } },
	{ prop = 'CCB_LEGACY_OFF_NET_REP', govt = 'GOVERNMENT_CLASSICAL_REPUBLIC', tag = 'REPUBLIC',
	  neg = { 'CCB_REP_OFFSET_NEG_AMENITY', 'CCB_REP_OFFSET_NEG_HOUSING' },
	  pos = { 'CCB_REP_OFFSET_POS_AMENITY', 'CCB_REP_OFFSET_POS_HOUSING' } },
	{ prop = 'CCB_LEGACY_OFF_NET_AUT', govt = 'GOVERNMENT_AUTOCRACY', tag = 'AUTOCRACY',
	  neg = { 'CCB_AUT_OFFSET_NEG_FOOD', 'CCB_AUT_OFFSET_NEG_PROD' },
	  pos = { 'CCB_AUT_OFFSET_POS_FOOD', 'CCB_AUT_OFFSET_POS_PROD' } },
};

-- 政策槽里是否装了该线的传承卡（一级/二级/三级都算，卡名含该线关键字）
local function HasLineCardSlotted(culture, tag)
	if culture == nil or culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil then return false; end
	local nSlots = culture:GetNumPolicySlots();
	for i = 0, nSlots - 1 do
		local h = culture:GetSlotPolicy(i);
		if h ~= nil and h ~= -1 then
			local info = GameInfo.Policies[h];
			if info ~= nil and string.find(info.PolicyType, tag, 1, true) ~= nil then return true; end
		end
	end
	return false;
end

function UpdateGovernmentDoubleOffset(player)
	if player == nil then return; end
	local culture = GetCulture(player);
	if culture == nil then return; end
	local curGovt = player:GetProperty(PROP_CURRENT_GOVT);
	for _, line in ipairs(OFFSET_LINES) do
		local desired = 0;
		if curGovt == line.govt and HasLineCardSlotted(culture, line.tag) then desired = -1; end
		local net = PropNum(player, line.prop);
		if desired ~= net then
			local steps = math.abs(desired - net);
			local ids = (desired < net) and line.neg or line.pos;
			for _ = 1, steps do
				for _, id in ipairs(ids) do player:AttachModifierByID(id); end
			end
			player:SetProperty(line.prop, desired);
			print('[CCB-Legacy] p' .. tostring(player:GetID()) .. ' govt-offset ' .. line.tag
				.. ' ' .. tostring(net) .. '->' .. tostring(desired)
				.. ' (govt=' .. tostring(curGovt) .. ')');
		end
	end
end

function OnGameTurnStarted(turn)
	local ids = PlayerManager.GetAliveMajorIDs();
	for _, playerID in ipairs(ids) do
		local player = Players[playerID];
		if player ~= nil then
			-- 防回插（设计文档§七）：每回合检查已升级一级卡是否被手动装回，是则移出。
			PurgeUpgradedT1Cards(player);

			-- 使者产出（仅 DIPLO 升级持有者参与计算；二级/三级 DIPLO 卡均算）
			local upList = SplitList(player:GetProperty(PROP_UPGRADED));
			local t3List = SplitList(player:GetProperty(PROP_T3_UPGRADED));
			local hasDiploUpgrade = false;
			for _, u in ipairs(upList) do
				local card = string.match(u, ':([^:]+)');
				if card ~= nil and IsDiploLineCard(card) then hasDiploUpgrade = true; break; end
			end
			if not hasDiploUpgrade then
				for _, u in ipairs(t3List) do
					local card = string.match(u, ':([^:]+)');
					if card ~= nil and IsDiploLineCard(card) then hasDiploUpgrade = true; break; end
				end
			end
			if hasDiploUpgrade then
				local culture = GetCulture(player);
				local equipped = IsDiploCardEquipped(culture);
				local target = 0;
				local envoys = 0;
				if equipped then
					envoys = CountEnvoys(player);
					target = math.floor(envoys / 2);
					if target > 10 then target = 10; end
				end
				local pos = PropNum(player, PROP_ENVOY_POS);
				local neg = PropNum(player, PROP_ENVOY_NEG);
				if pos == 0 and neg == 0 then
					-- 旧版（单向棘轮）存档迁移：已挂 FLAT_1..PROP_ENVOY_MAX
					local legacy = PropNum(player, PROP_ENVOY_MAX);
					if legacy > 0 then pos = legacy; end
				end
				local net = pos - neg;
				if target > net then
					for i = 1, target - net do
						pos = pos + 1;
						player:AttachModifierByID('CCB_ENVOY_FLAT_SCI_' .. pos);
						player:AttachModifierByID('CCB_ENVOY_FLAT_FAI_' .. pos);
						print('[CCB-Legacy] p' .. tostring(playerID) .. ' envoy +tier ' .. tostring(pos)
							.. ' (T=' .. tostring(target) .. ' envoys=' .. tostring(envoys)
							.. ' equipped=' .. tostring(equipped) .. ')');
					end
				elseif target < net then
					for i = 1, net - target do
						neg = neg + 1;
						player:AttachModifierByID('CCB_ENVOY_NEG_SCI_' .. neg);
						player:AttachModifierByID('CCB_ENVOY_NEG_FAI_' .. neg);
						print('[CCB-Legacy] p' .. tostring(playerID) .. ' envoy -tier ' .. tostring(neg)
							.. ' (T=' .. tostring(target) .. ' net=' .. tostring(net)
							.. ' equipped=' .. tostring(equipped) .. ')');
					end
				end
				player:SetProperty(PROP_ENVOY_POS, pos);
				player:SetProperty(PROP_ENVOY_NEG, neg);
			end

			-- 神权卡「外国信徒 → 文化/信仰」：Lua 自算 + 二进制档位（见 UpdateForeignFollowerYield 上方说明）
			UpdateForeignFollowerYield(player);

			-- 政体固有 × 传承卡基础效果 的重复结算抵消（方案 B，见 UpdateGovernmentDoubleOffset 上方说明）
			UpdateGovernmentDoubleOffset(player);
		end
	end
end
GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted);

-- ===========================================================================
-- 使者统计（玩家在所有城邦的使者总数）
-- 引擎 API（基础游戏 UI\PartialScreens\CityStates.lua L1442-1455 实证）：
--   ⚠ PlayerManager.GetAliveMinors() 返回【玩家对象】而非 ID！
--     （GetAliveMajorIDs / GetAliveMinorIDs 才返回 ID）
--   对象直接:GetInfluence():GetTokensReceived(玩家ID)；无使者时可能返回 -1/0 → 只累加正数
-- ===========================================================================
function CountEnvoys(player)
	local total = 0;
	local myID = player:GetID();
	local minors = PlayerManager.GetAliveMinors();
	for _, minor in ipairs(minors) do
		if minor ~= nil then
			local okGet, mi = pcall(function() return minor:GetInfluence(); end);
			if okGet and mi ~= nil and mi.GetTokensReceived ~= nil then
				local okTok, tokens = pcall(function() return mi:GetTokensReceived(myID); end);
				if okTok and tokens ~= nil and tokens > 0 then total = total + tokens; end
			end
		end
	end
	return total;
end

print("[CCB] Legacy Cards upgrade system (event-driven) loaded.");

-- ===========================================================================
-- [探针·临时 2026-09-19] 传承卡「外国信徒 → 文化/信仰」收益探针（拿到数据后必须整段删除）
--
-- 背景：用户实测「激活 2 个外国信徒 → +5 文化 / +5 信仰」，与设计（每信徒 +0.5，即每 2 个 +1）
--       差一个数量级。而本卡用的 `MODIFIER_PLAYER_RELIGION_ADD_PLAYER_BELIEF_YIELD` 在原版里
--       **只**与 `BELIEF_YIELD_PER_FOREIGN_CITY` 搭配（韩国"最后先知"= 每座外国城市 +1 科技）；
--       原版配 `BELIEF_YIELD_PER_FOREIGN_FOLLOWER` 的是另一个类型
--       `MODIFIER_PLAYER_RELIGION_ADD_RELIGIOUS_BELIEF_YIELD`（教会天下 / 跨文化对话，外面套
--       `MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER` + `PLAYER_FOUNDED_RELIGION_REQUIREMENTS`）。
--       → 因此必须实测：引擎在这套"非原版组合"下到底按什么口径计数、按什么公式给产出。
--
-- 本探针每回合打印一行：
--   ① 引擎口径的信徒统计（本国 / 外国主要文明 / 城邦，分开统计——"外国"是否含城邦未知）
--   ② 该玩家当前每回合 文化 / 信仰 总量
--   ③ 该玩家政策槽里是否装着我们这条线的 FAITH 卡
--   ④ 几个候选公式的预测值
-- 用法：挂卡停 1 回合、卸卡再停 1 回合，把两行 [CCB-Probe-FF] 发回 → 用"产出差 ÷ 信徒数"反推公式。
--
-- API 出处（均为原版 UI 实证，勿改）：
--   pPlayer:GetReligion():GetReligionTypeCreated()   —— ReligionScreen.lua:123（-1 = 未创立宗教）
--   pPlayer:GetCulture():GetCultureYield()           —— WorldRankings.lua:37
--   pPlayer:GetReligion():GetFaithYield()            —— WorldRankings.lua:48
--   pCity:GetReligion():GetReligionsInCity()         —— CityBannerManager.lua:1230（字段 .Religion/.Followers）
-- ===========================================================================
local PROBE_FF_ENABLED = true;

local function ProbeFF_ReligionName(iReligion)
	local row = GameInfo.Religions[iReligion];
	if row ~= nil then return row.ReligionType; end
	return tostring(iReligion);
end

-- 统计某玩家"创立宗教"的信徒分布（2026-09-20 加固：任何一步失败都只记录错误文本，绝不让整行探针失效）
local function ProbeFF_CountFollowers(player, iReligion, out)
	out.errs = out.errs or {};
	local myID = player:GetID();
	local function Scan(other, isMinor)
		if other == nil then return; end
		local okCities, cities = pcall(function() return other:GetCities(); end);
		if not okCities then table.insert(out.errs, 'GetCities:' .. tostring(cities)); return; end
		if cities == nil then return; end
		local okLoop, errLoop = pcall(function()
			for _, city in cities do
				local okRel, pRel = pcall(function() return city:GetReligion(); end);
				if not okRel then
					table.insert(out.errs, 'GetReligion:' .. tostring(pRel));
				elseif pRel ~= nil then
					local okList, list = pcall(function() return pRel:GetReligionsInCity(); end);
					if not okList then
						table.insert(out.errs, 'GetReligionsInCity:' .. tostring(list));
					elseif list ~= nil then
						for _, entry in pairs(list) do
							local rel, fol = entry.Religion, entry.Followers;
							if rel == nil then rel = entry[1]; end
							if fol == nil then fol = entry[2]; end
							if rel == iReligion and fol ~= nil and fol > 0 then
								if other:GetID() == myID then
									out.own = out.own + fol;
								elseif isMinor then
									out.minor = out.minor + fol;
									out.minorCities = out.minorCities + 1;
								else
									out.major = out.major + fol;
									out.majorCities = out.majorCities + 1;
								end
							end
						end
					end
				end
			end
		end);
		if not okLoop then table.insert(out.errs, 'scan:' .. tostring(errLoop)); end
	end
	local okIds, ids = pcall(function() return PlayerManager.GetAliveMajorIDs(); end);
	if okIds and ids ~= nil then
		for _, pid in ipairs(ids) do
			local ok, err = pcall(function() Scan(Players[pid], false); end);
			if not ok then table.insert(out.errs, 'major:' .. tostring(err)); end
		end
	end
	local okMinors, minors = pcall(function() return PlayerManager.GetAliveMinors(); end);
	if okMinors and minors ~= nil then
		for _, minor in ipairs(minors) do
			local ok, err = pcall(function() Scan(minor, true); end);
			if not ok then table.insert(out.errs, 'minor:' .. tostring(err)); end
		end
	end
end

-- 政策槽里装着的 CCB 卡（沿用 IsDiploCardEquipped 的取槽写法）
local function ProbeFF_SlottedCCBCards(player)
	local culture = player:GetCulture();
	if culture == nil or culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil then return "<未知>"; end
	local found = {};
	local nSlots = culture:GetNumPolicySlots();
	for i = 0, nSlots - 1 do
		local policyHash = culture:GetSlotPolicy(i);
		if policyHash ~= nil and policyHash ~= -1 then
			local info = GameInfo.Policies[policyHash];
			if info ~= nil and string.find(info.PolicyType, 'CCB_', 1, true) ~= nil then
				table.insert(found, string.gsub(info.PolicyType, 'POLICY_', ''));
			end
		end
	end
	if #found == 0 then return "<无CCB卡>"; end
	return table.concat(found, ',');
end

-- 上一回合产出（用于打印逐回合变化，判断"卸卡后数值有没有掉"）
local PROBE_FF_PREV = {};

-- 重复结算抵消的当前状态（0 = 未抵消；-1 = 已挂一份负向抵消）
local function ProbeOffsetStr(player)
	local parts = {};
	for _, line in ipairs(OFFSET_LINES) do
		table.insert(parts, string.sub(line.tag, 1, 3) .. '=' .. tostring(PropNum(player, line.prop)));
	end
	return table.concat(parts, ',');
end

function OnForeignFollowerProbe(turn)
	if not PROBE_FF_ENABLED then return; end
	local ids = PlayerManager.GetAliveMajorIDs();
	for _, playerID in ipairs(ids) do
		local player = Players[playerID];
		if player ~= nil and player:IsHuman() then
			local okRel, pReligion = pcall(function() return player:GetReligion(); end);
			if okRel and pReligion ~= nil and pReligion.GetReligionTypeCreated ~= nil then
				local iReligion = pReligion:GetReligionTypeCreated();
				local okC, cultureYield = pcall(function() return player:GetCulture():GetCultureYield(); end);
				local okF, faithYield = pcall(function() return pReligion:GetFaithYield(); end);
				local okN, nCitiesFaith = pcall(function() return player:GetStats():GetNumCitiesFollowingReligion(); end);
				-- 引擎自己的信徒口径（关键！BELIEF_YIELD_PER_FOREIGN_FOLLOWER 用的就是这个口径）
				-- API 出处：MABC\RUIVO_STAT_MODULE_GP.lua:1973/1990（GetNumFollowers / GetNumForeignFollowers）
				local nFollow, nForeign = -1, -1;
				local okSt, pStats = pcall(function() return player:GetStats(); end);
				if okSt and pStats ~= nil then
					local okF1, v1 = pcall(function() return pStats:GetNumFollowers(); end);
					local okF2, v2 = pcall(function() return pStats:GetNumForeignFollowers(); end);
					if okF1 and v1 ~= nil then nFollow = v1; end
					if okF2 and v2 ~= nil then nForeign = v2; end
				end
				-- 逐回合变化
				local prev = PROBE_FF_PREV[playerID];
				local dC, dF = 0, 0;
				if prev ~= nil then
					if okC and prev.culture ~= nil then dC = cultureYield - prev.culture; end
					if okF and prev.faith ~= nil then dF = faithYield - prev.faith; end
				end
				PROBE_FF_PREV[playerID] = {
					culture = okC and cultureYield or nil,
					faith = okF and faithYield or nil };
				if iReligion ~= nil and iReligion >= 0 then
					local out = { own = 0, major = 0, minor = 0, majorCities = 0, minorCities = 0, errs = {} };
					local ok = pcall(function() ProbeFF_CountFollowers(player, iReligion, out); end);
					if not ok then table.insert(out.errs, 'fatal'); end
					local total = out.own + out.major + out.minor;
					local fEngine = (nForeign >= 0) and math.floor(nForeign / 2) or -1;
					local scanStr = string.format("我方统计: 本国=%d 外国主要=%d(%d城) 城邦=%d(%d城) 合计=%d",
						out.own, out.major, out.majorCities, out.minor, out.minorCities, total);
					if #out.errs > 0 then
						scanStr = scanStr .. " [扫描错误: " .. table.concat(out.errs, '; ') .. "]";
					end
					print(string.format(
						"[CCB-Probe-FF] T%d p%d 宗教=%s | 引擎口径: 总信徒=%d 外国信徒=%d 信奉城市=%d | 产出: 文化=%.1f(Δ%+.1f) 信仰=%.1f(Δ%+.1f) | 卡=%s | Lua: FF净档=%d 应=%d 使者正/负=%d/%d | 抵消[%s] 当前政体=%s | %s",
						turn, playerID, ProbeFF_ReligionName(iReligion),
						nFollow, nForeign, (okN and nCitiesFaith) or -1,
						(okC and cultureYield) or -1, dC, (okF and faithYield) or -1, dF,
						ProbeFF_SlottedCCBCards(player),
						PropNum(player, 'CCB_LEGACY_FF_NET'), fEngine,
						PropNum(player, 'CCB_LEGACY_ENVOY_POS'), PropNum(player, 'CCB_LEGACY_ENVOY_NEG'),
						ProbeOffsetStr(player), tostring(player:GetProperty('CCB_LEGACY_CURRENT_GOVT')),
						scanStr));
				else
					print(string.format("[CCB-Probe-FF] T%d p%d 尚未创立宗教 | 产出: 文化=%.1f(Δ%+.1f) 信仰=%.1f(Δ%+.1f) | 卡=%s | 引擎口径: 总信徒=%d 外国信徒=%d | 抵消[%s] 当前政体=%s —— 本卡设计上需已创立宗教",
						turn, playerID, (okC and cultureYield) or -1, dC, (okF and faithYield) or -1, dF,
						ProbeFF_SlottedCCBCards(player), nFollow, nForeign,
						ProbeOffsetStr(player), tostring(player:GetProperty('CCB_LEGACY_CURRENT_GOVT'))));
				end
			end
		end
	end
end
GameEvents.OnGameTurnStarted.Add(OnForeignFollowerProbe);

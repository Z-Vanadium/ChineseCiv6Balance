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
--	✅ 引擎 API（游戏内实测确认，2026-09；当时用的临时探针已全部移除）：
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
-- 政体固有 × 传承卡效果 的「重复结算抵消」（方案 B，2026-09-20 用户确认；2026-10-14 扩到独裁全类）
--
-- 问题：引擎原生"处于该政体时隐藏该政体传承卡"只覆盖 Governments.PolicyToUnlock 绑定的那张【一级卡】；
--       我们自建的二级/三级升级卡不在规则内 → 在该政体内仍可装备 → 政体固有与卡片效果同项双计：
--         寡头 +4→+8 战斗力｜古典共和 宜居/住房 +1→+2｜独裁 粮/锤 +1→+2、宫殿/广场区/外交区/其中的建筑 各 +1→+2
-- 修法：Lua 每回合判断「当前处于该线政体 且 槽里装着该线的 CCB 升级卡」→ 挂【负向抵消】扣掉重复那一份；
--       状态解除 → 挂【正向抵消】还原（引擎无 detach → 正负池对冲，净额恒为"只算一次"）。
--       升级卡的其它附加效果（移速 / 海军经验 / T3 方向效果 / 影响力 / 信仰% / 金币%）不在抵消范围，照常生效。
-- 口径：抵消范围必须等于"两份效果真正重叠的范围"（详见 LegacyCards.sql §6 与 Policies_XP1_or_XP2.sql §5.2.7）
--   · 寡头   → 同兵种（近战/抗骑/海军近战）+ ±4 战斗力能力
--   · 共和   → 按【政体口径】CITY_HAS_1_SPECIALTY_DISTRICT（卡片是全城市，政体只给有区域的城市）
--   · 独裁   → ① 纪念碑粮/锤按【卡片口径】CCB_REQSET_AUTOCRACY_MONUMENT_SPECIALTY（既有 2 条）
--              ② 2026-10-14 新增 8 类 × 6 产出：宫殿 / 市政广场区本身 / 外交区本身 /
--                 市政广场三建筑（GOVT1/2/3）/ 领事馆 / 大法官厅 —— id 由下方两张表拼出，
--                 必须与 Policies_XP1_or_XP2.sql §5.2.7 用 CROSS JOIN 生成的 id 完全一致
-- 当前政体读取：player:GetGovernment() 不存在（见本文件顶部 API 备注）→ 用 PROP_CURRENT_GOVT
-- （由 Events.GovernmentChanged 维护；政体变更当场也会调用本函数，避免多算一整回合）
-- ===========================================================================
-- 独裁线抵消：8 类 × 6 产出（+ 既有纪念碑粮/锤 2 条）
local AUT_OFFSET_CATS = { 'PALACE', 'PLAZA', 'DQ', 'GOVT1', 'GOVT2', 'GOVT3', 'CONSULATE', 'CHANCERY' };
local AUT_OFFSET_YIELDS = { 'YIELD_FOOD', 'YIELD_PRODUCTION', 'YIELD_GOLD', 'YIELD_SCIENCE', 'YIELD_CULTURE', 'YIELD_FAITH' };
local AUT_OFFSET_NEG = { 'CCB_AUT_OFFSET_NEG_FOOD', 'CCB_AUT_OFFSET_NEG_PROD' };
local AUT_OFFSET_POS = { 'CCB_AUT_OFFSET_POS_FOOD', 'CCB_AUT_OFFSET_POS_PROD' };
for _, cat in ipairs(AUT_OFFSET_CATS) do
	for _, y in ipairs(AUT_OFFSET_YIELDS) do
		table.insert(AUT_OFFSET_NEG, 'CCB_AUT_OFFSET_NEG_' .. cat .. '_' .. y);
		table.insert(AUT_OFFSET_POS, 'CCB_AUT_OFFSET_POS_' .. cat .. '_' .. y);
	end
end
local OFFSET_LINES = {
	-- 寡头线已于 2026-09-21 移出：运行时 AttachModifierByID 挂"授予能力"无效（实测 +8 不变），
	-- 改由数据层解决——卡片直接授予政体那个能力 ABILITY_OLIGARCHY_MELEE_BUFF（见 LegacyCards.sql §1.1）。
	{ prop = 'CCB_LEGACY_OFF_NET_REP', govt = 'GOVERNMENT_CLASSICAL_REPUBLIC', tag = 'REPUBLIC',
	  neg = { 'CCB_REP_OFFSET_NEG_AMENITY', 'CCB_REP_OFFSET_NEG_HOUSING' },
	  pos = { 'CCB_REP_OFFSET_POS_AMENITY', 'CCB_REP_OFFSET_POS_HOUSING' } },
	{ prop = 'CCB_LEGACY_OFF_NET_AUT', govt = 'GOVERNMENT_AUTOCRACY', tag = 'AUTOCRACY',
	  neg = AUT_OFFSET_NEG, pos = AUT_OFFSET_POS },
};

-- 政策槽里是否装了【该线的 CCB 升级卡】（二级/三级自建卡：id 以 POLICY_CCB_GOV_ 开头且含该线关键字）
-- ⚠ 不能用"卡名含该线关键字"来判定：一级传承卡 POLICY_GOV_AUTOCRACY / POLICY_GOV_CLASSICAL_REPUBLIC
--   名字里也含关键字，而它在本政体内会被引擎隐藏 → 若把一级卡也算进来，会在"政体内只装一级卡"时多扣一份
local function HasUpgradeCardSlotted(culture, tag)
	if culture == nil or culture.GetNumPolicySlots == nil or culture.GetSlotPolicy == nil then return false; end
	local nSlots = culture:GetNumPolicySlots();
	for i = 0, nSlots - 1 do
		local h = culture:GetSlotPolicy(i);
		if h ~= nil and h ~= -1 then
			local info = GameInfo.Policies[h];
			if info ~= nil and info.PolicyType ~= nil
				and string.find(info.PolicyType, 'POLICY_CCB_GOV_', 1, true) == 1
				and string.find(info.PolicyType, tag, 1, true) ~= nil then
				return true;
			end
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
		if curGovt == line.govt and HasUpgradeCardSlotted(culture, line.tag) then desired = -1; end
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
print("[CCB] autocracy double-offset ids: " .. tostring(#AUT_OFFSET_NEG) .. " neg / " .. tostring(#AUT_OFFSET_POS) .. " pos (2 monument + 8 categories x 6 yields)");

------------------------------------------------------------------------------
--	FILE:   ccb_probetree.lua
--	PURPOSE: [探针·临时 2026-09-22] 新科技树面板 · UI 侧（验证完必须整段删除）
--	① 往左上 LaunchBar 的 ButtonStack 注入一个按钮（与科技/市政/政体同排）
--	   方式：LookUpControl("/InGame/LaunchBar/ButtonStack") + BuildInstanceForControl(本文件模板)
--	   注入后复刻原版 LaunchBar.RealizeBacking()（Base\Assets\UI\LaunchBar.lua:498-517）
--	   重算背景条宽度并广播 LuaEvents.LaunchBar_Resize —— 原版不会知道我们后加的按钮。
--	② 点击按钮弹出主窗口（AddUserInterfaces 上下文默认隐藏 → SetHide(false) + QueuePopup）
--	③ "解锁"按钮 → UI.RequestPlayerOperation(EXECUTE_SCRIPT) → scripts/ccb_probetree.lua
--	日志前缀：[CCB-Probe-Tree]
------------------------------------------------------------------------------

local NODE_TECH     = 'TECH_CCB_PROBE_PLANTATION';
local PREREQ_TECH   = 'TECH_IRRIGATION';
local PROP_UNLOCKED = 'CCB_PROBE_TREE_UNLOCKED';
local COST_GOLD     = 150;

local m_injected = false;
local m_alert    = nil;
local RefreshPanel;		-- 前向声明：下面多个函数会用到

local function TechIndex(techType)
	local row = GameInfo.Technologies[techType];
	if row == nil then return -1; end
	return row.Index;
end

-- ===========================================================================
-- 左上 LaunchBar 按钮注入
-- ===========================================================================
local function FixLaunchBarBacking(stack)
	-- 复刻原版 RealizeBacking 的尺寸换算（+116 / -20 / 原值）
	stack:CalculateSize();
	local w = stack:GetSizeX();
	local backing = ContextPtr:LookUpControl('/InGame/LaunchBar/LaunchBacking');
	local tile    = ContextPtr:LookUpControl('/InGame/LaunchBar/LaunchBackingTile');
	local shadow  = ContextPtr:LookUpControl('/InGame/LaunchBar/LaunchBarDropShadow');
	if backing ~= nil then backing:SetSizeX(w + 116); end
	if tile    ~= nil then tile:SetSizeX(w - 20); end
	if shadow  ~= nil then shadow:SetSizeX(w); end
	LuaEvents.LaunchBar_Resize(w);	-- 通知其它上下文（DiploRibbon 等）宽度已变
	print(string.format('[CCB-Probe-Tree] LaunchBar 背景宽度已重算: stackW=%.0f', w));
end

local function HidePanel()
	UIManager:DequeuePopup(ContextPtr);
	ContextPtr:SetHide(true);
end

local function ShowPanel()
	ContextPtr:SetHide(false);
	UIManager:QueuePopup(ContextPtr, PopupPriority.High);
	if RefreshPanel ~= nil then RefreshPanel(); end
end

local function InjectLaunchBarButton()
	if m_injected then return true; end
	local stack = ContextPtr:LookUpControl('/InGame/LaunchBar/ButtonStack');
	if stack == nil then
		print('[CCB-Probe-Tree] LaunchBar/ButtonStack 尚不存在，稍后重试');
		return false;
	end

	local inst = {};
	ContextPtr:BuildInstanceForControl('CCBProbeTreeLaunchButton', inst, stack);
	if inst.CCBProbeTreeBtn == nil then
		print('[CCB-Probe-Tree] ⚠ 按钮实例构建失败（模板名或控件名不匹配）');
		return false;
	end

	inst.CCBProbeTreeBtn:RegisterCallback(Mouse.eLClick, function() ShowPanel(); end);
	inst.CCBProbeTreeBtn:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound('Main_Menu_Mouse_Over'); end);
	m_alert = inst.CCBProbeTreeAlert;
	m_injected = true;

	print('[CCB-Probe-Tree] 已向 LaunchBar.ButtonStack 注入按钮（ButtonStack 子控件数=' .. tostring(stack:GetNumChildren()) .. '）');
	FixLaunchBarBacking(stack);
	if RefreshPanel ~= nil then RefreshPanel(); end
	return true;
end

-- ===========================================================================
-- 节点卡片状态刷新
-- ===========================================================================
function RefreshPanel()
	local localPlayerID = Game.GetLocalPlayer();
	if localPlayerID == nil or localPlayerID == PlayerTypes.NONE then return; end
	local player = Players[localPlayerID];
	if player == nil then return; end

	local techs = player:GetTechs();
	local unlocked  = (player:GetProperty(PROP_UNLOCKED) ~= nil);
	local hasPrereq = techs:HasTech(TechIndex(PREREQ_TECH));
	local gold      = player:GetTreasury():GetGoldBalance();
	local canUnlock = (not unlocked) and hasPrereq and (gold >= COST_GOLD);

	local statusKey = 'LOC_CCB_PROBE_NODE_STATUS_LOCKED';
	if unlocked then
		statusKey = 'LOC_CCB_PROBE_NODE_STATUS_DONE';
	elseif not hasPrereq then
		statusKey = 'LOC_CCB_PROBE_NODE_STATUS_NOPREREQ';
	elseif gold < COST_GOLD then
		statusKey = 'LOC_CCB_PROBE_NODE_STATUS_NOGOLD';
	else
		statusKey = 'LOC_CCB_PROBE_NODE_STATUS_READY';
	end

	Controls.CCBProbeNodeStatus:SetText(string.format('%s   [HasTech(灌溉)=%s | 当前金币=%d]',
		Locale.Lookup(statusKey), tostring(hasPrereq), gold));
	Controls.CCBProbeNodeUnlock:SetDisabled(not canUnlock);

	if m_alert ~= nil then
		m_alert:SetHide(not ((not unlocked) and hasPrereq));
	end
end

-- ===========================================================================
-- 解锁请求（UI → Gameplay）
-- ===========================================================================
local function OnUnlockClicked()
	local localPlayerID = Game.GetLocalPlayer();
	print('[CCB-Probe-Tree] UI 请求解锁节点');
	UI.PlaySound('Confirm_Dedication');

	local kParameters = {};
	kParameters.OnStart = 'OnPlayerCommandSetObjectState';	-- gameplay 侧由该事件接收
	kParameters.ccbProbeCommand = 'UNLOCK_NODE';
	kParameters.playerID = localPlayerID;
	UI.RequestPlayerOperation(localPlayerID, PlayerOperations.EXECUTE_SCRIPT, kParameters);
end

-- ===========================================================================
-- 生命周期
-- ===========================================================================
local function Initialize()
	ContextPtr:SetHide(true);

	Controls.CCBProbeNodeUnlock:RegisterCallback(Mouse.eLClick, OnUnlockClicked);
	Controls.CCBProbeTreeClose:RegisterCallback(Mouse.eLClick, function() HidePanel(); end);

	-- HUD 就绪后再注入（原版面板通用钩子：LaunchBar/TopPanel/WorldTracker 均用 LoadGameViewStateDone）
	Events.LoadGameViewStateDone.Add(function()
		InjectLaunchBarButton();
	end);
	Events.LocalPlayerTurnBegin.Add(function()
		InjectLaunchBarButton();	-- 兜底重试（首帧 LaunchBar 可能还没建好）
		RefreshPanel();
	end);
	Events.TurnBegin.Add(function() RefreshPanel(); end);

	print('[CCB-Probe-Tree] UI probe script loaded.');
end

Initialize();

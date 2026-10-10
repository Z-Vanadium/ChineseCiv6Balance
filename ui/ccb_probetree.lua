------------------------------------------------------------------------------
--	FILE:   ccb_probetree.lua
--	PURPOSE: [探针·临时] 新科技树面板 · UI 侧
--	① 往左上 LaunchBar.ButtonStack 注入按钮（LookUpControl + BuildInstanceForControl），
--	   注入后复刻原版 LaunchBar.RealizeBacking()（LaunchBar.lua:498-517）重算背景宽度
--	② 弹窗：节点卡片（解锁）+ 效果矩阵（13 个候选 modifier，逐一点击验证）
--	③ 解锁/矩阵请求 → UI.RequestPlayerOperation(EXECUTE_SCRIPT) → scripts/ccb_probetree.lua
--	日志前缀：[CCB-Probe-Tree]
------------------------------------------------------------------------------

local PREREQ_TECH   = 'TECH_IRRIGATION';
local PROP_UNLOCKED = 'CCB_PROBE_TREE_UNLOCKED';
local COST_GOLD     = 150;

-- 矩阵按钮 → 效果键（与 scripts/ccb_probetree.lua 的 MATRIX 表一一对应）
local MATRIX_BUTTONS = {
	{ ctrl = 'CCBProbeM1',  key = 'M1'  },
	{ ctrl = 'CCBProbeM2',  key = 'M2'  },
	{ ctrl = 'CCBProbeM3',  key = 'M3'  },
	{ ctrl = 'CCBProbeM4',  key = 'M4'  },
	{ ctrl = 'CCBProbeM5',  key = 'M5'  },
	{ ctrl = 'CCBProbeM6',  key = 'M6'  },
	{ ctrl = 'CCBProbeM7',  key = 'M7'  },
	{ ctrl = 'CCBProbeM8',  key = 'M8'  },
	{ ctrl = 'CCBProbeM9',  key = 'M9'  },
	{ ctrl = 'CCBProbeM10', key = 'M10' },
	{ ctrl = 'CCBProbeM11', key = 'M11' },
	{ ctrl = 'CCBProbeM12', key = 'M12' },
	{ ctrl = 'CCBProbeM13', key = 'M13' },
	-- 第二轮
	{ ctrl = 'CCBProbeR2',  key = 'R2'  },
	{ ctrl = 'CCBProbeR3',  key = 'R3'  },
	{ ctrl = 'CCBProbeR4',  key = 'R4'  },
	{ ctrl = 'CCBProbeR5',  key = 'R5'  },
	{ ctrl = 'CCBProbeR6',  key = 'R6'  },
	{ ctrl = 'CCBProbeR7',  key = 'R7'  },
	{ ctrl = 'CCBProbeR8',  key = 'R8'  },
	{ ctrl = 'CCBProbeR9',  key = 'R9'  },
};

local m_injected = false;
local m_alert    = nil;
local RefreshPanel;		-- 前向声明

local function TechIndex(techType)
	local row = GameInfo.Technologies[techType];
	if row == nil then return -1; end
	return row.Index;
end

-- ===========================================================================
-- 左上 LaunchBar 按钮注入
-- ===========================================================================
local function FixLaunchBarBacking(stack)
	stack:CalculateSize();
	local w = stack:GetSizeX();
	local backing = ContextPtr:LookUpControl('/InGame/LaunchBar/LaunchBacking');
	local tile    = ContextPtr:LookUpControl('/InGame/LaunchBar/LaunchBackingTile');
	local shadow  = ContextPtr:LookUpControl('/InGame/LaunchBar/LaunchBarDropShadow');
	if backing ~= nil then backing:SetSizeX(w + 116); end
	if tile    ~= nil then tile:SetSizeX(w - 20); end
	if shadow  ~= nil then shadow:SetSizeX(w); end
	LuaEvents.LaunchBar_Resize(w);
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
-- 请求（UI → Gameplay）
-- ===========================================================================
local function SendUnlock()
	local pid = Game.GetLocalPlayer();
	print('[CCB-Probe-Tree] UI 请求解锁节点');
	UI.PlaySound('Confirm_Dedication');
	UI.RequestPlayerOperation(pid, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = 'OnPlayerCommandSetObjectState',
		ccbProbeCommand = 'UNLOCK_NODE',
		playerID = pid,
	});
end

local function SendMatrix(key)
	local pid = Game.GetLocalPlayer();
	print('[CCB-Probe-Tree] UI 请求矩阵效果 ' .. tostring(key));
	UI.PlaySound('Main_Menu_Mouse_Over');
	UI.RequestPlayerOperation(pid, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = 'OnPlayerCommandSetObjectState',
		ccbProbeCommand = 'MATRIX',
		playerID = pid,
		effectKey = key,
	});
end

-- ===========================================================================
-- 生命周期
-- ===========================================================================
local function Initialize()
	ContextPtr:SetHide(true);

	Controls.CCBProbeNodeUnlock:RegisterCallback(Mouse.eLClick, SendUnlock);
	Controls.CCBProbeTreeClose:RegisterCallback(Mouse.eLClick, function() HidePanel(); end);

	local wired, missing = 0, {};
	for _, entry in ipairs(MATRIX_BUTTONS) do
		local ctrl = Controls[entry.ctrl];
		if ctrl ~= nil then
			ctrl:RegisterCallback(Mouse.eLClick, function() SendMatrix(entry.key); end);
			wired = wired + 1;
		else
			missing[#missing + 1] = entry.ctrl;
		end
	end
	print(string.format('[CCB-Probe-Tree] 矩阵按钮已接线 %d/%d%s', wired, #MATRIX_BUTTONS,
		(#missing > 0) and ('（缺失: ' .. table.concat(missing, ',') .. '）') or ''));

	Events.LoadGameViewStateDone.Add(function() InjectLaunchBarButton(); end);
	Events.LocalPlayerTurnBegin.Add(function()
		InjectLaunchBarButton();
		RefreshPanel();
	end);
	Events.TurnBegin.Add(function() RefreshPanel(); end);

	print('[CCB-Probe-Tree] UI probe script loaded.');
end

Initialize();

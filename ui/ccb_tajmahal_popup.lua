-------------------------------------------------------------------------------
--	FILE:   ccb_tajmahal_popup.lua
--	PURPOSE: 泰姬陵「沙贾汗的黄金时代」三选一 · UI 侧
--	触发：Events.WonderCompleted → 仅本地玩家建成泰姬陵且未选择过时弹窗
--	重弹：点「稍后决定」后，未选择期间每回合开始再次弹出（Events.TurnBegin）
--	选择：UI → Gameplay 走 PlayerOperation(EXECUTE_SCRIPT) → scripts/ccb_tajmahal.lua
--	文本：全部使用 LOC 键（见 lang/chinese.xml、lang/english.xml 的 LOC_CCB_TAJ_*）
--	结构参照已验证探针 tools/archive/HGProbe_v0.1/ui/HGProbePopup.lua（UI 三坑对策已内置）
-------------------------------------------------------------------------------

local PROP_TAJ_CHOICE = 'CCB_TAJ_CHOICE';
local TAJ_BUILDING_TYPE = 'BUILDING_TAJ_MAHAL';

local m_TajBuildingIndex = nil;
do
	local info = GameInfo.Buildings[TAJ_BUILDING_TYPE];
	if info ~= nil then m_TajBuildingIndex = info.Index; end
end

local function IsAlreadyChosen(playerID)
	local player = Players[playerID];
	if player == nil then return false; end
	local v = player:GetProperty(PROP_TAJ_CHOICE);
	return v ~= nil;
end

local function ShowPopup()
	-- AddUserInterfaces 生成的上下文默认隐藏：显示上下文本身并走 QueuePopup 取得层级
	ContextPtr:SetHide(false);
	UIManager:QueuePopup(ContextPtr, PopupPriority.High);
end

local function HidePopup()
	UIManager:DequeuePopup(ContextPtr);
	ContextPtr:SetHide(true);
end

local function OnChoice(choice)
	local kParameters = {};
	kParameters.OnStart = 'OnPlayerCommandSetObjectState';	-- Gameplay 侧由该事件接收
	kParameters.ccbTajCommand = 'TAJ_CHOICE';
	kParameters.playerID = Game.GetLocalPlayer();
	kParameters.choice = choice;
	UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.EXECUTE_SCRIPT, kParameters);
	print('[CCB_Taj] requested choice ' .. tostring(choice));
	HidePopup();
end

function OnTajWonderCompleted(locX, locY, buildingIndex, playerIndex, cityId, iPercentComplete, pillaged)
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer == PlayerTypes.NONE then return; end
	if localPlayer ~= playerIndex then return; end			-- 只认本地玩家
	if m_TajBuildingIndex == nil or buildingIndex ~= m_TajBuildingIndex then return; end
	if iPercentComplete ~= nil and iPercentComplete ~= 100 then return; end
	if IsAlreadyChosen(localPlayer) then
		print('[CCB_Taj] wonder completed but choice already made, skip popup.');
		return;
	end
	print('[CCB_Taj] Taj Mahal completed by local player → show popup.');
	ShowPopup();
end

-- 未做出选择时，每回合开始重新弹出（「稍后决定」后的兜底）
function OnTajTurnBegin(playerID)
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer == PlayerTypes.NONE then return; end
	if IsAlreadyChosen(localPlayer) then return; end
	if m_TajBuildingIndex == nil then return; end
	-- 仅当本地玩家确实已拥有泰姬陵时才弹（否则开局也会弹）
	local player = Players[localPlayer];
	if player == nil then return; end
	local cities = player:GetCities();
	if cities == nil then return; end
	for _, city in cities:Members() do
		if city ~= nil and city:GetBuildings() ~= nil then
			local ok, has = pcall(function() return city:GetBuildings():HasBuilding(m_TajBuildingIndex); end);
			if ok and has then
				ShowPopup();
				return;
			end
		end
	end
end

function Initialize()
	ContextPtr:SetHide(true);
	Controls.CCBTajBtnCharbagh:RegisterCallback(Mouse.eLClick, function() OnChoice(1) end);
	Controls.CCBTajBtnInlay:RegisterCallback(Mouse.eLClick, function() OnChoice(2) end);
	Controls.CCBTajBtnCalli:RegisterCallback(Mouse.eLClick, function() OnChoice(3) end);
	Controls.CCBTajBtnLater:RegisterCallback(Mouse.eLClick, function() HidePopup(); print('[CCB_Taj] postponed.'); end);
	Events.WonderCompleted.Add(OnTajWonderCompleted);
	Events.TurnBegin.Add(OnTajTurnBegin);
	print('[CCB_Taj] UI popup script loaded.');
end

Initialize();

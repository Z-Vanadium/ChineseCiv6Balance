-------------------------------------------------------------------------------
--	FILE:   ccb_tajmahal.lua
--	PURPOSE: 泰姬陵「沙贾汗的黄金时代」三选一 · Gameplay 侧
--	         接收 UI 选择 → player:AttachModifierByID 挂对应修饰器 + 记录选择（只允许一次）
--	桥：UI.RequestPlayerOperation(EXECUTE_SCRIPT, {OnStart="OnPlayerCommandSetObjectState", ...})
--	    → GameEvents.OnPlayerCommandSetObjectState（工程内先例 scripts/bbg_stateutils.lua）
--	说明：所有效果修饰器均带 OwnerRequirementSetId=PLAYER_HAS_GOLDEN_AGE（见 sql/CCB_TajMahal.sql）
--	      → 黄金/英雄时代生效，非黄金自动失效，无需 Lua 管理生命周期
--	结构参照已验证探针 tools/archive/HGProbe_v0.1/lua/HGProbe_Gameplay.lua
-------------------------------------------------------------------------------

local PROP_TAJ_CHOICE = 'CCB_TAJ_CHOICE';

-- 选项 → 修饰器清单（1 四分园 / 2 镶嵌工艺 / 3 铭文之壁）
-- 2026-09-20 增强：选项 1 由"全城 +1 宜居"扩为"全城 +1 宜居 +1 住房 +15% 发展速度"（三条修饰器）
--                 选项 2 工作坊大工程师点 1→2；选项 3 三条伟人点（剧院→作家+艺术家、古罗马→作家，古罗马不给艺术家）
local TAJ_CHOICE_MODIFIERS = {
	[1] = { 'CCB_TAJ_CHARBAGH_AMENITY', 'CCB_TAJ_CHARBAGH_HOUSING', 'CCB_TAJ_CHARBAGH_GROWTH' },
	[2] = { 'CCB_TAJ_INLAY_BUILDER', 'CCB_TAJ_INLAY_IZ_GEP', 'CCB_TAJ_INLAY_WORKSHOP_GEP' },
	[3] = { 'CCB_TAJ_CALLI_WRITER', 'CCB_TAJ_CALLI_ARTIST_THEATER', 'CCB_TAJ_CALLI_WRITER_AMPHI',
	        'CCB_TAJ_CALLI_WRITING_TOURISM', 'CCB_TAJ_CALLI_RELIGIOUS_TOURISM' },
};

function OnCCBTajMahalCommand(ePlayer, params)
	if params == nil or params.ccbTajCommand ~= 'TAJ_CHOICE' then
		return;
	end

	local playerID = params.playerID;
	local choice = params.choice;
	if playerID == nil or choice == nil then return; end

	local player = Players[playerID];
	if player == nil then return; end

	-- 只允许选择一次（防重复挂载；读档后 Property 仍在）
	local existing = player:GetProperty(PROP_TAJ_CHOICE);
	if existing ~= nil then
		print('[CCB_Taj] already chosen: ' .. tostring(existing) .. ' (ignore new ' .. tostring(choice) .. ')');
		return;
	end

	local modifiers = TAJ_CHOICE_MODIFIERS[choice];
	if modifiers == nil then
		print('[CCB_Taj] invalid choice: ' .. tostring(choice));
		return;
	end

	for _, modifierId in ipairs(modifiers) do
		local ok = pcall(function() player:AttachModifierByID(modifierId); end);
		print('[CCB_Taj] p' .. tostring(playerID) .. ' attach ' .. modifierId .. ' ok=' .. tostring(ok));
	end

	player:SetProperty(PROP_TAJ_CHOICE, choice);
	print('[CCB_Taj] p' .. tostring(playerID) .. ' choice=' .. tostring(choice) .. ' recorded.');
end

GameEvents.OnPlayerCommandSetObjectState.Add(OnCCBTajMahalCommand);

print('[CCB_Taj] gameplay script loaded.');

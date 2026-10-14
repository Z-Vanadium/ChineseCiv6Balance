--==============================================================================================
-- CCB：生产面板「X4 连点」开关（用户 2026-10-14 需求）—— ui/replacements/productionpanel_ccb.lua
--
-- 需求：生产面板（多队列）里点一次项目，就连续排入 4 个，方便后期铺队列。
-- 口径（用户 2026-10-14 确认）：
--   ① 固定 5 次；② **不作用于购买**；③ **不作用于奇观与区域**（它们需要放置，一次只能放一个）；
--   ④ 按钮与「滚动到 建筑/奇观/单位/项目」那 4 个小按钮同一排，激活时高亮，按钮文字就是 X4；
--   ⑤ 另外支持 **Ctrl+点击** 临时连点。
--
-- 机制依据（原版 Base\Assets\UI\Panels\ProductionPanel.lua）：
--   · 所有"加入队列"的入口最终都是同一句：
--       GetBuildInsertMode(tParameters);  CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
--     入口共 6 个：BuildUnit / BuildUnitCorps / BuildUnitArmy / BuildBuilding / ZoneDistrict / AdvanceProject。
--   · `GetBuildInsertMode` 会按当前面板状态写入 PARAM_INSERT_MODE：
--       队列或多队列面板打开 → VALUE_APPEND（追加到队尾）；否则 → VALUE_REPLACE_AT（直接切换当前生产）。
--     ★ 所以本文件**用这条参数自己判断"是否处于队列模式"**（不碰原版的私有 local），
--       只有 APPEND 时才连点 ⇒ 天然满足口径②里"仅作用于生成队列"。
--   · `CityOperationTypes` 里没有"数量"参数 ⇒ 只能重复发请求（这也正是原版的模型）。
--   · 队列上限 MAX_QUEUE_SIZE = 7（ProductionHelper.lua）；排满后原版逻辑是"替换最后一格"，连点也不会报错。
--   · 唯一性项目（例如已有的建筑）多出来的请求由引擎逐个校验并拒绝 ⇒ 表现"只进 1 个"，符合预期。
--
-- 按钮：`ui/replacements/ProductionPanel.xml`（同名覆盖原版布局）里新增控件 `CCBQueueMultiButton`，
--       本文件负责它的回调、高亮（SetSelected）与提示文字。
-- 修饰键：原版 UI 的 Mouse 事件只有 eLClick/eRClick/eLDblClick 等，**没有带修饰键的点击事件**
--       ⇒ 只能在自己的输入处理器里跟踪 `Keys.VK_CONTROL` / `Keys.VK_SHIFT` 的按下与抬起。
-- ⚠ Initialize() 在原版文件末尾就执行了，`ContextPtr:SetInputHandler` 注册的是**当时的函数对象**
--   ⇒ 覆盖 OnInputHandler 之后必须**重新注册一次**，否则永远收不到按键。
-- ⚠ 若另有 UI 模组在本 MOD 之后覆盖了 ProductionPanel.xml，控件会不存在 → 本文件已做 nil 兜底（只放弃按钮功能）。
--==============================================================================================

include "ProductionPanel";

-- ── 常量与状态 ─────────────────────────────────────────────────────────────────────────
local CCB_MULTI_TIMES :number = 4;   -- 连点次数（口径：用户 2026-10-14 由 5 调为 4）

local m_ccbMultiEnabled :boolean = false;    -- 按钮开关
local m_ccbCtrlDown  :boolean = false;    -- Ctrl（或 Shift）是否按住

local function CCB_IsMultiActive()
	return m_ccbMultiEnabled or m_ccbCtrlDown;
end

-- ── 构造 BUILD 操作参数（照抄原版入口的做法）────────────────────────────────────────────
local function CCB_BuildParameters( paramKey, hash, extraParams )
	local tParameters = {};
	tParameters[paramKey] = hash;
	if extraParams ~= nil then
		for k, v in pairs(extraParams) do
			tParameters[k] = v;
		end
	end
	-- 原版全局函数：队列模式 → APPEND；否则 → REPLACE_AT
	GetBuildInsertMode( tParameters );
	return tParameters;
end

-- ── 核心：按需发出 1 次或 5 次 BUILD 请求 ───────────────────────────────────────────────
local function CCB_RequestBuild( city, paramKey, hash, extraParams )
	local tFirst = CCB_BuildParameters( paramKey, hash, extraParams );
	CityManager.RequestOperation( city, CityOperationTypes.BUILD, tFirst );

	-- ★ 只有"追加到队列"（= 队列/多队列面板打开）时才连点；购买与"切换当前生产"都不受影响
	if CCB_IsMultiActive() and tFirst[CityOperationTypes.PARAM_INSERT_MODE] == CityOperationTypes.VALUE_APPEND then
		for i = 2, CCB_MULTI_TIMES do
			-- 每次都重新求值：队列排满时原版逻辑会转为"替换最后一格"，连点因此也不会出错
			CityManager.RequestOperation( city, CityOperationTypes.BUILD,
				CCB_BuildParameters( paramKey, hash, extraParams ) );
		end
	end
end

-- ── 保存原版入口（include 之后它们都是全局函数）──────────────────────────────────────
local fVanillaBuildUnit      = BuildUnit;
local fVanillaBuildUnitCorps = BuildUnitCorps;
local fVanillaBuildUnitArmy  = BuildUnitArmy;
local fVanillaBuildBuilding  = BuildBuilding;
local fVanillaZoneDistrict   = ZoneDistrict;
local fVanillaAdvanceProject = AdvanceProject;

-- ── 覆盖：单位 / 军团 / 军队（无需放置）──────────────────────────────────────────────
function BuildUnit( city, unitEntry )
	if not CCB_IsMultiActive() then return fVanillaBuildUnit( city, unitEntry ); end
	if CheckQueueItemSelected() then return; end
	CCB_RequestBuild( city, CityOperationTypes.PARAM_UNIT_TYPE, unitEntry.Hash );
	UI.PlaySound( "Confirm_Production" );
end

function BuildUnitCorps( city, unitEntry )
	if not CCB_IsMultiActive() then return fVanillaBuildUnitCorps( city, unitEntry ); end
	if CheckQueueItemSelected() then return; end
	CCB_RequestBuild( city, CityOperationTypes.PARAM_UNIT_TYPE, unitEntry.Hash,
		{ [CityOperationTypes.MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.CORPS_MILITARY_FORMATION } );
	UI.PlaySound( "Confirm_Production" );
end

function BuildUnitArmy( city, unitEntry )
	if not CCB_IsMultiActive() then return fVanillaBuildUnitArmy( city, unitEntry ); end
	if CheckQueueItemSelected() then return; end
	CCB_RequestBuild( city, CityOperationTypes.PARAM_UNIT_TYPE, unitEntry.Hash,
		{ [CityOperationTypes.MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.ARMY_MILITARY_FORMATION } );
	UI.PlaySound( "Confirm_Production" );
end

-- ── 覆盖：项目（无需放置）────────────────────────────────────────────────────────────
function AdvanceProject( city, projectEntry )
	if not CCB_IsMultiActive() then return fVanillaAdvanceProject( city, projectEntry ); end
	if CheckQueueItemSelected() then return; end
	CCB_RequestBuild( city, CityOperationTypes.PARAM_PROJECT_TYPE, projectEntry.Hash );
	UI.PlaySound( "Confirm_Production" );
end

-- ── 覆盖：建筑 / 区域（**需要放置的**一律交回原版，保持 1 次）──────────────────────────
function BuildBuilding( city, buildingEntry )
	if not CCB_IsMultiActive() then return fVanillaBuildBuilding( city, buildingEntry ); end

	-- 照抄原版的"是否需要放置"判断（奇观等）：需要放置 → 走原版（进入放置模式）
	local building      :table   = GameInfo.Buildings[buildingEntry.Type];
	local bNeedsPlacement:boolean = building.RequiresPlacement;
	local pBuildQueue   :table   = city:GetBuildQueue();
	if (pBuildQueue:HasBeenPlaced( buildingEntry.Hash )) then
		bNeedsPlacement = false;
	end
	if (bNeedsPlacement) then
		local cityBuildings = city:GetBuildings();
		if (cityBuildings:HasBuilding( buildingEntry.Hash )) then
			bNeedsPlacement = false;
		end
	end
	if (bNeedsPlacement) then
		return fVanillaBuildBuilding( city, buildingEntry );
	end

	if CheckQueueItemSelected() then return; end
	CCB_RequestBuild( city, CityOperationTypes.PARAM_BUILDING_TYPE, buildingEntry.Hash );
	UI.PlaySound( "Confirm_Production" );
	CloseAfterNewProduction();
end

function ZoneDistrict( city, districtEntry )
	if not CCB_IsMultiActive() then return fVanillaZoneDistrict( city, districtEntry ); end

	local district       :table   = GameInfo.Districts[districtEntry.Type];
	local bNeedsPlacement:boolean = district.RequiresPlacement;
	local pBuildQueue    :table   = city:GetBuildQueue();
	if (pBuildQueue:HasBeenPlaced( districtEntry.Hash )) then
		bNeedsPlacement = false;
	end
	if (bNeedsPlacement) then
		return fVanillaZoneDistrict( city, districtEntry );
	end

	if CheckQueueItemSelected() then return; end
	CCB_RequestBuild( city, CityOperationTypes.PARAM_DISTRICT_TYPE, districtEntry.Hash );
	UI.PlaySound( "Confirm_Production" );
	CloseAfterNewProduction();
end

-- ── 修饰键：Ctrl（或 Shift）按住 = 临时连点 ────────────────────────────────────────────
local fVanillaOnInputHandler = OnInputHandler;

function OnInputHandler( pInputStruct )
	local k = pInputStruct:GetKey();
	if k == Keys.VK_CONTROL or k == Keys.VK_SHIFT then
		local eMsg = pInputStruct:GetMessageType();
		if eMsg == KeyEvents.KeyDown then
			m_ccbCtrlDown = true;
		elseif eMsg == KeyEvents.KeyUp then
			m_ccbCtrlDown = false;
		end
	end
	return fVanillaOnInputHandler( pInputStruct );
end

-- ⚠ 必须重新注册：Initialize() 里注册的是覆盖前的旧函数对象
ContextPtr:SetInputHandler( OnInputHandler, true );

-- ── 按钮①：连点开关（X4）──────────────────────────────────────────────────────────────────────
local function CCB_RefreshMultiButton()
	if Controls.CCBQueueMultiButton == nil then return; end
	Controls.CCBQueueMultiButton:SetSelected( m_ccbMultiEnabled );
	Controls.CCBQueueMultiButton:SetToolTipString(
		Locale.Lookup( m_ccbMultiEnabled and "LOC_CCB_QUEUE_MULTI_TT_ON" or "LOC_CCB_QUEUE_MULTI_TT_OFF" ) );
end

function CCB_OnQueueMultiClicked()
	m_ccbMultiEnabled = not m_ccbMultiEnabled;
	CCB_RefreshMultiButton();
	UI.PlaySound( m_ccbMultiEnabled and "Confirm_Production" or "Main_Menu_Mouse_Over" );
end

-- ── 按钮②：清空该城市队列（2026-10-14 用户需求）────────────────────────────────────────
-- 依据：原版 `RemoveQueueItem(index)`（ProductionHelper.lua）=
--         PARAM_INSERT_MODE = VALUE_REMOVE_AT + PARAM_QUEUE_LOCATION = index 的 BUILD 操作；
--       队列索引 **1..MAX_QUEUE_SIZE 对应"排队中的项目"，0 = 正在生产的那一项**
--       （原版 RefreshQueue：GetAt(i) 的槽位号写 i+1、注释 "Start at 2"，以及 GetSize() - 1 都印证这点）。
--       ⇒ 清空 = 从 GetSize()-1 递减到 1 逐个 RemoveQueueItem（由后往前，避免索引位移）
--       ⇒ **正在生产的项目不会被取消**（那是另一个字段，本按钮不碰）。
local function CCB_GetQueuedCount()
	local pCity = UI.GetHeadSelectedCity();
	if pCity == nil then return 0; end
	local pBuildQueue = pCity:GetBuildQueue();
	if pBuildQueue == nil then return 0; end
	local nQueued = pBuildQueue:GetSize() - 1;                      -- 减掉"正在生产"那一项
	if nQueued < 0 then nQueued = 0; end
	if nQueued > MAX_QUEUE_SIZE then nQueued = MAX_QUEUE_SIZE; end  -- 防御性夹取
	return nQueued;
end

local function CCB_RefreshClearButton()
	if Controls.CCBClearQueueButton == nil then return; end
	Controls.CCBClearQueueButton:SetDisabled( CCB_GetQueuedCount() <= 0 );
end

function CCB_OnClearQueueClicked()
	local nQueued = CCB_GetQueuedCount();
	if nQueued <= 0 then
		UI.PlaySound( "Main_Menu_Mouse_Over" );
		return;
	end
	for i = nQueued, 1, -1 do
		RemoveQueueItem( i );                                       -- 原版全局函数（内部同样取 UI.GetHeadSelectedCity()）
	end
	UI.PlaySound( "Confirm_Production" );
	CCB_RefreshClearButton();
end

-- 队列一有变化（原版自身也会调 RefreshQueue 刷界面）就同步"清空"按钮的禁用态
local fVanillaRefreshQueue = RefreshQueue;
function RefreshQueue( playerID, cityID )
	fVanillaRefreshQueue( playerID, cityID );
	CCB_RefreshClearButton();
end

-- ── 控件接线（原版 Initialize() 在脚本加载时就跑完了；新控件的回调要在自己文件顶层注册）──
if Controls.CCBQueueMultiButton ~= nil then
	Controls.CCBQueueMultiButton:RegisterCallback( Mouse.eLClick, CCB_OnQueueMultiClicked );
	Controls.CCBQueueMultiButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end );
	CCB_RefreshMultiButton();
else
	-- 说明 ProductionPanel.xml 被别的 UI 模组覆盖了（本 MOD 的按钮不存在）→ 只失去按钮功能，
	-- Ctrl+点击 的临时连点仍然可用。
	print( "[CCB] ProductionPanel.xml 未生效（CCBQueueMultiButton 不存在）：X4 按钮不可用，Ctrl+点击仍可连点。" );
end

if Controls.CCBClearQueueButton ~= nil then
	Controls.CCBClearQueueButton:RegisterCallback( Mouse.eLClick, CCB_OnClearQueueClicked );
	Controls.CCBClearQueueButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end );
	CCB_RefreshClearButton();
else
	print( "[CCB] ProductionPanel.xml 未生效（CCBClearQueueButton 不存在）：清空队列按钮不可用。" );
end

--==============================================================================================
-- CCB 人工林（2026-09-19）
--   目的：把「玩家种植出来的森林」换成独立特征 FEATURE_CCB_PLANTED_FOREST，
--         使其在视觉上与原始森林区分（Clutter 排列/大小不同，见 ArtDefs/）。
--   规则层完全等同森林（本特征由 sql/Base/CCB_PlantedForest.sql 从 FEATURE_FOREST 整表复制）。
--
--   识别策略（双保险）：
--     ① 事件流：Events.FeatureAddedToMap(x, y) —— 种植完成那一刻触发（若 Gameplay 层可用）
--     ② 回合兜底：每回合开始做一次全图快照比对，"上回合无森林 → 本回合有森林"即视为新种
--        （防止事件在 Gameplay 上下文不可用导致功能整体失效）
--   首回合只建立快照、不替换，避免把地图生成阶段的自然森林误标为人工林。
--==============================================================================================

local PLANTED_FEATURE = 'FEATURE_CCB_PLANTED_FOREST';
local FOREST_FEATURE  = 'FEATURE_FOREST';
local PROP_PLANTED    = 'CCB_PLANTED_FOREST';

local plantedIndex = -1;
local forestIndex  = -1;

local function RefreshIndexes()
	local p = GameInfo.Features[PLANTED_FEATURE];
	local f = GameInfo.Features[FOREST_FEATURE];
	plantedIndex = (p ~= nil) and p.Index or -1;
	forestIndex  = (f ~= nil) and f.Index or -1;
end
RefreshIndexes();

local activated = false;   -- 第二回合起才启用替换
local snapshot  = {};      -- snapshot[plotIndex] = 上一回合的 featureType

local function ConvertPlot(plot, reason)
	if plot == nil or plantedIndex < 0 or forestIndex < 0 then return false; end
	if plot:GetFeatureType() ~= forestIndex then return false; end
	local ok = pcall(function() TerrainBuilder.SetFeatureType(plot, plantedIndex); end);
	if not ok then return false; end
	pcall(function() plot:SetProperty(PROP_PLANTED, 1); end);
	print('[CCB-Planted] (' .. tostring(plot:GetX()) .. ',' .. tostring(plot:GetY()) .. ') → 人工林 [' .. tostring(reason) .. ']');
	return true;
end;

-- ---------- ① 事件流（若可用，种下的瞬间就换） ----------
if Events ~= nil and Events.FeatureAddedToMap ~= nil then
	Events.FeatureAddedToMap.Add(function(x, y)
		if not activated then return; end
		ConvertPlot(Map.GetPlot(x, y), 'event');
	end);
	print('[CCB-Planted] FeatureAddedToMap 事件已注册');
else
	print('[CCB-Planted] 无 FeatureAddedToMap 事件，仅使用回合兜底');
end

-- ---------- ② 回合兜底：全图快照比对 ----------
local function FullScan(convertNew)
	local cur = {};
	local converted = 0;
	local count = Map.GetPlotCount();
	for i = 0, count - 1 do
		local plot = Map.GetPlotByIndex(i);
		if plot ~= nil then
			local f = plot:GetFeatureType();
			cur[i] = f;
			if convertNew and f == forestIndex and snapshot[i] ~= forestIndex then
				if ConvertPlot(plot, 'turn-sweep') then converted = converted + 1; end
			end
		end
	end
	snapshot = cur;
	return converted;
end

GameEvents.OnGameTurnStarted.Add(function(turn)
	if not activated then
		-- 首回合：只建基线快照
		activated = true;
		RefreshIndexes();
		FullScan(false);
		print('[CCB-Planted] 基线快照完成（回合 ' .. tostring(turn) .. '），后续新出现的森林将被转为人工林');
		return;
	end
	local n = FullScan(true);
	if n > 0 then
		print('[CCB-Planted] 本回合新增人工林 ' .. tostring(n) .. ' 格');
	end
end);

print('[CCB-Planted] 初始化完成（人工林索引=' .. tostring(plantedIndex) .. '，森林索引=' .. tostring(forestIndex) .. '）');

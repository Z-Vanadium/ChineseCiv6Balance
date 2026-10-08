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

-- 该地块是否曾被我们标记为人工林（属性随存档保存 → 跨读档仍有效）
local function WasPlanted(plot)
	local ok, v = pcall(function() return plot:GetProperty(PROP_PLANTED); end);
	return ok and v == 1;
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

-- ---------- ② 回合兜底：全图快照比对 + "灾后复生"回填 ----------
-- 2026-09-20 修复（用户实测：人工林着火后会变成原始树林）：
--   引擎的森林大火链是【森林 → 燃烧中森林 → 复生】，复生时写回的是**原版 FEATURE_FOREST**
--   （见 RandomEvent_Yields 里 RANDOM_EVENT_FOREST_FIRE 的 FEATURE_FOREST 行，复生目标由该行决定）。
--   原有逻辑只认"上一回合不是森林 → 本回合是森林"这一种变化：
--     · 正常时序下燃烧期间快照会记成"非森林"，复生当回合能兜住；
--     · 但若复生发生在快照之后、或中途读档，地块就会**一直停留在原始树林**。
--   现在改以 **plot 属性（随存档保存）**为准：凡是我们标记过人工林的地块，
--   只要当前特征又变回森林（无论是不是本回合刚发生），一律转回人工林。
--   属性只在 `ConvertPlot` 成功时写入，故天然森林不会被误标。
local function FullScan(convertNew)
	local cur = {};
	local converted = 0;
	local repaired = 0;
	local count = Map.GetPlotCount();
	for i = 0, count - 1 do
		local plot = Map.GetPlotByIndex(i);
		if plot ~= nil then
			local f = plot:GetFeatureType();
			cur[i] = f;
			if convertNew and f == forestIndex then
				local isNew    = (snapshot[i] ~= forestIndex);
				local regrow   = WasPlanted(plot);   -- 曾是人工林 → 火灾复生 / 时序错位
				if isNew or regrow then
					if ConvertPlot(plot, regrow and 'fire-regrow' or 'turn-sweep') then
						converted = converted + 1;
						if regrow and not isNew then repaired = repaired + 1; end
					end
				end
			elseif f == plantedIndex then
				-- 自愈：旧存档里的人工林可能没打上属性（或属性丢失）→ 补记（基线快照阶段也执行）
				if not WasPlanted(plot) then
					pcall(function() plot:SetProperty(PROP_PLANTED, 1); end);
				end
			end
		end
	end
	snapshot = cur;
	return converted, repaired;
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
	local n, repaired = FullScan(true);
	if n > 0 then
		print('[CCB-Planted] 本回合新增人工林 ' .. tostring(n) .. ' 格（其中灾后/错位回填 ' .. tostring(repaired) .. ' 格）');
	end
end);

print('[CCB-Planted] 初始化完成（人工林索引=' .. tostring(plantedIndex) .. '，森林索引=' .. tostring(forestIndex) .. '）');

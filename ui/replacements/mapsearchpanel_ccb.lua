--==============================================================================================
-- CCB：地图搜索面板（MapSearchPanel）覆盖 —— 2026-10-14
--
-- 背景：本 MOD 给军事工程师新开了队形类别 `FORMATION_CLASS_CCB_MILITARY_ENGINEER`
--   （`sql/Base/CCB_ReinforcedFort.sql` ⑥，目的是让它能与观测气球/补给车队/无人机同格）。
--   原版 `MapSearchPanel.GetPlotSearchTerms()` 里有一句
--       local pFormationClass = FormationClassNameMap[pUnitInfo.FormationClass]
--       pAdditionalTerms[pFormationClass] = true;
--   而 `FormationClassNameMap` 只登记原版 5 个类别 → 查表得到 nil → `t[nil] = true` 抛 Lua 错，
--   整个函数的搜索词全部作废 —— 表现就是：**在地图搜索框里搜该单位，结果永远是 0**。
--
-- 处理（用户 2026-10-14 实测反馈后从"pcall 兜底"升级为完整修复）：
--   ① 把该函数**逐字照抄**过来（原版 `Base\Assets\UI\Popups\MapSearchPanel.lua` L244-542），
--   ② 重建它用到的**全部**文件级 local（原版是 local，覆盖函数访问不到）：
--      `ResourceClassNameMap` / `GreatWorkTypeNameMap` / `FormationClassNameMap`，
--   ③ 在 `FormationClassNameMap` 里**登记我们的新类别**，
--   ④ 再给查表加 `or "LOC_UNIT_NAME"` 兜底，防其它模组新增类别时重演同样的 bug。
--   → 该格所有词条（地形/资源/改良/区域/建筑/单位名/单位类别…）都能正常产出。
--
-- 维护提醒：本文件是**原版函数的副本**，游戏版本升级后建议与本体对照一次；
--   只有 ① 的两处 ★ 标注是 CCB 改动，其余应保持与原版一致。
--==============================================================================================

include "MapSearchPanel";

-- ── 重建 GetPlotSearchTerms 用到的文件级 local（逐字照抄原版，仅 FormationClassNameMap 增加一项） ──

local ResourceClassNameMap = {
["RESOURCECLASS_BONUS"]     = "LOC_TOOLTIP_BONUS_RESOURCE",
["RESOURCECLASS_LUXURY"]    = "LOC_TOOLTIP_LUXURY_RESOURCE",
["RESOURCECLASS_STRATEGIC"] = "LOC_TOOLTIP_STRATEGIC_RESOURCE",
["RESOURCECLASS_ARTIFACT"]  = "LOC_TOOLTIP_ARTIFACT_RESOURCE",
};

local GreatWorkTypeNameMap = {
["GREATWORKOBJECT_SCULPTURE"] = "LOC_GREAT_WORK_OBJECT_SCULPTURE_NAME",
["GREATWORKOBJECT_PORTRAIT"]  = "LOC_GREAT_WORK_OBJECT_PORTRAIT_NAME",
["GREATWORKOBJECT_LANDSCAPE"] = "LOC_GREAT_WORK_OBJECT_LANDSCAPE_NAME",
["GREATWORKOBJECT_RELIGIOUS"] = "LOC_GREAT_WORK_OBJECT_RELIGIOUS_NAME",
["GREATWORKOBJECT_ARTIFACT"]  = "LOC_GREAT_WORK_OBJECT_ARTIFACT_NAME",
["GREATWORKOBJECT_WRITING"]   = "LOC_GREAT_WORK_OBJECT_WRITING_NAME",
["GREATWORKOBJECT_MUSIC"]     = "LOC_GREAT_WORK_OBJECT_MUSIC_NAME",
["GREATWORKOBJECT_RELIC"]     = "LOC_GREAT_WORK_OBJECT_RELIC_NAME",
};

local FormationClassNameMap = {
["FORMATION_CLASS_LAND_COMBAT"] = "LOC_FORMATION_CLASS_LAND_COMBAT_NAME",
["FORMATION_CLASS_SUPPORT"]     = "LOC_FORMATION_CLASS_SUPPORT_NAME",
["FORMATION_CLASS_CIVILIAN"]    = "LOC_FORMATION_CLASS_CIVILIAN_NAME",
["FORMATION_CLASS_NAVAL"]       = "LOC_FORMATION_CLASS_NAVAL_NAME",
["FORMATION_CLASS_AIR"]         = "LOC_FORMATION_CLASS_AIR_NAME",
-- ★ CCB 新增：军事工程师的队形类别（见 sql/Base/CCB_ReinforcedFort.sql ⑥）
["FORMATION_CLASS_CCB_MILITARY_ENGINEER"] = "LOC_FORMATION_CLASS_CCB_MILITARY_ENGINEER_NAME",
};

-- ── 以下函数逐字照抄原版 GetPlotSearchTerms（仅 ★ 两处为 CCB 改动） ──
function GetPlotSearchTerms(data)

	local bAlwaysHasAppeal = false;
	local eLocalPlayer = Game.GetLocalPlayer();
	local pLocalPlayer = Players[eLocalPlayer];

	local pSearchTerms = { };
	local AddLocalizedSearchTerm = function(kLocKey)
		if kLocKey then
			table.insert( pSearchTerms, Locale.Lookup(kLocKey) );
		else
			UI.DataError( "nil key passed in to AddLocalizedSearchTerm.");
		end
	end

	-- OWNER
	if(data.Owner ~= nil) then
		AddLocalizedSearchTerm( data.OwningCityName );
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_OWNED" );
		local pPlayerConfig = PlayerConfigurations[data.Owner];
		if (pPlayerConfig ~= nil) then
			AddLocalizedSearchTerm( pPlayerConfig:GetCivilizationShortDescription() );
			local pPlayer = Players[data.Owner];
			if(GameConfiguration:IsAnyMultiplayer() and pPlayer:IsHuman()) then
				AddLocalizedSearchTerm( pPlayerConfig:GetPlayerName() );
			end
		end
	else
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_UNCLAIMED" );
	end
	
	-- TERRAIN
	if data.IsLake then
		AddLocalizedSearchTerm( "LOC_TOOLTIP_LAKE" );
	elseif data.TerrainTypeName == "LOC_TERRAIN_COAST_NAME" then
		AddLocalizedSearchTerm( "LOC_TOOLTIP_COAST" );
	else
		AddLocalizedSearchTerm( data.TerrainTypeName );
	end
	if data.IsWater then
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_WATER" );
	end
	if data.IsMountain then
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_MOUNTAIN" );
	end
	if data.IsHill then
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_HILL" );
	end
	if data.IsRiver then
		AddLocalizedSearchTerm( "LOC_TOOLTIP_RIVER" );
	end
	if data.Impassable then
		AddLocalizedSearchTerm( "LOC_TOOLTIP_PLOT_IMPASSABLE_TEXT" );
	end

	-- FEATURES
	-- TODO add 'Second Growth' and 'Old Growth' terms
	if (data.FeatureType ~= nil) then
		local pFeature = GameInfo.Features[data.FeatureType];
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_FEATURE" );
		if pFeature.NaturalWonder then
			AddLocalizedSearchTerm( "LOC_NATURAL_WONDER_NAME" );
			bAlwaysHasAppeal = true;
		end

		AddLocalizedSearchTerm( pFeature.Name );
	end
	
	-- RESOURCES
	if(data.ResourceType ~= nil) then
		local pResource = GameInfo.Resources[data.ResourceType];

		-- If there is no local player, it can be visible
		local bResourceVisible = true;
		if pLocalPlayer ~= nil then
			local pPlayerResources = pLocalPlayer:GetResources();
			bResourceVisible = pPlayerResources:IsResourceVisible(pResource.Hash);
		end
		
		if bResourceVisible then
			AddLocalizedSearchTerm( ResourceClassNameMap[pResource.ResourceClassType] );
			AddLocalizedSearchTerm( pResource.Name );
		end
	end
	
	-- ROUTE TILE
	if (data.IsRoute and not data.Impassable) then -- Filter out Mountain Tunnels which are marked as routes
		local routeInfo = GameInfo.Routes[data.RouteType];
		if (routeInfo ~= nil and routeInfo.Name ~= nil) then
			AddLocalizedSearchTerm( "LOC_ROUTE_NAME" );
			AddLocalizedSearchTerm( routeInfo.Name );
			if data.RoutePillaged then
				AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_PILLAGED" );
			end
		end
	end

	-- APPEAL
	if (bAlwaysHasAppeal or not data.IsWater) then
		for row in GameInfo.AppealHousingChanges() do
			if (data.Appeal >= row.MinimumValue) then
				AddLocalizedSearchTerm( row.Description );
				break;
			end
		end
	end

	-- CONTINENT
	if (data.Continent ~= nil) then
		AddLocalizedSearchTerm( GameInfo.Continents[data.Continent].Description );
	end

	-- WONDER
	if (data.WonderType ~= nil) then
		AddLocalizedSearchTerm( "LOC_WONDER_NAME" );
		AddLocalizedSearchTerm( GameInfo.Buildings[data.WonderType].Name );
		if not data.WonderComplete then
			AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_UNDER_CONSTRUCTION" );
		end
	end
	
	-- IMPROVEMENT
	if (data.ImprovementType ~= nil) then
		AddLocalizedSearchTerm( "LOC_IMPROVEMENT_NAME" );
		AddLocalizedSearchTerm( GameInfo.Improvements[data.ImprovementType].Name );
		if (data.ImprovementPillaged) then
			AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_PILLAGED" );
		end
	end
	
	-- YIELDS
	for yieldType, v in pairs(data.Yields) do
		AddLocalizedSearchTerm( GameInfo.Yields[yieldType].Name );
	end
	
	-- FALLOUT
	if (data.Fallout > 0) then
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_CONTAMINATION" );
	end
	
	-- NATIONAL PARK
	if (data.NationalPark ~= nil) then
		AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_NATIONAL_PARK" );
		table.insert( pSearchTerms, data.NationalPark ); -- this is already localized
	end

	-- CITY TILE
	if (data.IsCity == true and data.DistrictType ~= nil) then
		
		AddLocalizedSearchTerm( GameInfo.Districts[data.DistrictType].Name )

	-- NON-CITY DISTRICT
	elseif (data.DistrictID ~= -1 and data.DistrictType ~= nil) then
		if (not GameInfo.Districts[data.DistrictType].InternalOnly) then --Ignore 'Wonder' districts
			-- Plot yields (ie. from Specialists)
			if (data.Yields ~= nil and table.count(data.Yields) > 0) then
				-- On a district tile, data.Yields can only come from specialists
				-- Yield search terms from specialists are handled in the YIELDS section above
				AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_SPECIALIST" );
			end

			AddLocalizedSearchTerm( "LOC_DISTRICT_NAME" );
			AddLocalizedSearchTerm( GameInfo.Districts[data.DistrictType].Name );
			if (data.DistrictPillaged) then
				AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_PILLAGED" );
			elseif (not data.DistrictComplete) then
				AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_UNDER_CONSTRUCTION" );
			end
			
			-- Inherent district yields
			for yieldType, v in pairs(data.DistrictYields) do
				AddLocalizedSearchTerm( GameInfo.Yields[yieldType].Name );
			end
		end
	end

	-- BUILDINGS + GREAT WORKS
	if (data.IsCity or data.WonderType ~= nil or data.DistrictID ~= -1) then
		if(data.BuildingNames ~= nil and table.count(data.BuildingNames) > 0) then

			local cityBuildings = data.OwnerCity:GetBuildings();
			if (data.WonderType == nil) then
				AddLocalizedSearchTerm( "LOC_BUILDING_NAME" );
			end

			local kGreatWorkTable = { };
			for i,szBuildingName in ipairs(data.BuildingNames) do 
			    if (data.WonderType == nil) then
					AddLocalizedSearchTerm( szBuildingName );
					if (data.BuildingsPillaged[i]) then
						AddLocalizedSearchTerm( "LOC_HUD_MAP_SEARCH_TERMS_PILLAGED" );
					end
				end

				local iSlots = cityBuildings:GetNumGreatWorkSlots(data.BuildingTypes[i]);
				for j = 0, iSlots - 1, 1 do
					local greatWorkIndex:number = cityBuildings:GetGreatWorkInSlot(data.BuildingTypes[i], j);
					if (greatWorkIndex ~= -1) then
						local greatWorkType:number = cityBuildings:GetGreatWorkTypeFromIndex(greatWorkIndex)
						local pGreatWork = GameInfo.GreatWorks[greatWorkType];
						
						if (kGreatWorkTable[pGreatWork.GreatWorkObjectType] == nil) then
							kGreatWorkTable[pGreatWork.GreatWorkObjectType] = { pGreatWork.Name };
						else
							table.insert(kGreatWorkTable[pGreatWork.GreatWorkObjectType], pGreatWork.Name);
						end
					end
				end
			end

			if table.count(kGreatWorkTable) > 0 then
				AddLocalizedSearchTerm( "LOC_GREAT_WORKS" );
				for kGreatWorkType,kGreatWorkList in pairs(kGreatWorkTable) do
					AddLocalizedSearchTerm( GreatWorkTypeNameMap[kGreatWorkType] );
					for _,szWorkName in pairs(kGreatWorkList) do
						AddLocalizedSearchTerm( szWorkName );
					end
				end
			end
		end
	end
	
	-- UNITS
	local pPlayerVis = PlayersVisibility[eLocalPlayer];
	if pPlayerVis ~= nil and pPlayerVis:IsVisible(data.X, data.Y) then
		local pUnitList:table = Units.GetUnitsInPlotLayerID( data.X, data.Y, MapLayers.ANY );
		if pUnitList ~= nil then
			-- A set of additional terms to add
			local pAdditionalTerms = { };

			for _,pUnit in pairs(pUnitList) do
				if pPlayerVis:IsUnitVisible(pUnit) and not pUnit:IsDelayedDeath() then
					local pUnitInfo:table = GameInfo.Units[pUnit:GetUnitType()];

					-- Add the unit name, and the unit type name if the unit has a custom name
					local pUnitName = pUnit:GetName();
					local pTypeName = pUnitInfo.Name;
					AddLocalizedSearchTerm(pUnitName);
					if pUnitName ~= pTypeName then
						AddLocalizedSearchTerm(pTypeName);
					end
					
					-- Add the unit owner's name
					local eUnitOwner = pUnit:GetOwner();
					local pPlayerConfig = PlayerConfigurations[eUnitOwner];
					if (pPlayerConfig ~= nil) then
						local pOwnerName = pPlayerConfig:GetCivilizationShortDescription();
						pAdditionalTerms[pOwnerName] = true;
						local pPlayer = Players[eUnitOwner];
						if(GameConfiguration:IsAnyMultiplayer() and pPlayer:IsHuman()) then
							local pPlayerName = pPlayerConfig:GetCivilizationShortDescription();
							pAdditionalTerms[pPlayerName] = true;
						end
					end

					-- Add the unit formations
					local eFormation = pUnit:GetMilitaryFormation();
					if pUnitInfo.Domain == "DOMAIN_SEA" then
						if (eFormation == MilitaryFormationTypes.CORPS_FORMATION) then
							pAdditionalTerms["LOC_UNITFLAG_FLEET_SUFFIX"] = true;
						elseif (eFormation == MilitaryFormationTypes.ARMY_FORMATION) then
							pAdditionalTerms["LOC_UNITFLAG_ARMADA_SUFFIX"] = true;
						end	
					else
						if (eFormation == MilitaryFormationTypes.CORPS_FORMATION) then
							pAdditionalTerms["LOC_UNITFLAG_CORPS_SUFFIX"] = true;
						elseif (eFormation == MilitaryFormationTypes.ARMY_FORMATION) then
							pAdditionalTerms["LOC_UNITFLAG_ARMY_SUFFIX"] = true;
						end
					end

					-- TODO more precise unit classes, e.g. heavy cavalry and anti air
					if pUnitInfo.Combat and pUnitInfo.Combat > 0 then
						pAdditionalTerms["LOC_PROMOTION_CLASS_MELEE_NAME"] = true;
					end
					if pUnitInfo.RangedCombat and pUnitInfo.RangedCombat > 0 then
						pAdditionalTerms["LOC_PROMOTION_CLASS_RANGED_NAME"] = true;
					end
					if pUnitInfo.BombardCombat and pUnitInfo.BombardCombat > 0 then
						pAdditionalTerms["LOC_PROMOTION_CLASS_SIEGE_NAME"] = true;
					end

					-- Add additional terms to the set (only once)
					-- ★ CCB：原版这里查不到队形类别时会得到 nil，紧接着 pAdditionalTerms[nil] = true
					--   会抛 Lua 错（table index is nil），整格的搜索词都会丢弃（搜单位名返回 0）。
					--   本 MOD 已把新类别登记进上面的 FormationClassNameMap，这里再兜一层，
					--   保证以后别的模组新增类别时也只是少一个类别名，不会把整格词条弄丢。
					local pFormationClass = FormationClassNameMap[pUnitInfo.FormationClass] or "LOC_UNIT_NAME";
					pAdditionalTerms[pFormationClass] = true;
					pAdditionalTerms["LOC_UNIT_NAME"] = true;
				end
			end

			for pTerm,_ in pairs(pAdditionalTerms) do
				AddLocalizedSearchTerm(pTerm);
			end
		end
	end
	
	-- maybe more?

	return pSearchTerms;
end

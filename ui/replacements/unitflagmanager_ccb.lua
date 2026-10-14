--==============================================================================================
-- CCB：单位旗帜管理（UnitFlagManager）覆盖
--   2026-10-14 建立（旗帜样式兜底）；2026-10-15 补「次数徽标」+「多单位错位」
--
-- 【为什么需要】原版 UnitFlagManager.lua 有两处对 FormationClass 的**硬编码 5 类**判断：
--   ① CreateUnitFlag()          —— 决定旗帜**样式**（LAND_COMBAT/AIR→军事旗；NAVAL→海军旗；
--                                  SUPPORT→支援旗；CIVILIAN→平民旗），**没有 else** →
--                                  任何未列出的类别**完全不创建旗帜**，单位在地图上等于没有图标、难以点选。
--   ② UpdateIconStack()         —— 多单位同格时的**旗帜错位**：未知类别落到 else → 偏移 (0,0)
--                                  = 格子正中，会被城市横幅 / 其它单位的旗帜压住 → 看起来像「旗标不见了」。
--   本 MOD 给军事工程师新开了队形类别 FORMATION_CLASS_CCB_MILITARY_ENGINEER
--   （sql/Base/CCB_ReinforcedFort.sql ⑥，目的是让它能与观测气球/补给车队/无人机同格）→ 两处都必须兜底。
--   （原版第 3 处硬编码在 ProductionPanel.lua PopulateUnits 的建造列表旗帜贴图，仅影响列表里的小旗样式。）
--
-- 【次数徽标】原版**不显示**建造次数（工人/工兵旗上看不到「还剩几次」，全库只有 MPT 的 BCT 模块用
--   UnitFlag.UpdatePromotions + Events.UnitChargesChanged 实现）。而 MPT 的 BCT 与本文件覆盖**同一个
--   LuaContext（UnitFlagManager）→ 只能有一个生效**（CCB LoadOrder 19999 > MPT 4000，CCB 胜）
--   → 装了 MPT 反而会丢掉 BCT 的次数显示。所以这里**自己实现一份**：不依赖 MPT，也不怕谁顶掉谁。
--
-- 【写法】include 原版文件拿到全部代码与事件注册，然后**只覆盖需要改的函数**
--   （这些都是全局函数；其它函数/事件回调在调用时才查全局名 → 覆盖有效）。
--   与工程内既有 ui/replacements/unitpanel_bbg.lua（include "UnitPanel_Expansion2" 后覆盖函数）同构。
-- ⚠ 覆盖函数里不能用原版的**文件级 local**（m_UnitFlagInstances / m_*InstanceManager），
--   所以「是否已有旗帜」改用原版提供的全局函数 GetUnitFlag()。
--   （m_FlagOffsets / m_LinkOffsets 原版就没写 local → 是全局表，可以直接用。）
-- ⚠ 覆盖 Subscribe/Unsubscribe **有效**：原版 Initialize() 只把 OnInit 注册给 ContextPtr，
--   而 OnInit 内部是**按名字**调用 Subscribe() 的 → 运行时取到我们这份。
--   **绝不能**在这里再调一次 Initialize()（会二次注册；原版是在自己文件末尾调的）。
--==============================================================================================

include "UnitFlagManager";

--==============================================================================================
-- ① 旗帜**样式**：新队形类别按「支援」画旗 + 补 else 兜底（原版这里没有 else → 会完全没有旗帜）
--==============================================================================================
function CreateUnitFlag( playerID: number, unitID : number, unitX : number, unitY : number )
	-- 已经有旗帜就直接返回（原版用文件级 local 表判断，这里改用全局函数）
	if (GetUnitFlag( playerID, unitID ) ~= nil) then
		return;
	end

	local pPlayer	:table = Players[playerID];
	local pUnit		:table = pPlayer:GetUnits():FindID(unitID);
	if pUnit ~= nil and pUnit:GetUnitType() ~= -1 then
		local formationClassType = GameInfo.Units[pUnit:GetUnitType()].FormationClass;
		if		(formationClassType == "FORMATION_CLASS_LAND_COMBAT" or formationClassType == "FORMATION_CLASS_AIR") then
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_MILITARY );
		elseif	(formationClassType == "FORMATION_CLASS_NAVAL") then
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_NAVAL );
		elseif	(formationClassType == "FORMATION_CLASS_CCB_MILITARY_ENGINEER" or formationClassType == "FORMATION_CLASS_SUPPORT") then
			-- ★ CCB 新增：军事工程师的队形类别按"支援"样式显示（它本来就是支援单位，只是堆叠格位不同）
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_SUPPORT );
		elseif	(formationClassType == "FORMATION_CLASS_CIVILIAN") then
			if	(GameInfo.Units[pUnit:GetUnitType()].MakeTradeRoute) then
				UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_TRADE );
			elseif (pUnit:GetReligiousStrength() > 0) then
				UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_RELIGION );
			else
				UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_CIVILIAN );
			end
		else
			-- ★ CCB 兜底：未知队形类别也给一面支援旗（原版这里没有 else → 会完全没有旗帜）
			UnitFlag:new( playerID, unitID, FLAGTYPE_UNIT, FLAGSTYLE_SUPPORT );
		end
	end
end

--==============================================================================================
-- ② 多单位同格时的**旗帜错位**：把新队形类别并入 CIVILIAN/SUPPORT 分支
--    整段**逐字取自原版** UnitFlagManager.lua L1250-1401，只有 ★★ 标记的 4 处是 CCB 改动
--    （1.7 时代工兵的类别还是 FORMATION_CLASS_SUPPORT，走的就是这条分支 → 本次等于恢复旧表现）
--==============================================================================================
function UpdateIconStack( plotX:number, plotY:number )
	local unitList:table = Units.GetUnitsInPlotLayerID( plotX, plotY, MapLayers.ANY );
	if unitList ~= nil then
		-- If a unit is going to die it shouldn't be counted 
		
		local numUnits:number = table.count(unitList);
		for i, pUnit in ipairs(unitList) do
			if pUnit:IsDelayedDeath() then
				numUnits = numUnits - 1; 
			elseif ShouldHideFlag(pUnit) then
				-- Don't count unit flags which will be hidden
				numUnits = numUnits - 1; 
			end
		end
		local multiSpacingX		:number = 32;
		local landCombatOffsetX	:number = 0;
		local civilianOffsetX	:number = 0;
		local formationIndex	:number = 0;
		local bHideLink			:boolean= false;
		local DuoFlag			:table;

		for _, pUnit in ipairs(unitList) do
			-- Cache commonly used values (optimization)
			local unitID:number = pUnit:GetID();
			local unitOwner:number = pUnit:GetOwner();
			local flag = GetUnitFlag( unitOwner, unitID );
			
			if ( flag ~= nil and flag.m_eVisibility == RevealedState.VISIBLE ) then
				local unitInfo:table = GameInfo.Units[pUnit:GetUnitType()];

				-- Check if we should hide this units flag
				flag.m_Instance.FlagRoot:SetHide(ShouldHideFlag(pUnit));

				-- If there's more than one unit in the hex, offset their flags so they don't overlap
				local formationClassString:string = unitInfo.FormationClass;
				local iFormationCount:number = pUnit:GetFormationUnitCount();
				if(iFormationCount > 1 or numUnits > 1) then
					if ( iFormationCount < 2 ) then					
						if (formationClassString == "FORMATION_CLASS_LAND_COMBAT") then
							flag.m_Instance.FlagRoot:SetOffsetVal(landCombatOffsetX + m_FlagOffsets[1][1], m_FlagOffsets[1][2] );
							landCombatOffsetX = landCombatOffsetX - multiSpacingX;
						-- ★★ CCB：新队形类别并入 CIVILIAN/SUPPORT 分支（它的堆叠格位与支援类不冲突，显示上就该按支援排位）
						elseif	(formationClassString == "FORMATION_CLASS_CIVILIAN" or formationClassString == "FORMATION_CLASS_SUPPORT" or formationClassString == "FORMATION_CLASS_CCB_MILITARY_ENGINEER") then
							flag.m_Instance.FlagRoot:SetOffsetVal(civilianOffsetX + m_FlagOffsets[2][1], m_FlagOffsets[2][2]);
							civilianOffsetX = civilianOffsetX + multiSpacingX;
						elseif	(formationClassString == "FORMATION_CLASS_NAVAL") then
							flag.m_Instance.FlagRoot:SetOffsetVal(m_FlagOffsets[3][1], m_FlagOffsets[3][2]);
						elseif	(formationClassString == "FORMATION_CLASS_AIR") then
							flag.m_Instance.FlagRoot:SetOffsetVal(m_FlagOffsets[3][1], m_FlagOffsets[3][2] * -1 );
						else -- ★★ CCB：未知队形类别也按「支援」排位（与 CreateUnitFlag 的 else 兜底口径一致）。
							--    原版这里是 (0,0) = 格子正中，多单位同格时会被城市横幅/其它旗帜整个压住
							flag.m_Instance.FlagRoot:SetOffsetVal(civilianOffsetX + m_FlagOffsets[2][1], m_FlagOffsets[2][2]);
							civilianOffsetX = civilianOffsetX + multiSpacingX;
						end

						flag.m_Instance.Formation2:SetHide(true);
						flag.m_Instance.Formation3:SetHide(true);
					else 
						if(formationClassString == "FORMATION_CLASS_CIVILIAN" or formationClassString == "FORMATION_CLASS_SUPPORT" or formationClassString == "FORMATION_CLASS_CCB_MILITARY_ENGINEER") then
							civilianOffsetX = civilianOffsetX + multiSpacingX;
						end
						if (iFormationCount < 3) then
							flag.m_Instance.Formation2:SetHide(true);
							flag.m_Instance.Formation3:SetHide(true);
							if formationClassString ~= "FORMATION_CLASS_LAND_COMBAT" then
								-- Only show formation links on the last flag
								if DuoFlag then
									DuoFlag.m_Instance.Formation2:SetHide(true);

									-- If the flags share the same parent, ensure the flag with the formation control renders below the DuoFlag
									local flagParent = flag.m_Instance.Anchor:GetParent();
									if flagParent == DuoFlag.m_Instance.Anchor:GetParent() then
										flagParent:AddChildAtIndex(flag.m_Instance.Anchor, 0);
									end
								end
								DuoFlag = flag;
								--Check if any unit in the formation has a hidden flag.
								for i, pUnit in ipairs(unitList) do
									local unitID	:number = pUnit:GetID();
									local unitOwner	:number = pUnit:GetOwner();
									local flag		:table  = GetUnitFlag( unitOwner, unitID );
									if flag ~= nil and flag.m_eVisibility == RevealedState.HIDDEN then
										bHideLink = true;
									end
								end
								--Hide the formation link if not local player and cloaking is active.
								flag.m_Instance.Formation2:SetHide(bHideLink and unitOwner ~= Game.GetLocalPlayer());
								flag.m_Instance.Formation2:SetOffsetVal(m_LinkOffsets[1][1], m_LinkOffsets[1][2]);
								flag.m_Instance.Formation2:SetSizeX(64);
							end	
							
						else
							flag.m_Instance.Formation2:SetHide(true);
							flag.m_Instance.Formation3:SetHide(true);
							if formationClassString == "FORMATION_CLASS_CIVILIAN" or formationClassString == "FORMATION_CLASS_SUPPORT" or formationClassString == "FORMATION_CLASS_CCB_MILITARY_ENGINEER" then
								-- Ensure the flag with Formation3 set to visible renders below the other flags
								local flagParent = flag.m_Instance.Anchor:GetParent();
								flagParent:AddChildAtIndex(flag.m_Instance.Anchor, 0);
								--Check if any unit in the formation has a hidden flag.
								for i, pUnit in ipairs(unitList) do
									local unitID	:number = pUnit:GetID();
									local unitOwner	:number = pUnit:GetOwner();
									local flag		:table  = GetUnitFlag( unitOwner, unitID );
									if flag ~= nil and flag.m_eVisibility == RevealedState.HIDDEN then
										bHideLink = true;
									end
								end
								--Hide the formation link if not local player and a unit in the formation has a hidden flag.
								flag.m_Instance.Formation3:SetHide(bHideLink and unitOwner ~= Game.GetLocalPlayer());
								flag.m_Instance.Formation3:SetOffsetVal(m_LinkOffsets[2][1], m_LinkOffsets[2][2]);
								flag.m_Instance.Formation3:SetSizeX(100);
								flag.m_Instance.Formation3:SetSizeY(80);
							end	
							
						end
						
						formationIndex = formationIndex + 1;
						flag.m_Instance.FlagRoot:SetOffsetVal(m_FlagOffsets[formationIndex][1], m_FlagOffsets[formationIndex][2] );
						--No offset if a unit in the formation has a hidden flag
						if (bHideLink and unitOwner ~= Game.GetLocalPlayer()) then 
							flag.m_Instance.FlagRoot:SetOffsetX(0);
							flag.m_Instance.FlagRoot:SetOffsetY(0);
						end
					end
				
				else
					-- If there is not more than one unit remove the offset and hide the formation indicator
					flag.m_Instance.FlagRoot:SetOffsetX(0);
					flag.m_Instance.FlagRoot:SetOffsetY(0);		
					flag.m_Instance.Formation2:SetHide(true);
					flag.m_Instance.Formation3:SetHide(true);
				end

				-- Avoid name changing (per frame) as there are lots of small string allocations that will occur.
				-- The only time the name would change is if the military formation has changed.
				local militaryFormation:number = pUnit:GetMilitaryFormation();
				if flag.m_cacheMilitaryFormation ~= militaryFormation then
					if militaryFormation == MilitaryFormationTypes.CORPS_FORMATION then
						flag.m_Instance.CorpsMarker:SetHide(false);
						flag.m_Instance.ArmyMarker:SetHide(true);
					elseif militaryFormation == MilitaryFormationTypes.ARMY_FORMATION then
						flag.m_Instance.CorpsMarker:SetHide(true);
						flag.m_Instance.ArmyMarker:SetHide(false);
					else
						flag.m_Instance.CorpsMarker:SetHide(true);
						flag.m_Instance.ArmyMarker:SetHide(true);
					end
					flag.m_cacheMilitaryFormation = militaryFormation;
					flag:UpdateName();
				end

			end
		end
	end
end


--==============================================================================================
-- ③ 建造次数徽标（= MPT/BCT「建造者次数」的功能，自带一份，不依赖 MPT）
--    实现要点：
--      · 只在徽标槽**没有晋升数字可显示**时抢用它（工人/工兵本来就不会有晋升；罗马军团、毛利托阿
--        这类「有次数但也有晋升」的单位仍按原版显示晋升数，不被本改动影响）
--      · 被征召的单位优先显示征召剩余回合（与原版一致，交给原版处理）
--      · 次数归零时**隐藏**徽标（MPT 版是 >0 才写、0 时直接 return，会留下上一次的数字）
--      · Events.UnitChargesChanged 负责「用掉一次」后立刻刷新
--==============================================================================================
local BASE_UpdatePromotions = UnitFlag.UpdatePromotions;
local BASE_Subscribe = Subscribe;
local BASE_Unsubscribe = Unsubscribe;

function CCB_OnUnitChargesChanged( playerID: number, unitID : number )
	local flagInstance = GetUnitFlag( playerID, unitID );
	if (flagInstance ~= nil) then
		flagInstance:UpdatePromotions();
	end
end

function UnitFlag.UpdatePromotions( self )
	local pUnit : table = self:GetUnit();
	if (pUnit ~= nil) then
		local kUnitInfo : table = GameInfo.Units[ pUnit:GetUnitType() ];
		-- ★ CCB：有建造次数（工人 3 / 工兵 / 军团 / 托阿 / 葡萄牙卡拉维尔 …）且未被征召
		if (kUnitInfo ~= nil and kUnitInfo.BuildCharges ~= nil and kUnitInfo.BuildCharges > 0
				and GetLevyTurnsRemaining( pUnit ) < 0) then
			local unitExperience : table = pUnit:GetExperience();
			local tPromotions : table = nil;
			if (unitExperience ~= nil) then
				tPromotions = unitExperience:GetPromotions();
			end
			if (tPromotions == nil or #tPromotions == 0) then
				local iCharges : number = pUnit:GetBuildCharges();
				if (iCharges ~= nil and iCharges > 0) then
					self.m_Instance.UnitNumPromotions:SetText( iCharges );
					self.m_Instance.Promotion_Flag:SetHide( false );
				else
					self.m_Instance.Promotion_Flag:SetHide( true );
				end
				return;
			end
		end
	end
	BASE_UpdatePromotions( self );
end

function Subscribe()
	BASE_Subscribe();
	if (Events.UnitChargesChanged ~= nil) then
		Events.UnitChargesChanged.Add( CCB_OnUnitChargesChanged );
	end
end

function Unsubscribe()
	BASE_Unsubscribe();
	if (Events.UnitChargesChanged ~= nil) then
		Events.UnitChargesChanged.Remove( CCB_OnUnitChargesChanged );
	end
end

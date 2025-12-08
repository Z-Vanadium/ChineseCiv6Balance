--地形地貌改良资源单位建筑区域缓存表
TerrainTypeMap = {}
FeatureTypeMap = {}
ImprovementTypeMap = {}
ResourceTypeMap = {}
UnitTypeMap = {}
BuildingTypeMap = {}
DistrictTypeMap = {}
TypeTagsMap = {}

--============================================================================================================================
--小工具部分
--==============================================
--广度优先搜索：获取从 (iX, iY) 出发，距离不超过 maxRing 的所有单元格（排除中心单元格）
    function RuivoGetRingPlotIndexes(iX, iY, maxRing)
        local resultPlotIndex = {}   -- 存储最终结果的格子索引列表
        local visited = {}           -- 标记已经访问过的格子，防止重复访问
        local queue = {}             -- 用于广度优先搜索的队列（FIFO）

        local centerPlot = Map.GetPlot(iX, iY)  -- 获取中心格对象
        if not centerPlot then return resultPlotIndex end  -- 如果中心格无效，返回空结果

        local centerIndex = centerPlot:GetIndex()  -- 获取中心格的索引
        visited[centerIndex] = true                -- 标记中心格为已访问
        --table.insert(resultPlotIndex, centerIndex) -- 加入结果列表
        table.insert(queue, centerIndex)           -- 加入队列，开始BFS搜索

        -- 广度优先搜索，逐层扩展格子
        while #queue > 0 do
            local currentIndex = table.remove(queue, 1)        -- 取出当前处理的格子索引
            local plot = Map.GetPlotByIndex(currentIndex)      -- 获取对应格子对象
            local dist = Map.GetPlotDistance(iX, iY, plot:GetX(), plot:GetY()) -- 计算该格子与中心格的距离

            -- 如果该格子在 maxRing 范围内，继续扩展它的相邻格子
            if dist < maxRing then
                local adjPlots = Map.GetAdjacentPlots(plot:GetX(), plot:GetY()) -- 获取相邻格子
                for _, adj in ipairs(adjPlots) do
                    if adj then
                        local adjIndex = adj:GetIndex()  -- 获取相邻格子的索引
                        if not visited[adjIndex] then   -- 如果未访问过
                            visited[adjIndex] = true    -- 标记为已访问
                            table.insert(resultPlotIndex, adjIndex) -- 加入结果列表
                            table.insert(queue, adjIndex)           -- 加入队列以便后续扩展
                        end
                    end
                end
            end
        end

        return resultPlotIndex  -- 返回所有在 maxRing 范围内的格子索引
    end
--==============================================
--是否有领袖特质
    function HasLeaderTrait(LeaderType, traitType)
        for row in GameInfo.LeaderTraits() do
            if (row.LeaderType == LeaderType and row.TraitType == traitType) then return 
                true end
        end
        return false
    end
--是否有文明特质
    function HasCivilizationTrait(CivilizationType, traitType)
        for row in GameInfo.CivilizationTraits() do
            if (row.CivilizationType == CivilizationType and row.TraitType == traitType) then return 
                true end
        end
        return false
    end
--==============================================
--城市是否有建筑
    function Ruivo_CityHasBuilding(WhoIsTheOwner, pCity)
        --首先要看在不在数据库里
        if GameInfo.Buildings[WhoIsTheOwner] then
            local iIndex = GameInfo.Buildings[WhoIsTheOwner].Index
            --是否有建筑
            if pCity:GetBuildings():HasBuilding(iIndex) then
                return true
            end
        end
        --否则返回否
        return false
    end

--玩家是否有政策
    function Ruivo_PlayerHasPolicy(WhoIsTheOwner, pPlayer)
        --首先要看在不在数据库里
        if GameInfo.Policies[WhoIsTheOwner] then
            local iIndex = GameInfo.Policies[WhoIsTheOwner].Index
            local PlayerCulture = pPlayer:GetCulture()
            --是否有政策
            if PlayerCulture:IsPolicyActive(iIndex) then
                return true
            end
        end
        --否则返回否
        return false
    end

--玩家是否有科技
    function Ruivo_PlayerHasTech(WhoIsTheOwner, pPlayer)
        --首先要看在不在数据库里
        if GameInfo.Technologies[WhoIsTheOwner] then
            local iIndex = GameInfo.Technologies[WhoIsTheOwner].Index

            local PlayerTechs = pPlayer:GetTechs()

            --是否有科技
            if PlayerTechs:HasTech(iIndex) then
                return true
            end

        end
        return false
    end

--玩家是否有市政
    function Ruivo_PlayerHasCivic(WhoIsTheOwner, pPlayer)
        --首先要看在不在数据库里
        if GameInfo.Civics[WhoIsTheOwner] then
            local iIndex = GameInfo.Civics[WhoIsTheOwner].Index

            local PlayerCulture = pPlayer:GetCulture()

            --是否有市政
            if PlayerCulture:HasCivic(iIndex) then
                return true
            end
        end
        --否则返回否
        return false
    end

--==============
--玩家是否为某个政体（由于GetCurrentGovernment只能在UI下使用，所以使用pcall法，GP默认true）
    function Ruivo_PlayerIsGovernment(WhoIsTheOwner, pPlayer)
        --pcall法处理异常
        local success, result = pcall(function()
            --首先要看在不在数据库里
            if GameInfo.Governments[WhoIsTheOwner] then
                local iIndex = GameInfo.Governments[WhoIsTheOwner].Index
                local PlayerCulture = pPlayer:GetCulture()

                --是否为政体
                if PlayerCulture:GetCurrentGovernment() == iIndex then
                    return true
                end
            end
            return false
        end)

        if success then
            return result --成功执行，说明在UI环境
        else
            return true --出错了（捕获异常），默认在GP环境为true
        end
    end
--==============
--城市是否有万神殿/信条
    function Ruivo_CityHasBelief(WhoIsTheOwner, pCity)
        --首先要看在不在数据库里
        if not GameInfo.Beliefs[WhoIsTheOwner] then
            return false
        end

        --获取数据
        local beliefData = GameInfo.Beliefs[WhoIsTheOwner]
        local pCityReligion = pCity:GetReligion()

        -- 万神殿判断
        if beliefData.BeliefClassType == "BELIEF_CLASS_PANTHEON" then
            local activePantheon = pCityReligion:GetActivePantheon()
            if activePantheon == beliefData.Index then
                return true
            end
            return false
        end

        -- 信条判断（通过主流宗教的信条列表）
        local pGameReligion = Game.GetReligion()
        local pAllReligions = pGameReligion:GetReligions()
        local eDominantReligion = pCityReligion:GetMajorityReligion()
        --遍历所有宗教
        for _, kFoundReligion in ipairs(pAllReligions) do
            --找到主流宗教
            if kFoundReligion.Religion == eDominantReligion then
                --遍历信条
                for _, beliefIndex in ipairs(kFoundReligion.Beliefs) do
                    if beliefIndex == beliefData.Index then
                        return true
                    end
                end
                break
            end
        end

        return false
    end
--==============
--UI下的总督晋升判断函数（从原版抄的）
    function only_UI_PlayerHasGovernorPromotion(playerID:number, GovernorPromotionType:string)
        --玩家
        local pPlayer = Players[playerID]
        if not pPlayer then
            return false
        end

        --总督
        local playerGovernors = pPlayer:GetGovernors()
        if not playerGovernors then
            return false
        end

        --总督列表
        local bHasGovernors, tGovernorList = playerGovernors:GetGovernorList()
        if not bHasGovernors or not tGovernorList then
            return false
        end

        --哈希化
        local promotionHash = DB.MakeHash(GovernorPromotionType)

        --看看有没有总督晋升
        for _, pGovernor in ipairs(tGovernorList) do
            if pGovernor and pGovernor:HasPromotion(promotionHash) then
                return true
            end
        end

        return false
    end
--玩家是否有总督晋升，GP和UI混用下pcall，GP默认是true
    function Ruivo_PlayerHasGovernorPromotion(playerID:number, GovernorPromotionType:string)
        local success, result = pcall(function()
            return only_UI_PlayerHasGovernorPromotion(playerID, GovernorPromotionType)
        end)

        if success then
            return result --成功执行，说明在UI环境
        else
            return true --出错了（捕获异常），默认在GP环境为true
        end
    end
--==============================================
--判断函数（建筑、政策卡、市政、科技、政体、总督升级、信仰）
    function IsModifierOwnerValid(ModifierOwner, WhoIsTheOwner, CollectionType, playerID, pCity)
        --发起者为区域
        if ModifierOwner == 'DistrictModifiers' then
            return true
        end

        --获取玩家对象
        local pPlayer = Players[playerID]

        --发起者为建筑
        if ModifierOwner == 'BuildingModifiers' then
            return Ruivo_CityHasBuilding(WhoIsTheOwner, pCity)
        end

        --发起者为政策
        if ModifierOwner == 'PolicyModifiers' then
            return Ruivo_PlayerHasPolicy(WhoIsTheOwner, pPlayer)
        end

        --发起者为科技
        if ModifierOwner == 'TechnologyModifiers' then
            return Ruivo_PlayerHasTech(WhoIsTheOwner, pPlayer)
        end

        --发起者为市政
        if ModifierOwner == 'CivicModifiers' then
            return Ruivo_PlayerHasCivic(WhoIsTheOwner, pPlayer)
        end

        --发起者为政体
        if ModifierOwner == 'GovernmentModifiers' then
            return Ruivo_PlayerIsGovernment(WhoIsTheOwner, pPlayer)
        end

        --发起者为万神殿/信条
        if ModifierOwner == 'BeliefModifiers' then
            return Ruivo_CityHasBelief(WhoIsTheOwner, pCity)
        end

        --发起者为总督升级
        if ModifierOwner == 'GovernorPromotionModifiers' then
            return Ruivo_PlayerHasGovernorPromotion(playerID, WhoIsTheOwner)
        end

        --默认false
        return false
    end
--判断是否可以显示某模块
    function CanDisplayModule(row, CivilizationType, LeaderType, playerID, pCity)
        local pPlayer = Players[playerID]

        -- 判断是否限定为仅人类或仅AI
        if row.Only == 'OnlyHuman' then 
            if not pPlayer:IsHuman() then
                return false
            end
        elseif row.Only == 'OnlyAI' then
            if pPlayer:IsHuman() then
                return false
            end
        end

        local validTrait = true
        local CanDisplay = false

        -- 判断是否具备指定文明或领袖特质
        if row.TraitType then
            validTrait = HasCivilizationTrait(CivilizationType, row.TraitType) 
                    or HasLeaderTrait(LeaderType, row.TraitType)
        end

        -- 若有区域修饰符或通过特质判断通过，进一步判断修饰符所有者是否合法
        if (row.DistrictModifiers or validTrait) then
            CanDisplay = IsModifierOwnerValid(row.ModifierOwner, row.WhoIsTheOwner, row.CollectionType, playerID, pCity)
        end

        return CanDisplay
    end
--==============================================
--二进制折叠列表缓存
Ruivo_BinaryList = {}
    maxNum = 0
    --从Ruivo_BinaryList表里取二进制数
    local i = 0
    while true do
        local row = GameInfo.Ruivo_BinaryList[i]
        if not row then break end
        table.insert(Ruivo_BinaryList, row.Num)
        i = i + 1
    end

    -- 输出为 {1, 2, 4, 8, 16, 32, 64, 128, 256, 512}
    local listStr = "{"
    for i, v in ipairs(Ruivo_BinaryList) do
        listStr = listStr .. v
        maxNum = maxNum + v
        if i < #Ruivo_BinaryList then
            listStr = listStr .. ", "
        end
    end
    listStr = listStr .. "}"

    --print("Ruivo_BinaryList =", listStr)
    --print("最大可表示数值 =", maxNum)
--==============================================
--UI环境的小工具部分
--根据产出获得图标
    function RUIVO_GetYieldTextIcon( yieldType:string )
        local  iconString:string = "";
        if		GameInfo.Ruivo_Yield_IconString[yieldType]	then iconString = GameInfo.Ruivo_Yield_IconString[yieldType].IconString
        elseif  yieldType == "YIELD_TOURISM"                then iconString = "[ICON_Tourism]"
        elseif  yieldType == "YIELD_INFLUENCE"              then iconString = "[ICON_Envoy]"
        elseif  yieldType == "YIELD_FAVOR"                  then iconString = "[ICON_Favor]"
        elseif  yieldType == "YIELD_POWER"                  then iconString = "[ICON_Power]"
        elseif  yieldType == "YIELD_AMENITY"                then iconString = "[ICON_Amenities]"
        elseif  yieldType == "YIELD_HOUSING"                then iconString = "[ICON_Housing]"
        elseif  yieldType == "YIELD_LOYALTY"                then iconString = "[ICON_PressureUp]"
        elseif  yieldType == "YIELD_TRADE_ROUTE"            then iconString = "[ICON_TradeRoute]"
        elseif  yieldType == "YIELD_DISTRICT_SLOT"          then iconString = "[ICON_DISTRICT]"
        elseif	GameInfo.Yields[yieldType] ~= nil and GameInfo.Yields[yieldType].IconString ~= nil and GameInfo.Yields[yieldType].IconString ~= "" then iconString = GameInfo.Yields[yieldType].IconString
        elseif	GameInfo.GreatPersonClasses[yieldType] ~= nil and GameInfo.GreatPersonClasses[yieldType].IconString ~= nil and GameInfo.GreatPersonClasses[yieldType].IconString ~= "" then iconString = GameInfo.GreatPersonClasses[yieldType].IconString
        elseif	GameInfo.Resources[yieldType] ~= nil        then iconString = "[ICON_"..yieldType.."]"
        elseif	GameInfo.Districts[yieldType] ~= nil        then iconString = "[ICON_"..yieldType.."]"
        else    iconString = "???"; end			
        return  iconString;
    end
--根据产出获得文本颜色
    function RUIVO_GetYieldTextColor( yieldType:string )
        if		GameInfo.Ruivo_Yield_IconString[yieldType]	    then return GameInfo.Ruivo_Yield_IconString[yieldType].TextColor
        elseif  yieldType == "YIELD_FOOD"		                then return "[COLOR:ResFoodLabelCS]";
        elseif  yieldType == "YIELD_PRODUCTION"	                then return "[COLOR:ResProductionLabelCS]";
        elseif  yieldType == "YIELD_GOLD"		                then return "[COLOR:ResGoldLabelCS]";
        elseif  yieldType == "YIELD_SCIENCE"                    then return "[COLOR:ResScienceLabelCS]";
        elseif  yieldType == "YIELD_CULTURE"                    then return "[COLOR:ResCultureLabelCS]";
        elseif  yieldType == "YIELD_FAITH"                      then return "[COLOR:ResFaithLabelCS]";
        elseif  yieldType == "YIELD_TOURISM"                    then return "[COLOR:ResTourismLabelCS]";
        elseif  yieldType == "YIELD_INFLUENCE"                  then return "[COLOR:DiplomaticLabelCS]";
        elseif  yieldType == "YIELD_FAVOR"                      then return "[COLOR:ResFavorLabelCS]";
        elseif  yieldType == "YIELD_POWER"                      then return "[COLOR:TutorialCS]";
        elseif  yieldType == "YIELD_AMENITY"                    then return "[COLOR:UnitPanelTextCS]";
        elseif  yieldType == "YIELD_HOUSING"                    then return "[COLOR:UnitPanelTextCS]";
        elseif  yieldType == "YIELD_LOYALTY"                    then return "[COLOR:UnitPanelTextCS]";
        elseif  yieldType == "YIELD_TRADE_ROUTE"                then return "[COLOR:UnitPanelTextCS]";
        elseif  yieldType == "YIELD_DISTRICT_SLOT"              then return "[COLOR:UnitPanelTextCS]";
        elseif	GameInfo.GreatPersonClasses[yieldType] ~= nil   then return "[COLOR:PiratesButtonCS]";
        elseif	GameInfo.Resources[yieldType] ~= nil            then return "[COLOR_FLOAT_MILITARY]";
        else                                                         return "[COLOR:255,255,255,255]";
        end				
    end
--根据产出和类型获得产出名称（返回已本地化文本）
    function RUIVO_GetYieldText(yieldType, ProvideType)
        local YieldText = ""

        --区域LOC_DISTRICT_NAME 
        --城市LOC_CITY_NAME_BLANK 
        --文明LOC_WORLDBUILDER_CIVILIZATION 
        --领袖LOC_WORLDBUILDER_LEADER 
        --玩家LOC_WORLDBUILDER_PLAYER

        
        --========================
        --自定义产出及其图标
        --========================
        if GameInfo.Ruivo_Yield_IconString[yieldType] then
            return Locale.Lookup(GameInfo.Ruivo_Yield_IconString[yieldType].Name)
        end


        --========================
        -- 基础产出
        --========================
        if ProvideType == "SelfBonus" and GameInfo.Yields[yieldType] then
            return Locale.Lookup(GameInfo.Yields[yieldType].Name)

        elseif ProvideType == "SelfMultiplier" and GameInfo.Yields[yieldType] then
            return Locale.Lookup("LOC_DISTRICT_NAME") .. Locale.Lookup(GameInfo.Yields[yieldType].Name)

        --========================
        -- 电力相关
        --========================
        elseif ProvideType == "SelfPower" and yieldType == "YIELD_POWER" then
            return Locale.Lookup("LOC_HUD_POWER_LENS")

        elseif ProvideType == "SelfPowerModifier" and yieldType == "YIELD_POWER" then
            return Locale.Lookup("LOC_CITY_NAME_BLANK") .. Locale.Lookup("LOC_HUD_POWER_LENS")

        --========================
        -- 特殊产出类型
        --========================
        elseif ProvideType == "SelfTourism" and yieldType == "YIELD_TOURISM" then
            return Locale.Lookup("LOC_TOP_PANEL_TOURISM")

        elseif ProvideType == "SelfAmenity" and yieldType == "YIELD_AMENITY" then
            return Locale.Lookup("LOC_HUD_CITY_AMENITIES")

        elseif ProvideType == "SelfHousing" and yieldType == "YIELD_HOUSING" then
            return Locale.Lookup("LOC_HUD_CITY_HOUSING")

        elseif ProvideType == "SelfLoyalty" and yieldType == "YIELD_LOYALTY" then
            return Locale.Lookup("LOC_OPTIONS_HOTKEY_LENSES_LOYALTY")

        elseif ProvideType == "SelfInfluence" and yieldType == "YIELD_INFLUENCE" then
            return Locale.Lookup("LOC_CITY_STATES_TITLE") .. Locale.Lookup("LOC_DIPLOMATIC")

        elseif ProvideType == "SelfFavor" and yieldType == "YIELD_FAVOR" then
            return Locale.Lookup("LOC_HOF_STAT_DIPLOMATIC_FAVOR")

        elseif ProvideType == "SelfTradeRoute" and yieldType == "YIELD_TRADE_ROUTE" then
            return Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES")

        elseif ProvideType == "SelfExtraDistrictSlot" and yieldType == "YIELD_DISTRICT_SLOT" then
            return Locale.Lookup("LOC_DISTRICT_NAME")

        --========================
        -- 战略资源
        --========================
        elseif ProvideType == "SelfExtractResource" and GameInfo.Resources[yieldType] then
            return Locale.Lookup(GameInfo.Resources[yieldType].Name)

        --========================
        -- 伟人点
        --========================
        elseif ProvideType == "GreatPersonPoints" and GameInfo.GreatPersonClasses[yieldType] then
            return Locale.Lookup(GameInfo.GreatPersonClasses[yieldType].Name)

        elseif ProvideType == "GreatPersonMultiplier" and GameInfo.GreatPersonClasses[yieldType] then
            return Locale.Lookup("LOC_WORLDBUILDER_PLAYER") .. Locale.Lookup(GameInfo.GreatPersonClasses[yieldType].Name)
        end

        --========================
        -- 默认：返回提示字符串
        --========================
        return YieldText ~= "" and YieldText or "[" .. tostring(ProvideType) .. "/" .. tostring(yieldType) .. "]"
    end
--根据任意数值返回一个带有 + / - 或 0 的字符串
    function RUIVO_toPlusMinusString( value:number )
        if value == 0 then return "0"; end
        --return Locale.ToNumber(value, "+#,###.#;-#,###.#");
        return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
    end
--根据产出和数量获得完整文本
    function RUIVO_GetYieldString( yieldType:string, amount:number )
        return RUIVO_GetYieldTextIcon(yieldType)..RUIVO_GetYieldTextColor(yieldType)..RUIVO_toPlusMinusString(amount).."[ENDCOLOR]";
    end
--获取自定义对象（CustomAdjacentObject）的本地化名称，带图标（若可用）
    function RUIVO_GetCAOName(CustomAdjacentObject)
        local icon = ""
        local Name = ""

        -- 尝试获取图标文本
        local iconText = RUIVO_GetYieldTextIcon(CustomAdjacentObject)
        if iconText ~= "???" then
            icon = icon .. iconText
        end

        -- 按类别判断对象类型，找到其名称
        --（产出、地形、地貌、资源、改良、区域、建筑、单位）
        if GameInfo.Ruivo_CAO[CustomAdjacentObject] then
            Name = GameInfo.Ruivo_CAO[CustomAdjacentObject].Name
        elseif GameInfo.Yields[CustomAdjacentObject] then
            Name = GameInfo.Yields[CustomAdjacentObject].Name
        elseif GameInfo.Terrains[CustomAdjacentObject] then
            Name = GameInfo.Terrains[CustomAdjacentObject].Name

        elseif GameInfo.Features[CustomAdjacentObject] then
            Name = GameInfo.Features[CustomAdjacentObject].Name

        elseif GameInfo.Resources[CustomAdjacentObject] then
            Name = GameInfo.Resources[CustomAdjacentObject].Name

        elseif GameInfo.Improvements[CustomAdjacentObject] then
            Name = GameInfo.Improvements[CustomAdjacentObject].Name

        elseif GameInfo.Districts[CustomAdjacentObject] then
            Name = GameInfo.Districts[CustomAdjacentObject].Name

        elseif GameInfo.Buildings[CustomAdjacentObject] then
            Name = GameInfo.Buildings[CustomAdjacentObject].Name

        elseif GameInfo.Units[CustomAdjacentObject] then
            Name = GameInfo.Units[CustomAdjacentObject].Name
        elseif GameInfo.Ruivo_Terrain_Function[CustomAdjacentObject] then
            Name = GameInfo.Ruivo_Terrain_Function[CustomAdjacentObject].Name

        else
            -- 如果未找到任何匹配类型，返回标记为未知
            Name = tostring(CustomAdjacentObject)
            return icon .. Name
        end

        -- 使用 Locale.Lookup 本地化显示名称
        Name = Locale.Lookup(Name)
        return icon .. Name
    end
--根据modifier来源获取对应的对象名称
Modifier_sources = {        --来源
    "Buildings",            --建筑√
    "Policies",             --政策√
    "Beliefs",              --信仰√
    "Technologies",         --科技√
    "Civics",               --市政√
    "Governments",          --政体√
    "GovernorPromotions"    --总督晋升√
}
    function RUIVO_AppendOwnerInfo(tooltipText, ownerKey)
        for _, source in ipairs(Modifier_sources) do
            if GameInfo[source][ownerKey] then
                local Name = Locale.Lookup(GameInfo[source][ownerKey].Name)
                return tooltipText .. " (" .. Name .. ")" -- 找到匹配的就返回
            end
        end
        return tooltipText -- 没找到则返回原文本
    end
--============================================================================================================================


--============================================================================================================================
--统计整合模块->switch模块--GP环境
    function StatsModule_For_GP(AdjacencyType, CustomAdjacentObject, iX, iY, playerID, City, Rings)
        local PropertyValueAmount = -1;
    --全局属性（无参数）
        if AdjacencyType == 'FROM_UNCONDITIONAL_BONUS' then PropertyValueAmount = FROM_UNCONDITIONAL_BONUS() end
        if AdjacencyType == 'FROM_STORM_HAPPEND' then PropertyValueAmount = FROM_STORM_HAPPEND() end
        if AdjacencyType == 'FROM_STANDARDIZE_TURNS' then PropertyValueAmount = FROM_STANDARDIZE_TURNS() end
    
    --自定义相邻对象
        if AdjacencyType == 'FROM_HIGHEST_HUMAN_YIELD' then PropertyValueAmount = FROM_HIGHEST_HUMAN_YIELD(CustomAdjacentObject) end
    --property系列！！！
        if AdjacencyType == "FROM_GAME_PROPERTY" then PropertyValueAmount = FROM_GAME_PROPERTY(CustomAdjacentObject) end
        if AdjacencyType == "FROM_GAME_PROPERTY_HASHED" then PropertyValueAmount = FROM_GAME_PROPERTY_HASHED(CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLOT_PROPERTY" then PropertyValueAmount = FROM_PLOT_PROPERTY(iX, iY, CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLOT_PROPERTY_HASHED" then PropertyValueAmount = FROM_PLOT_PROPERTY_HASHED(iX, iY, CustomAdjacentObject) end
        if AdjacencyType == "FROM_CITY_PROPERTY" then PropertyValueAmount = FROM_CITY_PROPERTY(City, CustomAdjacentObject) end
        if AdjacencyType == "FROM_CITY_PROPERTY_HASHED" then PropertyValueAmount = FROM_CITY_PROPERTY_HASHED(City, CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLAYER_PROPERTY" then PropertyValueAmount = FROM_PLAYER_PROPERTY(playerID, CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLAYER_PROPERTY_HASHED" then PropertyValueAmount = FROM_PLAYER_PROPERTY_HASHED(playerID, CustomAdjacentObject) end

    --单元格属性：
        --自定义+环数
        if AdjacencyType == 'FROM_RINGS_TYPETAG_RESOURCE' then PropertyValueAmount = FROM_RINGS_TYPETAG_RESOURCE(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_RESOURCE' then PropertyValueAmount = FROM_RINGS_CAO_RESOURCE(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_IMPROVEMENT' then PropertyValueAmount = FROM_RINGS_CAO_IMPROVEMENT(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_DISTRICT' then PropertyValueAmount = FROM_RINGS_CAO_DISTRICT(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_FEATURE' then PropertyValueAmount = FROM_RINGS_CAO_FEATURE(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_TERRAIN_SETS' then PropertyValueAmount = FROM_RINGS_CAO_TERRAIN_SETS(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_TERRAIN' then PropertyValueAmount = FROM_RINGS_CAO_TERRAIN(iX, iY, CustomAdjacentObject, Rings) end

        --正常相邻（环数）
        if AdjacencyType == 'FROM_RINGS_NATIONALPARK' then PropertyValueAmount = FROM_RINGS_NATIONALPARK(iX, iY, Rings) end

        --正常相邻
        if AdjacencyType == 'FROM_LAND_WATER_PAIR' then PropertyValueAmount = FROM_LAND_WATER_PAIR(iX, iY) end
        if AdjacencyType == 'FROM_RIVER_CROSSING' then PropertyValueAmount = FROM_RIVER_CROSSING(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_ROUTE' then PropertyValueAmount = FROM_ADJACENT_ROUTE(iX, iY) end
        if AdjacencyType == 'FROM_SELF_ROUTE' then PropertyValueAmount = FROM_SELF_ROUTE(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_WORKER' then PropertyValueAmount = FROM_ADJACENT_WORKER(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_UNIT' then PropertyValueAmount = FROM_ADJACENT_UNIT(iX, iY) end
        if AdjacencyType == 'FROM_SELF_WORKER' then PropertyValueAmount = FROM_SELF_WORKER(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_DISTRICT_AND_WONDER' then PropertyValueAmount = FROM_ADJACENT_DISTRICT_AND_WONDER(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_DISTRICT' then PropertyValueAmount = FROM_ADJACENT_DISTRICT(iX, iY) end
        if AdjacencyType == 'FROM_CLIFF' then PropertyValueAmount = FROM_CLIFF(iX, iY) end
        if AdjacencyType == 'FROM_LATITUDE' then PropertyValueAmount = FROM_LATITUDE(iX, iY) end
        if AdjacencyType == 'FROM_POLE' then PropertyValueAmount = FROM_POLE(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_LAKE' then PropertyValueAmount = FROM_ADJACENT_LAKE(iX, iY) end
        --本格淡水等级
        if AdjacencyType == 'FROM_SELF_WATER_LEVEL' then PropertyValueAmount = FROM_SELF_WATER_LEVEL(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_WATER_LEVEL' then PropertyValueAmount = FROM_ADJACENT_WATER_LEVEL(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_RESOURCE' then PropertyValueAmount = FROM_ADJACENT_RESOURCE(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_WONDERS' then PropertyValueAmount = FROM_ADJACENT_WONDERS(iX, iY) end

    --城市属性：
        if AdjacencyType == 'FROM_CITY_POPULATION' then PropertyValueAmount = FROM_CITY_POPULATION(City) end
        if AdjacencyType == 'FROM_CITY_TOTAL_HOUSING' then PropertyValueAmount = FROM_CITY_TOTAL_HOUSING(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_HOUSING' then PropertyValueAmount = FROM_CITY_SURPLUS_HOUSING(City) end
        if AdjacencyType == 'FROM_CITY_DISTRICTS_NUM' then PropertyValueAmount = FROM_CITY_DISTRICTS_NUM(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_FOOD' then PropertyValueAmount = FROM_CITY_SURPLUS_FOOD(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_AMENITIES' then PropertyValueAmount = FROM_CITY_SURPLUS_AMENITIES(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS' then PropertyValueAmount = FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS(City) end
        if AdjacencyType == 'FROM_CITY_DEFENSE_STRENGTH' then PropertyValueAmount = FROM_CITY_DEFENSE_STRENGTH(City) end
    --城市属性（自定义对象）
        if AdjacencyType == 'FROM_CITY_CAO_YIELD' then PropertyValueAmount = FROM_CITY_CAO_YIELD(City, CustomAdjacentObject) end

    --玩家属性：
        if AdjacencyType == 'FROM_PLAYER_TECHS_NUM' then PropertyValueAmount = FROM_PLAYER_TECHS_NUM(playerID) end  
        if AdjacencyType == 'FROM_PLAYER_CIVICS_NUM' then PropertyValueAmount = FROM_PLAYER_CIVICS_NUM(playerID) end  

        if AdjacencyType == 'FROM_SLOT_MILITARY' then PropertyValueAmount = FROM_SLOT_MILITARY(playerID) end  
        if AdjacencyType == 'FROM_SLOT_ECONOMIC' then PropertyValueAmount = FROM_SLOT_ECONOMIC(playerID) end  
        if AdjacencyType == 'FROM_SLOT_DIPLOMATIC' then PropertyValueAmount = FROM_SLOT_DIPLOMATIC(playerID) end  
        if AdjacencyType == 'FROM_SLOT_GREAT_PERSON' then PropertyValueAmount = FROM_SLOT_GREAT_PERSON(playerID) end  
        if AdjacencyType == 'FROM_SLOT_WILDCARD' then PropertyValueAmount = FROM_SLOT_WILDCARD(playerID) end  
        if AdjacencyType == 'FROM_PLAYER_TOTAL_UNITS' then PropertyValueAmount = FROM_PLAYER_TOTAL_UNITS(playerID) end  
        if AdjacencyType == 'FROM_PLAYER_RESOURCES_TYPES' then PropertyValueAmount = FROM_PLAYER_RESOURCES_TYPES(playerID) end  
        if AdjacencyType == 'FROM_OUTGOING_ROUTES' then PropertyValueAmount = FROM_OUTGOING_ROUTES(playerID) end
        if AdjacencyType == 'FROM_CAO_IMPROVEMENT_RESOURCE_TYPES' then PropertyValueAmount = FROM_CAO_IMPROVEMENT_RESOURCE_TYPES(playerID, CustomAdjacentObject) end

    --宗教体系：仅GP
        if AdjacencyType == 'FROM_RELIGION_FAITH_YIELD' then PropertyValueAmount = FROM_RELIGION_FAITH_YIELD(playerID) end
        if AdjacencyType == 'FROM_RELIGION_BELIEFS_COUNT' then PropertyValueAmount = FROM_RELIGION_BELIEFS_COUNT(playerID) end
        if AdjacencyType == 'FROM_RELIGION_TOTAL_FOLLOWERS' then PropertyValueAmount = FROM_RELIGION_TOTAL_FOLLOWERS(playerID) end
        if AdjacencyType == 'FROM_RELIGION_FOREIGN_FOLLOWERS' then PropertyValueAmount = FROM_RELIGION_FOREIGN_FOLLOWERS(playerID) end
        if AdjacencyType == 'FROM_RELIGION_DOMESTIC_FOLLOWERS' then PropertyValueAmount = FROM_RELIGION_DOMESTIC_FOLLOWERS(playerID) end
        if AdjacencyType == 'FROM_RELIGION_TOTAL_CITIES_FOLLOWING' then PropertyValueAmount = FROM_RELIGION_TOTAL_CITIES_FOLLOWING(playerID) end
        if AdjacencyType == 'FROM_RELIGION_CITIES_WITH_WONDER' then PropertyValueAmount = FROM_RELIGION_CITIES_WITH_WONDER(playerID) end
        if AdjacencyType == 'FROM_RELIGION_FOREIGN_CITIES' then PropertyValueAmount = FROM_RELIGION_FOREIGN_CITIES(playerID) end
        if AdjacencyType == 'FROM_RELIGION_DOMESTIC_CITIES' then PropertyValueAmount = FROM_RELIGION_DOMESTIC_CITIES(playerID) end
        if AdjacencyType == 'FROM_RELIGION_CITY_PLAYER_FOLLOWERS' then PropertyValueAmount = FROM_RELIGION_CITY_PLAYER_FOLLOWERS(playerID, iX, iY) end

    --转产体系：不能用于预建造面版
        if AdjacencyType == 'FROM_SELF_YIELD_FOOD' then PropertyValueAmount = FROM_SELF_YIELD_FOOD(iX, iY) end
        if AdjacencyType == 'FROM_SELF_YIELD_PRODUCTION' then PropertyValueAmount = FROM_SELF_YIELD_PRODUCTION(iX, iY) end
        if AdjacencyType == 'FROM_SELF_YIELD_GOLD' then PropertyValueAmount = FROM_SELF_YIELD_GOLD(iX, iY) end
        if AdjacencyType == 'FROM_SELF_YIELD_SCIENCE' then PropertyValueAmount = FROM_SELF_YIELD_SCIENCE(iX, iY) end
        if AdjacencyType == 'FROM_SELF_YIELD_CULTURE' then PropertyValueAmount = FROM_SELF_YIELD_CULTURE(iX, iY) end
        if AdjacencyType == 'FROM_SELF_YIELD_FAITH' then PropertyValueAmount = FROM_SELF_YIELD_FAITH(iX, iY) end
    --返回值
        return PropertyValueAmount
    end
--============================================================================================================================
--统计整合模块->switch模块--UI环境
    function StatsModule_For_UI(AdjacencyType, CustomAdjacentObject, iX, iY, playerID, City, Rings)
        local PropertyValueAmount = -1;
    --全局属性（无参数）
        if AdjacencyType == 'FROM_UI_SEA_LEVEL' then PropertyValueAmount = FROM_UI_SEA_LEVEL() end

    --单元格属性：
        --本单元格单位等级之和
        if AdjacencyType == 'FROM_UI_SELF_UNIT_LEVELS' then PropertyValueAmount = FROM_UI_SELF_UNIT_LEVELS(iX, iY) end
        --相邻单元格单位等级之和
        if AdjacencyType == 'FROM_UI_ADJACENT_UNIT_LEVELS' then PropertyValueAmount = FROM_UI_ADJACENT_UNIT_LEVELS(iX, iY) end
        if AdjacencyType == 'FROM_UI_SELF_APPEAL' then PropertyValueAmount = FROM_UI_SELF_APPEAL(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_APPEAL' then PropertyValueAmount = FROM_UI_ADJACENT_APPEAL(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_FOOD' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_FOOD(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_PRODUCTION' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_PRODUCTION(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_GOLD' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_GOLD(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_SCIENCE' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_SCIENCE(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_CULTURE' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_CULTURE(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_FAITH' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_FAITH(iX, iY) end
    --城市属性：
        if AdjacencyType == 'FROM_UI_CITY_DISTRICT_SLOT' then PropertyValueAmount = FROM_UI_CITY_DISTRICT_SLOT(City) end
        if AdjacencyType == 'FROM_UI_CITY_SURPLUS_DISTRICT_SLOT' then PropertyValueAmount = FROM_UI_CITY_SURPLUS_DISTRICT_SLOT(City) end
        if AdjacencyType == 'FROM_UI_CITY_FREE_POWER' then PropertyValueAmount = FROM_UI_CITY_FREE_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_TEMPORARY_POWER' then PropertyValueAmount = FROM_UI_CITY_TEMPORARY_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_REQUIRED_POWER' then PropertyValueAmount = FROM_UI_CITY_REQUIRED_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_CURRENT_POWER' then PropertyValueAmount = FROM_UI_CITY_CURRENT_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_SURPLUS_POWER' then PropertyValueAmount = FROM_UI_CITY_SURPLUS_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_POWER_RATIO' then PropertyValueAmount = FROM_UI_CITY_POWER_RATIO(City) end
        if AdjacencyType == 'FROM_UI_CITY_LOYALTY_PERTURN' then PropertyValueAmount = FROM_UI_CITY_LOYALTY_PERTURN(City) end
        if AdjacencyType == 'FROM_UI_CITY_LOYALTY_PERCENT' then PropertyValueAmount = FROM_UI_CITY_LOYALTY_PERCENT(City) end
    --玩家属性：
        if AdjacencyType == 'FROM_UI_MILITARY_STRENGTH' then PropertyValueAmount = FROM_UI_MILITARY_STRENGTH(playerID) end  
    --返回值
        return PropertyValueAmount
    end
--============================================================================================================================
--统计整合模块->switch模块--UI和GP显示集合
    function StatsModule_For_Display(AdjacencyType, CustomAdjacentObject, iX, iY, playerID, City, Rings)
        local PropertyValueAmount = -1;
    --全局属性（无参数）
        if AdjacencyType == 'FROM_UNCONDITIONAL_BONUS' then PropertyValueAmount = FROM_UNCONDITIONAL_BONUS() end
        if AdjacencyType == 'FROM_STORM_HAPPEND' then PropertyValueAmount = FROM_STORM_HAPPEND() end
        if AdjacencyType == 'FROM_STANDARDIZE_TURNS' then PropertyValueAmount = FROM_STANDARDIZE_TURNS() end
        
        --UI
        if AdjacencyType == 'FROM_UI_SEA_LEVEL' then PropertyValueAmount = FROM_UI_SEA_LEVEL() end

    --自定义相邻对象
        if AdjacencyType == 'FROM_HIGHEST_HUMAN_YIELD' then PropertyValueAmount = FROM_HIGHEST_HUMAN_YIELD(CustomAdjacentObject) end
    --property系列！！！
        if AdjacencyType == "FROM_GAME_PROPERTY" then PropertyValueAmount = FROM_GAME_PROPERTY(CustomAdjacentObject) end
        if AdjacencyType == "FROM_GAME_PROPERTY_HASHED" then PropertyValueAmount = FROM_GAME_PROPERTY_HASHED(CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLOT_PROPERTY" then PropertyValueAmount = FROM_PLOT_PROPERTY(iX, iY, CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLOT_PROPERTY_HASHED" then PropertyValueAmount = FROM_PLOT_PROPERTY_HASHED(iX, iY, CustomAdjacentObject) end
        if AdjacencyType == "FROM_CITY_PROPERTY" then PropertyValueAmount = FROM_CITY_PROPERTY(City, CustomAdjacentObject) end
        if AdjacencyType == "FROM_CITY_PROPERTY_HASHED" then PropertyValueAmount = FROM_CITY_PROPERTY_HASHED(City, CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLAYER_PROPERTY" then PropertyValueAmount = FROM_PLAYER_PROPERTY(playerID, CustomAdjacentObject) end
        if AdjacencyType == "FROM_PLAYER_PROPERTY_HASHED" then PropertyValueAmount = FROM_PLAYER_PROPERTY_HASHED(playerID, CustomAdjacentObject) end

    --单元格属性：
        --自定义+环数
        if AdjacencyType == 'FROM_RINGS_TYPETAG_RESOURCE' then PropertyValueAmount = FROM_RINGS_TYPETAG_RESOURCE(iX, iY, CustomAdjacentObject, Rings) end     
        if AdjacencyType == 'FROM_RINGS_CAO_RESOURCE' then PropertyValueAmount = FROM_RINGS_CAO_RESOURCE(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_IMPROVEMENT' then PropertyValueAmount = FROM_RINGS_CAO_IMPROVEMENT(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_DISTRICT' then PropertyValueAmount = FROM_RINGS_CAO_DISTRICT(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_FEATURE' then PropertyValueAmount = FROM_RINGS_CAO_FEATURE(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_TERRAIN_SETS' then PropertyValueAmount = FROM_RINGS_CAO_TERRAIN_SETS(iX, iY, CustomAdjacentObject, Rings) end
        if AdjacencyType == 'FROM_RINGS_CAO_TERRAIN' then PropertyValueAmount = FROM_RINGS_CAO_TERRAIN(iX, iY, CustomAdjacentObject, Rings) end


        if AdjacencyType == 'FROM_RINGS_NATIONALPARK' then PropertyValueAmount = FROM_RINGS_NATIONALPARK(iX, iY, Rings) end

        
        if AdjacencyType == 'FROM_LAND_WATER_PAIR' then PropertyValueAmount = FROM_LAND_WATER_PAIR(iX, iY) end
        if AdjacencyType == 'FROM_RIVER_CROSSING' then PropertyValueAmount = FROM_RIVER_CROSSING(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_ROUTE' then PropertyValueAmount = FROM_ADJACENT_ROUTE(iX, iY) end
        if AdjacencyType == 'FROM_SELF_ROUTE' then PropertyValueAmount = FROM_SELF_ROUTE(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_WORKER' then PropertyValueAmount = FROM_ADJACENT_WORKER(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_UNIT' then PropertyValueAmount = FROM_ADJACENT_UNIT(iX, iY) end
        if AdjacencyType == 'FROM_SELF_WORKER' then PropertyValueAmount = FROM_SELF_WORKER(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_DISTRICT_AND_WONDER' then PropertyValueAmount = FROM_ADJACENT_DISTRICT_AND_WONDER(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_DISTRICT' then PropertyValueAmount = FROM_ADJACENT_DISTRICT(iX, iY) end
        if AdjacencyType == 'FROM_CLIFF' then PropertyValueAmount = FROM_CLIFF(iX, iY) end
        if AdjacencyType == 'FROM_LATITUDE' then PropertyValueAmount = FROM_LATITUDE(iX, iY) end
        if AdjacencyType == 'FROM_POLE' then PropertyValueAmount = FROM_POLE(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_LAKE' then PropertyValueAmount = FROM_ADJACENT_LAKE(iX, iY) end
        --本格淡水等级
        if AdjacencyType == 'FROM_SELF_WATER_LEVEL' then PropertyValueAmount = FROM_SELF_WATER_LEVEL(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_WATER_LEVEL' then PropertyValueAmount = FROM_ADJACENT_WATER_LEVEL(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_RESOURCE' then PropertyValueAmount = FROM_ADJACENT_RESOURCE(iX, iY) end
        if AdjacencyType == 'FROM_ADJACENT_WONDERS' then PropertyValueAmount = FROM_ADJACENT_WONDERS(iX, iY) end

    --单元格属性仅UI
        --本单元格单位等级之和
        if AdjacencyType == 'FROM_UI_SELF_UNIT_LEVELS' then PropertyValueAmount = FROM_UI_SELF_UNIT_LEVELS(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_UNIT_LEVELS' then PropertyValueAmount = FROM_UI_ADJACENT_UNIT_LEVELS(iX, iY) end
        if AdjacencyType == 'FROM_UI_SELF_APPEAL' then PropertyValueAmount = FROM_UI_SELF_APPEAL(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_APPEAL' then PropertyValueAmount = FROM_UI_ADJACENT_APPEAL(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_FOOD' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_FOOD(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_PRODUCTION' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_PRODUCTION(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_GOLD' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_GOLD(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_SCIENCE' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_SCIENCE(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_CULTURE' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_CULTURE(iX, iY) end
        if AdjacencyType == 'FROM_UI_ADJACENT_YIELD_FAITH' then PropertyValueAmount = FROM_UI_ADJACENT_YIELD_FAITH(iX, iY) end
    --城市属性：
        if AdjacencyType == 'FROM_CITY_POPULATION' then PropertyValueAmount = FROM_CITY_POPULATION(City) end
        if AdjacencyType == 'FROM_CITY_TOTAL_HOUSING' then PropertyValueAmount = FROM_CITY_TOTAL_HOUSING(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_HOUSING' then PropertyValueAmount = FROM_CITY_SURPLUS_HOUSING(City) end
        if AdjacencyType == 'FROM_CITY_DISTRICTS_NUM' then PropertyValueAmount = FROM_CITY_DISTRICTS_NUM(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_FOOD' then PropertyValueAmount = FROM_CITY_SURPLUS_FOOD(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_AMENITIES' then PropertyValueAmount = FROM_CITY_SURPLUS_AMENITIES(City) end
        if AdjacencyType == 'FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS' then PropertyValueAmount = FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS(City) end
        if AdjacencyType == 'FROM_CITY_DEFENSE_STRENGTH' then PropertyValueAmount = FROM_CITY_DEFENSE_STRENGTH(City) end
    --城市属性（自定义对象）
        if AdjacencyType == 'FROM_CITY_CAO_YIELD' then PropertyValueAmount = FROM_CITY_CAO_YIELD(City, CustomAdjacentObject) end

    --城市属性仅UI：
        if AdjacencyType == 'FROM_UI_CITY_DISTRICT_SLOT' then PropertyValueAmount = FROM_UI_CITY_DISTRICT_SLOT(City) end
        if AdjacencyType == 'FROM_UI_CITY_SURPLUS_DISTRICT_SLOT' then PropertyValueAmount = FROM_UI_CITY_SURPLUS_DISTRICT_SLOT(City) end
        if AdjacencyType == 'FROM_UI_CITY_FREE_POWER' then PropertyValueAmount = FROM_UI_CITY_FREE_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_TEMPORARY_POWER' then PropertyValueAmount = FROM_UI_CITY_TEMPORARY_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_REQUIRED_POWER' then PropertyValueAmount = FROM_UI_CITY_REQUIRED_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_CURRENT_POWER' then PropertyValueAmount = FROM_UI_CITY_CURRENT_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_SURPLUS_POWER' then PropertyValueAmount = FROM_UI_CITY_SURPLUS_POWER(City) end
        if AdjacencyType == 'FROM_UI_CITY_POWER_RATIO' then PropertyValueAmount = FROM_UI_CITY_POWER_RATIO(City) end
        if AdjacencyType == 'FROM_UI_CITY_LOYALTY_PERTURN' then PropertyValueAmount = FROM_UI_CITY_LOYALTY_PERTURN(City) end
        if AdjacencyType == 'FROM_UI_CITY_LOYALTY_PERCENT' then PropertyValueAmount = FROM_UI_CITY_LOYALTY_PERCENT(City) end
    --玩家属性：
        if AdjacencyType == 'FROM_PLAYER_TECHS_NUM' then PropertyValueAmount = FROM_PLAYER_TECHS_NUM(playerID) end  
        if AdjacencyType == 'FROM_PLAYER_CIVICS_NUM' then PropertyValueAmount = FROM_PLAYER_CIVICS_NUM(playerID) end  

        if AdjacencyType == 'FROM_SLOT_MILITARY' then PropertyValueAmount = FROM_SLOT_MILITARY(playerID) end  
        if AdjacencyType == 'FROM_SLOT_ECONOMIC' then PropertyValueAmount = FROM_SLOT_ECONOMIC(playerID) end  
        if AdjacencyType == 'FROM_SLOT_DIPLOMATIC' then PropertyValueAmount = FROM_SLOT_DIPLOMATIC(playerID) end  
        if AdjacencyType == 'FROM_SLOT_GREAT_PERSON' then PropertyValueAmount = FROM_SLOT_GREAT_PERSON(playerID) end  
        if AdjacencyType == 'FROM_SLOT_WILDCARD' then PropertyValueAmount = FROM_SLOT_WILDCARD(playerID) end
        if AdjacencyType == 'FROM_PLAYER_TOTAL_UNITS' then PropertyValueAmount = FROM_PLAYER_TOTAL_UNITS(playerID) end  
        if AdjacencyType == 'FROM_PLAYER_RESOURCES_TYPES' then PropertyValueAmount = FROM_PLAYER_RESOURCES_TYPES(playerID) end  
        if AdjacencyType == 'FROM_OUTGOING_ROUTES' then PropertyValueAmount = FROM_OUTGOING_ROUTES(playerID) end
        if AdjacencyType == 'FROM_CAO_IMPROVEMENT_RESOURCE_TYPES' then PropertyValueAmount = FROM_CAO_IMPROVEMENT_RESOURCE_TYPES(playerID, CustomAdjacentObject) end

    --玩家属性仅UI：
        if AdjacencyType == 'FROM_UI_MILITARY_STRENGTH' then PropertyValueAmount = FROM_UI_MILITARY_STRENGTH(playerID) end  
  
    --返回值
        return PropertyValueAmount
    end
--============================================================================================================================


--全局属性（无参数）
--============================================================================================================================
--GP
--无条件加成
    function FROM_UNCONDITIONAL_BONUS() return 1 end
--本局风暴发生次数
    function FROM_STORM_HAPPEND()
        local stormTimes = Game:GetProperty("PROPERTY_RUIVO_STORM_TIMES") or 0
        return stormTimes
    end
--标准化回合数
    function FROM_STANDARDIZE_TURNS()
        local turn = Game.GetCurrentGameTurn()
        local gameSpeed = GameConfiguration.GetGameSpeedType()
        local iSpeedCostMultiplier = GameInfo.GameSpeeds[gameSpeed].CostMultiplier * 0.01
        local standardizeTurn = turn / iSpeedCostMultiplier
        return standardizeTurn
    end
--UI
--气候变化点数
    function FROM_UI_SEA_LEVEL()	
        local Count = GameClimate.GetClimateChangeForLastSeaLevelEvent();
        return Count
    end
--============================================================================================================================


--自定义相邻对象
--============================================================================================================================
--获取指定产出类型的最高人类玩家产出值
    function FROM_HIGHEST_HUMAN_YIELD(YieldType)
        --标准化YieldType判断
        local yieldIndex = GameInfo.Yields[YieldType]
        if yieldIndex == nil then
            return 0
        end

        local maxYield = 0
        for i, pPlayer in ipairs(Players) do
            if pPlayer:IsAlive() and pPlayer:IsHuman() then
                local yield = GetPlayerYield(i, YieldType)
                if yield > maxYield then
                    maxYield = yield
                end
            end
        end

        --print("人类玩家最高", YieldType, "为:", maxYield)
        return maxYield
    end
--取单个玩家的指定产出值
    function GetPlayerYield(playerID, yieldType)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local yieldAmount = 0

        if yieldType == "YIELD_SCIENCE" then
            local pTechs = pPlayer:GetTechs()
            if pTechs then yieldAmount = pTechs:GetScienceYield() end

        elseif yieldType == "YIELD_CULTURE" then
            local pCulture = pPlayer:GetCulture()
            if pCulture then yieldAmount = pCulture:GetCultureYield() end

        elseif yieldType == "YIELD_GOLD" then
            local pTreasury = pPlayer:GetTreasury()
            if pTreasury then yieldAmount = pTreasury:GetGoldYield() end

        elseif yieldType == "YIELD_FAITH" then
            local pReligion = pPlayer:GetReligion()
            if pReligion then yieldAmount = pReligion:GetFaithYield() end

        else
            -- 对于食物/生产等城市产出，累加所有城市
            for _, pCity in pPlayer:GetCities():Members() do
                yieldAmount = yieldAmount + pCity:GetYield(yieldType)
            end
        end

        return yieldAmount
    end
--============================================================================================================================


--============================================================================================================================
--自定义相邻对象：property体系
--============================================
--通用：获取原始 key 的 property
--============================================
--游戏全局
    function FROM_GAME_PROPERTY(CustomAdjacentObject)
        local propertyKey = CustomAdjacentObject
        local Count = Game:GetProperty(propertyKey) or 0
        return Count
    end
--单元格
    function FROM_PLOT_PROPERTY(iX, iY, CustomAdjacentObject)
        local Plot = Map.GetPlot(iX, iY)
        if not Plot then return 0 end
        local propertyKey = CustomAdjacentObject
        local Count = Plot:GetProperty(propertyKey) or 0
        return Count
    end
--城市
    function FROM_CITY_PROPERTY(City, CustomAdjacentObject)
        if not City then return 0 end
        local propertyKey = CustomAdjacentObject
        local Count = City:GetProperty(propertyKey) or 0
        return Count
    end
--玩家
    function FROM_PLAYER_PROPERTY(playerID, CustomAdjacentObject)
        local propertyKey = CustomAdjacentObject
        local player = Players[playerID]
        if not player then return 0 end
        local Count = player:GetProperty(propertyKey) or 0
        return Count
    end
--============================================
--哈希版：先对 key 做 DB.MakeHash 再读 property
--============================================
--游戏全局
    function FROM_GAME_PROPERTY_HASHED(CustomAdjacentObject)
        local propertyKey = DB.MakeHash(CustomAdjacentObject)
        local Count = Game:GetProperty(propertyKey) or 0
        return Count
    end
--单元格
    function FROM_PLOT_PROPERTY_HASHED(iX, iY, CustomAdjacentObject)
        local Plot = Map.GetPlot(iX, iY)
        if not Plot then return 0 end
        local propertyKey = DB.MakeHash(CustomAdjacentObject)
        local Count = Plot:GetProperty(propertyKey) or 0
        return Count
    end
--城市
    function FROM_CITY_PROPERTY_HASHED(City, CustomAdjacentObject)
        if not City then return 0 end
        local propertyKey = DB.MakeHash(CustomAdjacentObject)
        local Count = City:GetProperty(propertyKey) or 0
        return Count
    end
--玩家
    function FROM_PLAYER_PROPERTY_HASHED(playerID, CustomAdjacentObject)
        local player = Players[playerID]
        if not player then return 0 end
        local propertyKey = DB.MakeHash(CustomAdjacentObject)
        local Count = player:GetProperty(propertyKey) or 0
        return Count
    end
--============================================================================================================================


--单元格属性
--============================================================================================================================
--统计模块->范围内的国家公园
function FROM_RINGS_NATIONALPARK(iX, iY, Rings)
    local Count = 0
    local pCenterPlot = Map.GetPlot(iX, iY)

    -- 0 环视为自身，不搜索周围格子
    if Rings > 0 then
        -- 开始遍历
        local resultPlotIndexes = RuivoGetRingPlotIndexes(iX, iY, Rings)
        for _, plotIndex in ipairs(resultPlotIndexes) do
            local pPlot = Map.GetPlotByIndex(plotIndex)
            if pPlot and pPlot:IsNationalPark() then
                Count = Count + 1
            end
        end
    end

    return Count
end
--统计模块->指定环数内指定资源数量
    function FROM_RINGS_CAO_RESOURCE(iX, iY, CustomAdjacentObject, Rings)
        local Count = 0
        local Plot = Map.GetPlot(iX, iY)

        -- 0环视为自身，不搜索周围格子
        if Rings > 0 then
            --开始遍历
            local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
            for _, PlotIndex in ipairs(resultPlotIndex) do
                local plot = Map.GetPlotByIndex(PlotIndex)
                if plot:GetResourceType() ~= -1 then  -- -1 表示没有资源
                    local ResourceType = ResourceTypeMap[plot:GetResourceType()]
                    if ResourceType == CustomAdjacentObject then
                        Count = Count + 1
                    end
                end
            end
        end

        return Count
    end
--统计模块->指定环数内属于某tag的资源数量
    function FROM_RINGS_TYPETAG_RESOURCE(iX, iY, CustomAdjacentObject, Rings)
        local count = 0
        local centerPlot = Map.GetPlot(iX, iY)
        local tag = CustomAdjacentObject

        -- 确认 tag 合法，且是资源类
        local tagInfo = GameInfo.Tags[tag]
        if tagInfo == nil or tagInfo.Vocabulary ~= "RESOURCE_CLASS" then
            return 0
        end

        -- 遍历环范围
        local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
        for _, plotIndex in ipairs(resultPlotIndex) do
            local plot = Map.GetPlotByIndex(plotIndex)

            --环数大于0
            if Rings > 0 then
                --单元格是否有资源
                if plot and plot:GetResourceType() ~= -1 then
                    local resourceType = ResourceTypeMap[plot:GetResourceType()]

                    --是否为tag资源
                    if TypeTagsMap[tag] and TypeTagsMap[tag][resourceType] then
                        count = count + 1
                    end
                end

            end

        end

        return count
    end

--统计模块->指定环数内指定改良数量
    function FROM_RINGS_CAO_IMPROVEMENT(iX, iY, CustomAdjacentObject, Rings)
        local Count = 0
        if Rings > 0 then

            local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
            for _, PlotIndex in ipairs(resultPlotIndex) do
                local plot = Map.GetPlotByIndex(PlotIndex)
                if plot:GetImprovementType() ~= -1 and not plot:IsImprovementPillaged() then
                    local ImprovementType = ImprovementTypeMap[plot:GetImprovementType()]
                    if ImprovementType == CustomAdjacentObject then
                        Count = Count + 1
                    end
                end
            end

        end
        return Count
    end
--统计模块->指定环数内指定区域数量
    function FROM_RINGS_CAO_DISTRICT(iX, iY, CustomAdjacentObject, Rings)
        local Count = 0
        if Rings > 0 then
            local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
            for _, PlotIndex in ipairs(resultPlotIndex) do
                local plot = Map.GetPlotByIndex(PlotIndex)
                if plot:GetDistrictType() ~= -1 then
                    local DistrictType = DistrictTypeMap[plot:GetDistrictType()]
                    if DistrictType == CustomAdjacentObject then
                        Count = Count + 1
                    end
                end
            end
        end
        return Count
    end
--统计模块->指定环数内指定地貌数量
    function FROM_RINGS_CAO_FEATURE(iX, iY, CustomAdjacentObject, Rings)
        local Count = 0
        if Rings > 0 then
            local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
            for _, PlotIndex in ipairs(resultPlotIndex) do
                local plot = Map.GetPlotByIndex(PlotIndex)
                if plot:GetFeatureType() ~= -1 then
                    local FeatureType = FeatureTypeMap[plot:GetFeatureType()]
                    if FeatureType == CustomAdjacentObject then
                        Count = Count + 1
                    end
                end
            end
        end
        return Count
    end
--统计模块->指定环数内指定地形（函数格式）数量
    function FROM_RINGS_CAO_TERRAIN_SETS(iX, iY, CustomAdjacentObject, Rings)
        local Count = 0
        if Rings > 0 then
            local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
            for _, PlotIndex in ipairs(resultPlotIndex) do
                local plot = Map.GetPlotByIndex(PlotIndex)
                local isRight = false

                -- 常规 terrain 判断函数
                if CustomAdjacentObject == "IsMountain" then
                    isRight = plot:IsMountain()

                elseif CustomAdjacentObject == "IsHills" then
                    isRight = plot:IsHills()

                elseif CustomAdjacentObject == "IsFlatlands" then
                    isRight = plot:IsFlatlands()

                elseif CustomAdjacentObject == "IsWater" then
                    isRight = plot:IsWater()

                elseif CustomAdjacentObject == "IsShallowWater" then
                    isRight = plot:IsShallowWater()

                elseif CustomAdjacentObject == "IsLake" then
                    isRight = plot:IsLake()

                elseif CustomAdjacentObject == "IsCanyon" then
                    isRight = plot:IsCanyon()

                elseif CustomAdjacentObject == "IsCoastalLand" then
                    isRight = plot:IsCoastalLand()

                elseif CustomAdjacentObject == "IsRiverCrossing" then
                    isRight = plot:IsRiverCrossing()

                elseif CustomAdjacentObject == "IsOpenGround" then
                    isRight = plot:IsOpenGround()

                elseif CustomAdjacentObject == "IsRoughGround" then
                    isRight = plot:IsRoughGround()

                end

                if isRight then
                    Count = Count + 1
                end
            end
        end
        return Count
    end
--统计模块->指定环数内指定地形（地形type格式）数量
    function FROM_RINGS_CAO_TERRAIN(iX, iY, CustomAdjacentObject, Rings)
        local Count = 0
        if Rings > 0 then
            local resultPlotIndex = RuivoGetRingPlotIndexes(iX, iY, Rings)
            for _, PlotIndex in ipairs(resultPlotIndex) do
                local plot = Map.GetPlotByIndex(PlotIndex)
                if plot:GetTerrainType() ~= -1 then
                    local TerrainType = TerrainTypeMap[plot:GetTerrainType()]
                    if TerrainType == CustomAdjacentObject then
                        Count = Count + 1
                    end
                end
            end
        end
        return Count
    end
--============================================================================================================================

--============================================================================================================================
--通用部分：
--统计模块->相邻海陆对数
    function FROM_LAND_WATER_PAIR(iX, iY)
        local Count = 0

        for direction = 0, 2 do
            local oppo_direction = (direction + 3) % 6  -- 对称方向（六边形地图有 6 个方向）

            local plot = Map.GetAdjacentPlot(iX, iY, direction)
            local oppo_plot = Map.GetAdjacentPlot(iX, iY, oppo_direction)

            if plot and oppo_plot then
                if plot:IsWater() and not oppo_plot:IsWater() then
                    Count = Count + 1
                elseif not plot:IsWater() and oppo_plot:IsWater() then
                    Count = Count + 1
                end
            end
        end

        return Count
    end
--统计模块->相邻河流面数
    function FROM_RIVER_CROSSING(iX, iY)
        local Plot = Map.GetPlot(iX, iY);
        local Count = Plot:GetRiverCrossingCount();
        return Count;
    end
--统计模块->相邻道路数量，根据等级提供加成
    function FROM_ADJACENT_ROUTE(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                Count = Count + Plot:GetRouteType() + 1; --道路索引+1
            end
        end
        return Count;
    end
--统计模块->本格道路等级
    function FROM_SELF_ROUTE(iX, iY)
        local Plot = Map.GetPlot(iX, iY);
        local Count = Plot:GetRouteType() + 1 --道路索引+1
        return Count;
    end
--统计模块->相邻在岗公民
    function FROM_ADJACENT_WORKER(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                Count = Count + Plot:GetWorkerCount();
            end
        end
        return Count;
    end
--统计模块->相邻单位
    function FROM_ADJACENT_UNIT(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                --不包括商人
                --print("单元格",Plot:GetX(),Plot:GetY(),"有单位数量：",Plot:GetUnitCount())
                Count = Count + Plot:GetUnitCount();
            end
        end
        return Count;
    end
--统计模块->自己的在岗公民
    function FROM_SELF_WORKER(iX, iY)
        local Plot = Map.GetPlot(iX, iY);
        local Count = Plot:GetWorkerCount();
        --print(iX,iY,"自己的在岗公民：",Count);
        return Count;
    end
--统计模块->相邻奇观和区域
    function FROM_ADJACENT_DISTRICT_AND_WONDER(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                if Plot:GetDistrictType() ~= -1 then 
                    Count = Count + 1;
                end
            end
        end
        return Count;
    end
--统计模块->相邻区域
    function FROM_ADJACENT_DISTRICT(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                if Plot:GetDistrictType() ~= -1 then 
                    local DistrictType = GameInfo.Districts[Plot:GetDistrictType()].DistrictType;
                    if DistrictType ~= 'DISTRICT_WONDER' then
                        Count = Count + 1;
                    end
                end
            end
        end
        return Count;
    end
--统计模块->相邻悬崖
    function FROM_CLIFF(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0;
        if Plot:IsNEOfCliff() then Count = 1 
            --print("悬崖为东北方向")
        end
        if Plot:IsNWOfCliff() then Count = 1 
            --print("悬崖为西北方向")
        end
        if Plot:IsWOfCliff() then Count = 1 
            --print("悬崖为正西方向")
        end
        --print("最终数值：", Count)
        --print("-==============================")
        return Count;
    end
--统计模块->与赤道距离的百分比
    function FROM_LATITUDE(iX, iY)
        --print("-==============================")
        local iW, iH = Map.GetGridSize()
        local equator_y = (iH - 1) / 2
        local distance = math.abs(iY - equator_y)
        local max_distance = equator_y  -- 赤道到极地的最大距离
        local standard_distance = max_distance / 2  -- 25% ~ 75% 之间的距离

        local count = 0
        if distance < standard_distance then
            count = 1 - (distance / standard_distance)  -- 修正计算
        end

        count = math.max(0, math.min(1, count)) * 100
        --print(string.format("坐标(%d, %d) 赤道Y:%.1f 距离:%.1f 接近度:%d%%", iX, iY, equator_y, distance, count))
        --print("-==============================")
        return count
    end
--统计模块->与极地距离的百分比
    function FROM_POLE(iX, iY)
        --print("-==============================")
        local iW, iH = Map.GetGridSize()
        local equator_y = (iH - 1) / 2
        local distance = math.abs(iY - equator_y)
        local max_distance = equator_y  -- 赤道到极地的最大距离
        local standard_distance = max_distance / 2  -- 25% ~ 75% 之间的距离

        local count = 0
        if distance > standard_distance then
            count = (distance - standard_distance) / standard_distance  -- 修正计算
        end

        count = math.max(0, math.min(1, count)) * 100
        --print(string.format("坐标(%d, %d) 极地接近度:%d%%", iX, iY, count))
        --print("-==============================")
        return count
    end

--统计模块->相邻淡水湖数量
    function FROM_ADJACENT_LAKE(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                if Plot:IsLake() then
                    Count = Count + 1;
                end
            end
        end
        --print("相邻淡水湖数量：", Count)
        return Count;
    end

--统计模块->本单元格淡水等级（无水0，咸水1，淡水3）
    function FROM_SELF_WATER_LEVEL(iX, iY)
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0;
        if Plot then
            local NumToAdd = 0
            if Plot:IsCoastalLand() then NumToAdd = 1 end
            if Plot:IsFreshWater()  then NumToAdd = 3 end
            Count = Count + NumToAdd;
        end
        return Count;
    end
--统计模块->相邻淡水等级（无水0，咸水1，淡水3）
    function FROM_ADJACENT_WATER_LEVEL(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local NumToAdd = 0
                if Plot:IsCoastalLand() then NumToAdd = 1 end
                if Plot:IsFreshWater()  then NumToAdd = 3 end
                Count = Count + NumToAdd;
            end
        end
        --print("相邻淡水等级之和：", Count)
        return Count;
    end
--统计模块->相邻资源数量
    function FROM_ADJACENT_RESOURCE(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                if Plot:GetResourceType() > -1 then
                    Count = Count + 1;
                end
            end
        end
        return Count;
    end
--统计模块->相邻奇观数量
    function FROM_ADJACENT_WONDERS(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                if Plot:GetWonderType() > -1 then
                    if Plot:IsWonderComplete() then
                        Count = Count + 1;
                    end
                end
            end
        end
        return Count;
    end
--UI部分：
--统计模块->本单元格的单位等级
    function FROM_UI_SELF_UNIT_LEVELS(iX, iY)
        local plot = Map.GetPlot(iX, iY)
        local count = 0

        for _, pUnit in ipairs(Units.GetUnitsInPlot(plot)) do
            if(pUnit ~= nil) then
                local iLevel = pUnit:GetExperience():GetLevel()
                count = count + iLevel
            end
        end

        return count
    end
--统计模块->相邻单元格的单位等级
    function FROM_UI_ADJACENT_UNIT_LEVELS(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                Count = Count + FROM_UI_SELF_UNIT_LEVELS(Plot:GetX(), Plot:GetY());
            end
        end
        return Count;
    end
--统计模块->单元格魅力
    function FROM_UI_SELF_APPEAL(iX, iY)
        local Plot = Map.GetPlot(iX, iY);
        local Count = Plot:GetAppeal();
        return Count;
    end
--统计模块->相邻单元格魅力之和
    function FROM_UI_ADJACENT_APPEAL(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction); --获取相邻单元格
            if Plot then
                Count = Count + Plot:GetAppeal();
            end
        end
        return Count;
    end
--统计模块->相邻单元格的食物产出
    function FROM_UI_ADJACENT_YIELD_FOOD(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local iYield = GameInfo.Yields['YIELD_FOOD'].Index
                Count = Count + Plot:GetYield(iYield)
            end
        end
        return Count;
    end
--统计模块->相邻单元格的生产力产出
    function FROM_UI_ADJACENT_YIELD_PRODUCTION(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local iYield = GameInfo.Yields['YIELD_PRODUCTION'].Index
                Count = Count + Plot:GetYield(iYield)
            end
        end
        return Count;
    end
--统计模块->相邻单元格的金币产出
    function FROM_UI_ADJACENT_YIELD_GOLD(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local iYield = GameInfo.Yields['YIELD_GOLD'].Index
                Count = Count + Plot:GetYield(iYield)
            end
        end
        return Count;
    end
--统计模块->相邻单元格的科技产出
    function FROM_UI_ADJACENT_YIELD_SCIENCE(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local iYield = GameInfo.Yields['YIELD_SCIENCE'].Index
                Count = Count + Plot:GetYield(iYield)
            end
        end
        return Count;
    end
--统计模块->相邻单元格的文化产出
    function FROM_UI_ADJACENT_YIELD_CULTURE(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local iYield = GameInfo.Yields['YIELD_CULTURE'].Index
                Count = Count + Plot:GetYield(iYield)
            end
        end
        return Count;
    end
--统计模块->相邻单元格的信仰产出
    function FROM_UI_ADJACENT_YIELD_FAITH(iX, iY)
        local Count = 0;
        for direction = 0, 5 do
            local Plot = Map.GetAdjacentPlot(iX, iY, direction);
            if Plot then
                local iYield = GameInfo.Yields['YIELD_FAITH'].Index
                Count = Count + Plot:GetYield(iYield)
            end
        end
        return Count;
    end
--============================================================================================================================


--城市属性
--============================================================================================================================
--通用部分：
--统计模块->玩家激活的贸易路线数量（兼容 GP 和 UI 环境）
    function FROM_OUTGOING_ROUTES(playerID)
        local Count = 0
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pPlayerTrade = pPlayer:GetTrade()

        -- GP 环境：尝试使用 CountOutgoingRoutes()
        local successGP, result = pcall(function()
            return pPlayerTrade:CountOutgoingRoutes()
        end)

        if successGP then
            Count = result
        else
            -- UI 环境：尝试使用 GetNumOutgoingRoutes()
            local successUI, result2 = pcall(function()
                return pPlayerTrade:GetNumOutgoingRoutes()
            end)

            if successUI then
                Count = result2
            else
                -- 若两种方式都失败，返回 0 或 nil
                Count = 0
            end
        end

        return Count
    end
--统计模块->本城人口数量
    function FROM_CITY_POPULATION(City)
        local Population = City:GetPopulation();
        local Count = Population;
        --print("本城人口数量：", Count);
        return Count;
    end
--统计模块->本城总住房数
    function FROM_CITY_TOTAL_HOUSING(City)
        local CityGrowth = City:GetGrowth();
        local TotalHousing = CityGrowth:GetHousing();
        local Count = TotalHousing;
        --print("本城总住房数量：", Count);
        return Count;
    end
--统计模块->本城剩余住房数
    function FROM_CITY_SURPLUS_HOUSING(City)
        local CityGrowth = City:GetGrowth();
        local TotalHousing = CityGrowth:GetHousing();
        local Population = City:GetPopulation();
        local Count = TotalHousing - Population;
        --print("本城剩余住房数量：", Count);
        return Count;
    end
--统计模块->本城区域总数
    function FROM_CITY_DISTRICTS_NUM(city)
        local CityDistricts = city:GetDistricts()
        local DistrictsNum = 0

        -- GP 环境尝试：通过 GetNumDistricts 和 GetDistrictByIndex
        local successGP, _ = pcall(function()
            local totalNum = CityDistricts:GetNumDistricts()
            for i = 0, totalNum - 1 do
                local district = CityDistricts:GetDistrictByIndex(i)
                if district ~= nil and district:IsComplete() then
                    local districtType = district:GetType()
                    local districtInfo = GameInfo.Districts[districtType]
                    if districtInfo 
                    and districtInfo.DistrictType ~= "DISTRICT_WONDER" 
                    and districtInfo.DistrictType ~= "DISTRICT_CITY_CENTER" 
                    then
                        DistrictsNum = DistrictsNum + 1
                    end
                end
            end
        end)

        -- 如果 GP 方式失败，则尝试 UI 环境方式
        if not successGP then
            local successUI, _ = pcall(function()
                for _, district in CityDistricts:Members() do
                    if district ~= nil and district:IsComplete() then
                        local districtType = district:GetType()
                        local districtInfo = GameInfo.Districts[districtType]
                        if districtInfo 
                        and districtInfo.DistrictType ~= "DISTRICT_WONDER" 
                        and districtInfo.DistrictType ~= "DISTRICT_CITY_CENTER"
                        then
                            DistrictsNum = DistrictsNum + 1
                        end
                    end
                end
            end)

            -- 如果 UI 方式也失败，可以设为 0 或返回 nil 提示异常
            if not successUI then
                DistrictsNum = 0
            end
        end

        return DistrictsNum
    end
--统计模块->本城余粮
    function FROM_CITY_SURPLUS_FOOD(City)
        local CityGrowth = City:GetGrowth();
        local FoodSurplus = CityGrowth:GetFoodSurplus();
        local Count = FoodSurplus;
        --print("本城余粮数量：", Count);
        return Count;
    end
--统计模块->本城溢出宜居度
    function FROM_CITY_SURPLUS_AMENITIES(City)
        local CityGrowth = City:GetGrowth();
        local TotalAmenities = CityGrowth:GetAmenities();
        --print("本城总宜居度：", TotalAmenities);
        local Population = City:GetPopulation();
        local CITY_POP_PER_AMENITY = GameInfo.GlobalParameters['CITY_POP_PER_AMENITY'].Value
        --print("消耗1个宜居度的人口数：", CITY_POP_PER_AMENITY)
        local AmenitiesNeeded_FromPopulation = math.ceil(Population / CITY_POP_PER_AMENITY);--向上取整，1个人口也消耗1宜居，2个也消耗1宜居
        --print("人口消耗宜居度（向上取整）：", AmenitiesNeeded_FromPopulation);
        local CITY_AMENITIES_FOR_FREE = GameInfo.GlobalParameters['CITY_AMENITIES_FOR_FREE'].Value
        local Count = TotalAmenities + CITY_AMENITIES_FOR_FREE - AmenitiesNeeded_FromPopulation;
        --print("溢出宜居度：", Count);
        --print("-==============================")
        return Count;
    end
--统计模块->本城超出顶级幸福度部分的宜居度
    HIGHEST_LEVEL_HAPPINESS = 0
    function FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS(City)
        local count = FROM_CITY_SURPLUS_AMENITIES(City)
        count = math.max(count - HIGHEST_LEVEL_HAPPINESS, 0)  -- 防止负数
        --print("顶级幸福度的宜居度："..HIGHEST_LEVEL_HAPPINESS,"溢出部分："..count)
        return count
    end
--统计模块->本城市中心的防御
    function FROM_CITY_DEFENSE_STRENGTH(City)
        local CityDistricts = City:GetDistricts()
        local garrisonDefense = nil
    
        --第一尝试：GP环境 GetDistrictByIndex(0)
        local successGP, resultGP = pcall(function()
            local district = CityDistricts:GetDistrictByIndex(0)
            return math.floor(district:GetDefenseStrength() + 0.5)
        end)
    
        if successGP and resultGP then
            garrisonDefense = resultGP
        else
            --第二尝试：UI环境找出主城区并取防御力
            local successUI, resultUI = pcall(function()
                local members = CityDistricts:Members()
                for i,district in CityDistricts:Members() do
                    return math.floor(district:GetDefenseStrength() + 0.5)
                end
            end)
    
            if successUI and resultUI then
                garrisonDefense = resultUI
            else
                garrisonDefense = 0 -- 都失败就返回0，或你可设为 -1 / nil
            end
        end
    
        return garrisonDefense
    end
--统计模块->本城的产出
    function FROM_CITY_CAO_YIELD(City, CustomAdjacentObject)
        --标准化YieldType
        local YieldType = CustomAdjacentObject
        local yieldIndex = GameInfo.Yields[YieldType]
        if yieldIndex == nil then
            return 0
        end

        --获取产出
        local yieldValue = City:GetYield(YieldType)
        if yieldValue then return yieldValue
        else               return 0             end

    end
--UI部分：
--统计模块->本城区域位
    function FROM_UI_CITY_DISTRICT_SLOT(City)
        if not City then return 0 end

        local pCityDistricts = City:GetDistricts()
        local DistrictsPossibleNum = pCityDistricts:GetNumAllowedDistrictsRequiringPopulation()

        return DistrictsPossibleNum
    end
--统计模块->本城剩余区域位
    function FROM_UI_CITY_SURPLUS_DISTRICT_SLOT(City)
        if not City then return 0 end

        local pCityDistricts = City:GetDistricts()
        local DistrictsPossibleNum = pCityDistricts:GetNumAllowedDistrictsRequiringPopulation()
        local DistrictsNum = pCityDistricts:GetNumZonedDistrictsRequiringPopulation()

        return DistrictsPossibleNum - DistrictsNum
    end
--统计模块->本城清洁电力
    function FROM_UI_CITY_FREE_POWER(City)
        local pCityPower = City:GetPower()  -- 修正 pCityPower 的获取方式
        local freePower = pCityPower:GetFreePower()
        return freePower
    end
--统计模块->本城临时电力
    function FROM_UI_CITY_TEMPORARY_POWER(City)
        local pCityPower = City:GetPower()
        local temporaryPower = pCityPower:GetTemporaryPower()
        if pCityPower:IsFullyPoweredByActiveProject() then
            temporaryPower = pCityPower:GetRequiredPower()
        end
        return temporaryPower
    end
--统计模块->本城电力需求
    function FROM_UI_CITY_REQUIRED_POWER(City)
        local pCityPower = City:GetPower()
        local requiredPower = pCityPower:GetRequiredPower()
        return requiredPower
    end
--统计模块->本城总电力
    function FROM_UI_CITY_CURRENT_POWER(City)
        local pCityPower = City:GetPower()
        local freePower = pCityPower:GetFreePower()
        local temporaryPower = pCityPower:GetTemporaryPower()
        local currentPower = freePower + temporaryPower
        return currentPower
    end
--统计模块->本城溢出电力
    function FROM_UI_CITY_SURPLUS_POWER(City)
        local pCityPower = City:GetPower()
        local currentPower = pCityPower:GetFreePower() + pCityPower:GetTemporaryPower()
        local requiredPower = pCityPower:GetRequiredPower()
        local surplusPower = currentPower - requiredPower
        return surplusPower
    end
--统计模块->本城供电率
    function FROM_UI_CITY_POWER_RATIO(City)
        local pCityPower = City:GetPower()
        local currentPower = pCityPower:GetFreePower() + pCityPower:GetTemporaryPower()
        local requiredPower = pCityPower:GetRequiredPower()
        local powerRatio = requiredPower > 0 and (currentPower / requiredPower * 100) or 100
        return powerRatio
    end
--统计模块->本城忠诚度
    function FROM_UI_CITY_LOYALTY_PERTURN(City)
        local CityCulturalIdentity = City:GetCulturalIdentity()
        local loyaltyPerTurn = CityCulturalIdentity:GetLoyaltyPerTurn()
        return loyaltyPerTurn
    end
--统计模块->本城忠诚率
    function FROM_UI_CITY_LOYALTY_PERCENT(City)
        local CityCulturalIdentity = City:GetCulturalIdentity()
        local currentLoyalty = CityCulturalIdentity:GetLoyalty();
        local maxLoyalty = CityCulturalIdentity:GetMaxLoyalty();
        local loyaltyPercent = (currentLoyalty / maxLoyalty) * 100;
        return loyaltyPercent
    end
--============================================================================================================================


--玩家属性
--============================================================================================================================
--通用部分：
--统计模块->统计玩家拥有的科技数量
    function FROM_PLAYER_TECHS_NUM(playerID)
        local pPlayer = Players[playerID]
        if pPlayer == nil then return 0 end

        local amount = 0
        local pTechs = pPlayer:GetTechs()

        for row in GameInfo.Technologies() do
            if pTechs:HasTech(row.Index) then
                amount = amount + 1
            end
        end
        return amount
    end

--统计模块->统计玩家拥有的市政数量
    function FROM_PLAYER_CIVICS_NUM(playerID)
        local pPlayer = Players[playerID]
        if pPlayer == nil then return 0 end

        local amount = 0
        local pCulture = pPlayer:GetCulture()

        for row in GameInfo.Civics() do
            if pCulture:HasCivic(row.Index) then
                amount = amount + 1
            end
        end
        return amount
    end

--核心组件->玩家政策卡数量
    function PLAYER_SLOT_CARD_TYPE_NUM(playerID)
        local PolicySlotTypeAmount = {
            SLOT_MILITARY    = 0,  -- 军事卡
            SLOT_ECONOMIC    = 0,  -- 经济卡
            SLOT_DIPLOMATIC  = 0,  -- 外交卡
            SLOT_GREAT_PERSON = 0, -- 伟人卡
            SLOT_WILDCARD    = 0   -- 通配卡（通用卡、黑暗时代卡、黄金时代卡）
        }

        local pPlayer = Players[playerID]
        if not pPlayer then
            return PolicySlotTypeAmount
        end

        local PlayerCulture = pPlayer:GetCulture()
        local NumPolicySlots = PlayerCulture:GetNumPolicySlots()

        if NumPolicySlots then  -- 判断是否有政策槽
            for index = 0, NumPolicySlots - 1 do  -- 索引从0开始，到总政策槽位数-1
                local iPolicy = PlayerCulture:GetSlotPolicy(index)
                if iPolicy and GameInfo.Policies[iPolicy] then
                    local PolicyName = GameInfo.Policies[iPolicy].Name  -- 便于调试或后续扩展使用
                    local PolicyType = GameInfo.Policies[iPolicy].GovernmentSlotType
                    if PolicySlotTypeAmount[PolicyType] then -- 记录对应政策卡类型数量
                        PolicySlotTypeAmount[PolicyType] = PolicySlotTypeAmount[PolicyType] + 1
                    end
                end
            end
        end

        return PolicySlotTypeAmount
    end
--统计模块->玩家军事卡数量
    function FROM_SLOT_MILITARY(playerID)
        local PolicySlotTypeAmount = PLAYER_SLOT_CARD_TYPE_NUM(playerID)
        return PolicySlotTypeAmount["SLOT_MILITARY"]
    end
--统计模块->玩家经济卡数量
    function FROM_SLOT_ECONOMIC(playerID)
        local PolicySlotTypeAmount = PLAYER_SLOT_CARD_TYPE_NUM(playerID)
        return PolicySlotTypeAmount["SLOT_ECONOMIC"]
    end
--统计模块->玩家外交卡数量
    function FROM_SLOT_DIPLOMATIC(playerID)
        local PolicySlotTypeAmount = PLAYER_SLOT_CARD_TYPE_NUM(playerID)
        return PolicySlotTypeAmount["SLOT_DIPLOMATIC"]
    end
--统计模块->玩家伟人卡数量
    function FROM_SLOT_GREAT_PERSON(playerID)
        local PolicySlotTypeAmount = PLAYER_SLOT_CARD_TYPE_NUM(playerID)
        return PolicySlotTypeAmount["SLOT_GREAT_PERSON"]
    end
--统计模块->玩家通配卡数量
    function FROM_SLOT_WILDCARD(playerID)
        local PolicySlotTypeAmount = PLAYER_SLOT_CARD_TYPE_NUM(playerID)
        return PolicySlotTypeAmount["SLOT_WILDCARD"]
    end
--统计模块->玩家总单位
    function FROM_PLAYER_TOTAL_UNITS(playerID)
        local Count = 0
        local pPlayer = Players[playerID];
        local PlayerUnits = pPlayer:GetUnits()
        Count = PlayerUnits:GetCount();
        return Count
    end

--统计模块->玩家总资源类型
    function FROM_PLAYER_RESOURCES_TYPES(playerID)
        local pPlayer = Players[playerID]
        local playerResources = pPlayer:GetResources()

        local Count = 0
        for row in GameInfo.Resources() do
            if playerResources:HasResource(row.Index) then
                Count = Count + 1
            end
        end

        return Count
    end
--统计模块->玩家对应改良的资源持有类型
    function FROM_CAO_IMPROVEMENT_RESOURCE_TYPES(playerID, CustomAdjacentObject)
        local player = Players[playerID]
        if not player then return 0 end

        local Count = 0

        for Row in GameInfo.Improvement_ValidResources() do
            -- 对应改良
            if Row.ImprovementType == CustomAdjacentObject then
                local ResourceType = Row.ResourceType
                local ResourceIndex = GameInfo.Resources[ResourceType] and GameInfo.Resources[ResourceType].Index
                -- 持有则+1
                if ResourceIndex and player:GetResources():HasResource(ResourceIndex) then
                    Count = Count + 1
                end
            end
        end

        return Count
    end
--UI部分：
--统计模块->玩家总军事战力
    function FROM_UI_MILITARY_STRENGTH(playerID)
        return Players[playerID]:GetStats():GetMilitaryStrengthWithoutTreasury()
    end
--============================================================================================================================


--宗教体系
--============================================================================================================================
--仅GP部分：也就是UI无法显示的部分：
--统计模块->玩家每回合信仰值产出
    function FROM_RELIGION_FAITH_YIELD(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pReligion = pPlayer:GetReligion()
        if pReligion then
            local iFaith = pReligion:GetFaithYield()
            --print("玩家每回合信仰值产出：", iFaith)
            return iFaith
        end
        return 0
    end

--统计模块->玩家宗教信条数量
    function FROM_RELIGION_BELIEFS_COUNT(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pStats:table = pPlayer:GetStats()
        if pStats then
            local iBeliefs = pStats:GetNumBeliefsInReligion() or 0
            --print("玩家宗教信条数量：", iBeliefs)
            return iBeliefs
        end
        return 0
    end

--统计模块->玩家总信徒数量
    function FROM_RELIGION_TOTAL_FOLLOWERS(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pStats:table = pPlayer:GetStats()
        if pStats then
            local pReligion = pPlayer:GetReligion()
            if pReligion then
                local iFollowers = pStats:GetNumFollowers() or 0
                --print("玩家总信徒数量：", iFollowers)
                return iFollowers
            end
        end
        return 0
    end

--统计模块->玩家外国信徒数量
    function FROM_RELIGION_FOREIGN_FOLLOWERS(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pStats:table = pPlayer:GetStats()
        if pStats then
            local pReligion = pPlayer:GetReligion()
            if pReligion then
                local iForeignFollowers = pStats:GetNumForeignFollowers() or 0
                --print("玩家外国信徒数量：", iForeignFollowers)
                return iForeignFollowers
            end
        end
        return 0
    end

--统计模块->玩家本土信徒数量（总信徒减去外国信徒）
    function FROM_RELIGION_DOMESTIC_FOLLOWERS(playerID)
        local total = FROM_RELIGION_TOTAL_FOLLOWERS(playerID)
        local foreign = FROM_RELIGION_FOREIGN_FOLLOWERS(playerID)
        local domestic = total - foreign
        --print("玩家本土信徒数量：", domestic)
        return domestic
    end

--统计模块->信奉玩家宗教的总城市数量
    function FROM_RELIGION_TOTAL_CITIES_FOLLOWING(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pStats:table = pPlayer:GetStats()
        if pStats then
            local pReligion = pPlayer:GetReligion()
            if pReligion then
                local iTotalCities = pStats:GetNumCitiesFollowingReligion() or 0
                --print("信奉玩家宗教的总城市数量：", iTotalCities)
                return iTotalCities
            end
        end
        return 0
    end

--统计模块->信奉玩家宗教且拥有奇观的城市数量
    function FROM_RELIGION_CITIES_WITH_WONDER(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pStats:table = pPlayer:GetStats()
        if pStats then
            local pReligion = pPlayer:GetReligion()
            if pReligion then
                local iCitiesWithWonder = pStats:GetNumCitiesFollowingReligionWithWonder() or 0
                --print("信奉玩家宗教，且有奇观的城市数量：", iCitiesWithWonder)
                return iCitiesWithWonder
            end
        end
        return 0
    end

--统计模块->信奉玩家宗教的外国城市数量
    function FROM_RELIGION_FOREIGN_CITIES(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return 0 end

        local pStats:table = pPlayer:GetStats()
        if pStats then
            local pReligion = pPlayer:GetReligion()
            if pReligion then
                local iForeignCities = pStats:GetNumForeignCitiesFollowingReligion() or 0
                --print("信奉玩家宗教的外国城市数量：", iForeignCities)
                return iForeignCities
            end
        end
        return 0
    end

--统计模块->信奉玩家宗教的国内城市数量（总城市数减去外国城市数）
    function FROM_RELIGION_DOMESTIC_CITIES(playerID)
        local totalCities = FROM_RELIGION_TOTAL_CITIES_FOLLOWING(playerID)
        local foreignCities = FROM_RELIGION_FOREIGN_CITIES(playerID)
        local domesticCities = totalCities - foreignCities
        --print("信奉玩家宗教的国内城市数量：", domesticCities)
        return domesticCities
    end

--统计模块->本城信仰玩家（拥有者）宗教的信徒
    function FROM_RELIGION_CITY_PLAYER_FOLLOWERS(playerID, iX, iY)
        --print("-==============================")

        local pPlayer = Players[playerID];
        if not pPlayer then
            --print("无法获取玩家数据")
            return 0
        end

        local iReligionType = -1;
        local pReligion = pPlayer:GetReligion();
        if pReligion then
            iReligionType = pReligion:GetReligionTypeCreated();
            if iReligionType ~= -1 then
                --print("玩家创建的宗教为：", GameInfo.Religions[iReligionType].ReligionType)
            else
                --print("玩家没有创建宗教")
            end
        else
            --print("玩家没有宗教数据")
        end

        local Plot = Map.GetPlot(iX, iY);
        local City = Cities.GetPlotPurchaseCity(Plot);
        if not City then
            --print("无法获取对应的城市")
            return 0
        end

        --print("城市名称：", City:GetName());
        local CityReligion = City:GetReligion();
        if not CityReligion then
            --print("该城市没有宗教数据")
            return 0
        end

        local Count = 0;
        if iReligionType ~= -1 then
            -- 统计该城市中信仰玩家创建的宗教的信徒数量
            Count = CityReligion:GetNumFollowers(iReligionType);
            --print("本城信仰玩家宗教的信徒数量：", Count);
        else
            --print("玩家没有创建宗教，因此无法统计对应的信徒")
        end

        --print("-==============================")
        return Count;
    end
--============================================================================================================================


--区域属性
--============================================================================================================================
--统计模块->自己的相邻加成:食物产出
    function FROM_SELF_YIELD_FOOD(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0

        local City = Cities.GetPlotPurchaseCity(Plot);
        --print("城市名称：", City:GetName());

        local DistrictID = Plot:GetDistrictID();
        local Districts = City:GetDistricts();
        local District = Districts:GetDistrictByID(DistrictID);

        local index = GameInfo.Yields['YIELD_FOOD'].Index
        local Yield_Food = District:GetYield(index);

        Count = Yield_Food;
        --print("此区域食物产出：", Count);
        --print("-==============================")
        
        return Count;
    end

--统计模块->自己的相邻加成:锤子产出
    function FROM_SELF_YIELD_PRODUCTION(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0

        local City = Cities.GetPlotPurchaseCity(Plot);
        --print("城市名称：", City:GetName());

        local DistrictID = Plot:GetDistrictID();
        local Districts = City:GetDistricts();
        local District = Districts:GetDistrictByID(DistrictID);

        local index = GameInfo.Yields['YIELD_PRODUCTION'].Index
        local Yield_Production = District:GetYield(index);

        Count = Yield_Production;
        --print("此区域生产产出：", Count);
        --print("-==============================")
        
        return Count;
    end

--统计模块->自己的相邻加成:金币产出
    function FROM_SELF_YIELD_GOLD(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0

        local City = Cities.GetPlotPurchaseCity(Plot);
        --print("城市名称：", City:GetName());

        local DistrictID = Plot:GetDistrictID();
        local Districts = City:GetDistricts();
        local District = Districts:GetDistrictByID(DistrictID);

        local index = GameInfo.Yields['YIELD_GOLD'].Index
        local Yield_Gold = District:GetYield(index);

        Count = Yield_Gold;
        --print("此区域黄金产出：", Count);
        --print("-==============================")
        
        return Count;
    end

--统计模块->自己的相邻加成:科技产出
    function FROM_SELF_YIELD_SCIENCE(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0

        local City = Cities.GetPlotPurchaseCity(Plot);
        --print("城市名称：", City:GetName());

        local DistrictID = Plot:GetDistrictID();
        local Districts = City:GetDistricts();
        local District = Districts:GetDistrictByID(DistrictID);

        local index = GameInfo.Yields['YIELD_SCIENCE'].Index
        local Yield_Science = District:GetYield(index);

        Count = Yield_Science;
        --print("此区域科学产出：", Count);
        --print("-==============================")
        
        return Count;
    end

--统计模块->自己的相邻加成:文化产出
    function FROM_SELF_YIELD_CULTURE(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0

        local City = Cities.GetPlotPurchaseCity(Plot);
        --print("城市名称：", City:GetName());

        local DistrictID = Plot:GetDistrictID();
        local Districts = City:GetDistricts();
        local District = Districts:GetDistrictByID(DistrictID);

        local index = GameInfo.Yields['YIELD_CULTURE'].Index
        local Yield_Culture = District:GetYield(index);

        Count = Yield_Culture;
        --print("此区域文化产出：", Count);
        --print("-==============================")
        
        return Count;
    end

--统计模块->自己的相邻加成:信仰值
    function FROM_SELF_YIELD_FAITH(iX, iY)
        --print("-==============================")
        local Plot = Map.GetPlot(iX, iY);
        local Count = 0

        local City = Cities.GetPlotPurchaseCity(Plot);
        --print("城市名称：", City:GetName());

        local DistrictID = Plot:GetDistrictID();
        local Districts = City:GetDistricts();
        local District = Districts:GetDistrictByID(DistrictID);

        local index = GameInfo.Yields['YIELD_FAITH'].Index
        local Yield_Faith = District:GetYield(index);

        Count = Yield_Faith;
        --print("此区域信仰值产出：", Count);
        --print("-==============================")
        
        return Count;
    end
--============================================================================================================================




--============================================================================================================================
--小工具函数：判断table里有没有对应的值
    function contains(t, value)
        for _, v in ipairs(t) do
            if v == value then return true end
        end
        return false
    end
--============================================================================================================================
--直接缓存相邻加成表--二级缓存：按区域分类
    Ruivo_Adjacency_Cache = {byDistrict = {}}
--============================================================================================================================
--模块化相邻加成的显示部分
    function Ruivo_ExtraAdjacentYieldBonusString(eDistrict, pkCity, plot, iconString, tooltipText, Yield_Table)
        local targetDistrictType = GameInfo.Districts[eDistrict].DistrictType --获取目标区域
        local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {} --获取目标区域的模块化相邻加成
        
        --===========================================
        --产出加成表
        local DirectBonusTypes = {
            SelfExtraDistrictSlot = true,
            SelfTradeRoute      = true,
            SelfTourism         = true,
            SelfPower           = true,
            SelfAmenity         = true,
            SelfHousing         = true,
            SelfLoyalty         = true,
            SelfInfluence       = true,
            SelfFavor           = true,
            SelfBonus           = true,
            GreatPersonPoints   = true,
            SelfExtractResource = true,
            TriggerFunction     = true
        }
        --系数加成表
        local MultiplierTypes = {
            SelfPowerModifier       = true,
            SelfMultiplier          = true,
            GreatPersonMultiplier   = true
        }
        --显示的产出顺序
        local yieldOrder = {
            "YIELD_DISTRICT_SLOT",
            "YIELD_TRADE_ROUTE",
            "YIELD_HOUSING",
            "YIELD_AMENITY",
            "YIELD_LOYALTY",
            "YIELD_INFLUENCE",
            "YIELD_FAVOR",
            "YIELD_TOURISM",
            "YIELD_POWER",
            "YIELD_FOOD",
            "YIELD_PRODUCTION",
            "YIELD_SCIENCE",
            "YIELD_CULTURE",
            "YIELD_GOLD",
            "YIELD_FAITH"
        }
        --最终显示列表的数据部分
        local LatitudeRating = false
        local TotalBonus:table = {
            YIELD_FOOD       = 0, MULTIPLIER_YIELD_FOOD       = 0,
            YIELD_PRODUCTION = 0, MULTIPLIER_YIELD_PRODUCTION = 0,
            YIELD_GOLD       = 0, MULTIPLIER_YIELD_GOLD       = 0,
            YIELD_SCIENCE    = 0, MULTIPLIER_YIELD_SCIENCE    = 0,
            YIELD_CULTURE    = 0, MULTIPLIER_YIELD_CULTURE    = 0,
            YIELD_FAITH      = 0, MULTIPLIER_YIELD_FAITH      = 0,
            YIELD_POWER      = 0, MULTIPLIER_YIELD_POWER      = 0, 
            YIELD_AMENITY    = 0, 
            YIELD_HOUSING    = 0,
            YIELD_LOYALTY    = 0,
            YIELD_TOURISM    = 0,
            YIELD_INFLUENCE  = 0,
            YIELD_FAVOR      = 0,
            YIELD_TRADE_ROUTE= 0,
            YIELD_DISTRICT_SLOT = 0
            }
        -- 插入所有伟人的显示类型
        for row in GameInfo.GreatPersonClasses() do
            TotalBonus[row.GreatPersonClassType] = 0
            TotalBonus['MULTIPLIER_' .. row.GreatPersonClassType] = 0
            table.insert(yieldOrder, row.GreatPersonClassType)
        end
        -- 插入所有自定义的显示类型
        for row in GameInfo.Ruivo_Yield_IconString() do
            TotalBonus[row.YieldType] = 0
            table.insert(yieldOrder, row.YieldType)
        end
        --原版相邻加成部分先合并入最终显示表中
        for key, value in pairs(Yield_Table) do
            --print(key, value)
            TotalBonus[key] = value;
        end
        --===========================================

        --===========================================
        --仅遍历该区域类型的行
        for _, row in ipairs(cachedEntries) do
            -- 获取玩家信息
            local playerID = pkCity:GetOwner()
            local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
            local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()
            
            -- 判断模块
            local CanDisplay = CanDisplayModule(row, CivilizationType, LeaderType, playerID, pkCity)

            -- 同时满足区域类型和特质要求
            if CanDisplay then

                --如果有经纬度判断，则再加一行
                if row.AdjacencyType == 'FROM_LATITUDE' or row.AdjacencyType == 'FROM_POLE' then
                    LatitudeRating = true;
                end

                --如果是非触发函数的自由组装模式，则不显示
                if not (row.FreeCompose and row.ProvideType ~= "TriggerFunction") then
                    -- 计算加成数值
                    local iX, iY = plot:GetX(), plot:GetY()
                    local iBonus = StatsModule_For_Display(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pkCity, row.Rings)
                    local AdjacentSubjectNum = iBonus --缓存相邻对象数量
                    iBonus = math.floor(math.max(iBonus * row.YieldChange, 0)) --不能为负数
                    iBonus = math.min(iBonus, maxNum)

                    --更新总加成表
                    local yieldType = row.YieldType
                    local ProvideType = row.ProvideType
                    if TotalBonus[yieldType] ~= nil then
                        if DirectBonusTypes[row.ProvideType] then
                            TotalBonus[yieldType] = TotalBonus[yieldType] + iBonus
                        elseif MultiplierTypes[row.ProvideType] then
                            TotalBonus["MULTIPLIER_"..yieldType] = TotalBonus["MULTIPLIER_"..yieldType] + iBonus
                        end

                    --对于资源的产出进行特殊的处理
                    elseif row.ProvideType == 'SelfExtractResource' then
                        local resourceType = row.YieldType
                        --如果原表中没有，则添加到显示的产出顺序
                        if not contains(yieldOrder, resourceType) then
                            table.insert(yieldOrder, resourceType)
                        end
                        --lua支持拓展表的键值对
                        if resourceType then
                            TotalBonus[resourceType] = (TotalBonus[resourceType] or 0) + iBonus
                            --print(resourceType, TotalBonus[resourceType])
                        end                        
                    end
 
                    --非零时添加tooltip
                    if iBonus ~= 0 then
                        --提供相邻加成已弃用，只有自己的相邻加成
                        if row.ProvideType ~= 'ProvideToADJ' then
                            local numText = tostring(iBonus)
                            local yieldIcon = RUIVO_GetYieldTextIcon(yieldType)..RUIVO_GetYieldText(yieldType, ProvideType)
                            local customAdjObj = row.CustomAdjacentObject
                            local newAdjTextRow = GameInfo.Ruivo_New_Adjacency_Text[row.ID]

                            -- tooltipText 非空时先换行
                            if tooltipText ~= "" then
                                tooltipText = tooltipText .. "[NEWLINE]"
                            end

                            -- 系数加百分号
                            if MultiplierTypes[row.ProvideType] then
                                numText = numText .. "%"
                            end

                            -- 默认文本
                            local text = Locale.Lookup(
                                "LOC_RUIVO_" .. row.AdjacencyType,
                                numText, yieldIcon, AdjacentSubjectNum
                            )

                            -- 如果有指定的相邻对象
                            if customAdjObj ~= 'NONE' then
                                text = Locale.Lookup(
                                    "LOC_RUIVO_" .. row.AdjacencyType,
                                    numText, yieldIcon, AdjacentSubjectNum, RUIVO_GetCAOName(customAdjObj)
                                )
                            end

                            -- 自定义文本
                            if newAdjTextRow then
                                text = Locale.Lookup(
                                    newAdjTextRow.Tooltip,
                                    numText, yieldIcon, AdjacentSubjectNum, RUIVO_GetCAOName(customAdjObj)
                                )
                            end

                            -- 拼接主体文本
                            tooltipText = tooltipText .. text

                            -- 环数
                            if row.Rings > 1 then
                                tooltipText = tooltipText .. " (" .. Locale.Lookup("LOC_RUIVO_RINGS", row.Rings) .. ")"
                            end

                            -- Modifier 来源
                            if row.TraitType then
                                local traitInfo = GameInfo.Traits[row.TraitType]
                                if traitInfo and traitInfo.Name then
                                    tooltipText = tooltipText .. " (" .. Locale.Lookup(traitInfo.Name) .. ")"
                                end
                            end

                            -- 附加拥有者信息
                            if row.WhoIsTheOwner then
                                tooltipText = RUIVO_AppendOwnerInfo(tooltipText, row.WhoIsTheOwner)
                            end
                        end
                    end


                end
            end
        end
        --===========================================

        --显示赤道和两极靠近比例
        if LatitudeRating then 
            local iX, iY = plot:GetX(), plot:GetY()
            local FROM_LATITUDE = FROM_LATITUDE(iX, iY)
            local FROM_POLE = FROM_POLE(iX, iY)
            local rating = 0

            if iconString ~= "" then iconString = iconString .. "[NEWLINE]" end --非空换行
            iconString = iconString .. "[ICON_GLOBAL]"

            --根据正负和比例来变颜色
            if FROM_LATITUDE == 0 and FROM_POLE == 0 then 
                rating = 0
                iconString = iconString .. "[COLOR:171,255,0,255]+"
            elseif FROM_LATITUDE ~= 0 and FROM_POLE == 0 then 
                rating = FROM_LATITUDE

                if      0 < rating and rating <= 10  then iconString = iconString .. "[COLOR:171,255,0,255]+" 
                elseif 10 < rating and rating <= 40  then iconString = iconString .. "[COLOR:255,253,0,255]+" 
                elseif 40 < rating and rating <= 70  then iconString = iconString .. "[COLOR:255,169,0,255]+" 
                elseif 70 < rating and rating <= 100 then iconString = iconString .. "[COLOR:255,85,0,255]+" 
                end
            elseif FROM_LATITUDE == 0 and FROM_POLE ~= 0 then 
                rating = FROM_POLE

                if      0 < rating and rating <= 10  then iconString = iconString .. "[COLOR:171,255,0,255]-" 
                elseif 10 < rating and rating <= 40  then iconString = iconString .. "[COLOR:0,255,255,255]-" 
                elseif 40 < rating and rating <= 70  then iconString = iconString .. "[COLOR:102,204,255,255]-" 
                elseif 70 < rating and rating <= 100 then iconString = iconString .. "[COLOR:224,235,255,255]-" 
                end
            end

            rating = math.floor(rating);
            iconString = iconString .. rating .. "%[ENDCOLOR]"
        end

        --组合文本
        for _, yieldType in ipairs(yieldOrder) do
            local base = TotalBonus[yieldType]
            --print(yieldType, base)
            local multiplier = TotalBonus["MULTIPLIER_"..yieldType] or 0
            
            if base ~= 0 or multiplier ~= 0 then
                --图标字符串
                local line = RUIVO_GetYieldTextColor(yieldType)
                if base ~= 0 then
                    line = line .. RUIVO_GetYieldString(yieldType, base)
                end
                if multiplier ~= 0 then
                    if base ~= 0 then line = line .. " " end
                    line = line .. RUIVO_GetYieldTextIcon(yieldType).."+"..multiplier.."%"
                end
                iconString = iconString .. (iconString == "" and "" or "[NEWLINE]") .. line .. "[ENDCOLOR]"
            end
        end

        return iconString, tooltipText
    end
--============================================================================================================================



--============================================================================================================================
--初始化
    function STAT_Initialize()
        -- 清空旧缓存
        Ruivo_Adjacency_Cache.byDistrict = {}

        -- 预先生成区域类型索引
        for row in GameInfo.Ruivo_New_Adjacency() do
            if true then
                local districtType = row.DistrictType
                
                -- 初始化区域类型子表
                if not Ruivo_Adjacency_Cache.byDistrict[districtType] then
                    Ruivo_Adjacency_Cache.byDistrict[districtType] = {}
                end
                
                -- 结构化存储
                table.insert(Ruivo_Adjacency_Cache.byDistrict[districtType], {
                    ID                  = row.ID,
                    DistrictType        = row.DistrictType,
                    ProvideType         = row.ProvideType,
                    YieldType           = row.YieldType,
                    YieldChange         = row.YieldChange,
                    AdjacencyType       = row.AdjacencyType,
                    CustomAdjacentObject= row.CustomAdjacentObject,
                    Rings               = row.Rings,
                    DistrictModifiers   = row.DistrictModifiers,
                    TraitType           = row.TraitType or false,
                    ModifierOwner       = row.ModifierOwner,
                    WhoIsTheOwner       = row.WhoIsTheOwner or false,
                    CollectionType      = row.CollectionType,
                    Only                = row.Only,
                    FreeCompose         = row.FreeCompose
                })
            end
        end

        --游戏中的顶级幸福度的宜居度
        for row in GameInfo.Happinesses() do
            if row.MinimumAmenityScore then
                if row.MinimumAmenityScore > HIGHEST_LEVEL_HAPPINESS then
                    HIGHEST_LEVEL_HAPPINESS = row.MinimumAmenityScore
                end
            end
        end

    --============================================================================================================================
    --地形地貌改良资源单位建筑区域缓存表
        --地形
        do
            for row in GameInfo.Terrains() do
                TerrainTypeMap[row.Index] = row.TerrainType;
            end
        end
        --地貌
        do
            for row in GameInfo.Features() do
                FeatureTypeMap[row.Index] = row.FeatureType;
            end
        end
        --改良
        do
            for row in GameInfo.Improvements() do
                ImprovementTypeMap[row.Index] = row.ImprovementType;
            end
        end
        --资源
        do
            for row in GameInfo.Resources() do
                ResourceTypeMap[row.Index] = row.ResourceType;
            end
        end
        --单位
        do
            for row in GameInfo.Units() do
                UnitTypeMap[row.Index] = row.UnitType;
            end
        end
        --建筑（奇观）
        do
            for row in GameInfo.Buildings() do
                BuildingTypeMap[row.Index] = row.BuildingType;
            end
        end
        --区域
        do
            for row in GameInfo.Districts() do
                DistrictTypeMap[row.Index] = row.DistrictType;
            end
        end
    --缓存 tag->资源类型 对照表
        for row in GameInfo.TypeTags() do
            if TypeTagsMap[row.Tag] == nil then
                TypeTagsMap[row.Tag] = {}   -- 初始化
            end
            TypeTagsMap[row.Tag][row.Type] = true
        end
    --============================================================================================================================
    end
    Events.LoadGameViewStateDone.Add(STAT_Initialize);
--============================================================================================================================
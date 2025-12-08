include("RUIVO_STAT_MODULE_GP.lua");

--============================================================================================================================
-- SetProperty事件函数
    function RuivoADJBonusSetProperty(playerID, kPara)
        local iX, iY = kPara.iX, kPara.iY
        local iBonus = kPara.iBonus
        local YieldChange = kPara.YieldChange
        local ID = kPara.ID

        Ruivo_Zip_SetProperty(ID, iBonus, YieldChange, iX, iY)
    end
    GameEvents.RuivoADJBonusSetProperty.Add(RuivoADJBonusSetProperty)

-- SetProperty部分--二进制折叠--全局参数在"RUIVO_STAT_MODULE_GP.lua"文件里
    function Ruivo_Zip_SetProperty(ID, iBonus, YieldChange, iX, iY)
        local pPlot = Map.GetPlot(iX, iY)

        -- 记录总数
        local TotalKey = ID .. '_TOTAL'

        --如果当前值与要set的值相同则跳过
        local current = pPlot:GetProperty(TotalKey) or 0
        if current == iBonus then return end

        pPlot:SetProperty(TotalKey, iBonus)
        --print(TotalKey, tostring(pPlot:GetProperty(TotalKey))) -- 输出检查

        -- 计算实际总数
        local ActualAmountKey = ID .. '_ACTUAL_AMOUNT'
        local ActualAmount = iBonus * YieldChange
        ActualAmount = math.floor(ActualAmount) -- 确保是整数
        pPlot:SetProperty(ActualAmountKey, ActualAmount)
        --print(ActualAmountKey, tostring(pPlot:GetProperty(ActualAmountKey))) -- 输出检查

        -- 防止超出压缩表上限
        ActualAmount = math.min(ActualAmount, maxNum);

        --测试信息
        --Game.AddWorldViewText(0, ID .. '对应数量：' .. iBonus .. '总量：' .. ActualAmount, iX, iY)

        -- 初始化结果列表，默认全为 0
        local resultList = {};
        for _ = 1, #Ruivo_BinaryList do table.insert(resultList, 0) end

        -- 按照 Ruivo_BinaryList 进行二进制折叠
        for i = #Ruivo_BinaryList, 1, -1 do
            if ActualAmount >= Ruivo_BinaryList[i] then
                resultList[i] = 1;
                ActualAmount = ActualAmount - Ruivo_BinaryList[i];
            end
        end

        for i = 1, #Ruivo_BinaryList do
            -- Property的键值由modifier的ID和二进制数组合而成
            local PropertyKey = ID .. '_' .. Ruivo_BinaryList[i];
            pPlot:SetProperty(PropertyKey, resultList[i]);
            -- 通过游戏内 get 方法输出，看看有没有正确地存入 property 里
            --local retrievedValue = pPlot:GetProperty(PropertyKey);
            --print(PropertyKey, tostring(retrievedValue));
        end
    end
--============================================================================================================================


--其实我把刷新函数内置了，因为沟槽的参数传递问题
--============================================================================================================================
--SetProperty刷新核心函数--整合的刷新全部玩家
    function Ruivo_Refresh_Core()
        local kPlayers = PlayerManager.GetAliveMajors()

        --遍历所有玩家，并且只会遍历 活着的 主流文明 的玩家，不包括城邦和蛮子
        for _, pPlayer in ipairs(kPlayers) do
            local playerID = pPlayer:GetID()
            local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName();
            local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName();
            local cities = pPlayer:GetCities(); -- 获取玩家所有城市

            --=================================================================================
            --遍历所有城市
                for indexKey, pCity in cities:Members() do
                    --遍历所有区域
                    local CityDistricts = pCity:GetDistricts();
                    local DistrictsNum = CityDistricts:GetNumDistricts();
                    local DistrictsIndex = DistrictsNum - 1;
                    for DistrictIndex = 0, DistrictsIndex do
                        local district = CityDistricts:GetDistrictByIndex(DistrictIndex);
                        --区域建成
                        if district ~= nil and district:IsComplete() then
                            local iDistrictType = district:GetType();
                            local districtPlot = Map.GetPlot(district:GetX(), district:GetY());
                            local iX = districtPlot:GetX();
                            local iY = districtPlot:GetY();
                            local targetDistrictType = GameInfo.Districts[iDistrictType].DistrictType --获取目标区域
                            
                            local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {} --获取目标区域的模块化相邻加成
                            --遍历此区域对应的相邻加成
                            for _, row in ipairs(cachedEntries) do
                                -- 判断模块
                                local CanDisplay = CanDisplayModule(row, CivilizationType, LeaderType, playerID, pCity)
                                --开始统计
                                if CanDisplay then
                                    local iBonus = StatsModule_For_GP(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                                    if iBonus >= 0 then
                                        Ruivo_Zip_SetProperty(row.ID, iBonus, row.YieldChange, iX, iY)
                                    end
                                end
                            end
                        end

                    end
                end
            --=================================================================================

        end
    
    end

--遍历所有主流存活文明玩家
    function Ruivo_All_Players()
        local kPlayers = PlayerManager.GetAliveMajors()
        --遍历所有玩家，并且只会遍历 活着的 主流文明 的玩家，不包括城邦和蛮子
        for _, pPlayer in ipairs(kPlayers) do
            local playerID = pPlayer:GetID()
            Ruivo_Single_Player(playerID)
        end
    end

--遍历一个玩家的所有城市
    function Ruivo_Single_Player(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer then return end

        local cities = pPlayer:GetCities()
        if not cities then return end

        --遍历城市
        for _, pCity in cities:Members() do
            if pCity then
                Ruivo_Single_City(pCity)
            end
        end
    end

--遍历一个城市的所有区域
    function Ruivo_Single_City(pCity)
        if not pCity then return end

        local CityDistricts = pCity:GetDistricts()
        if not CityDistricts then return end

        --GP的遍历区域法
        local DistrictsNum = CityDistricts:GetNumDistricts()
        for DistrictIndex = 0, DistrictsNum - 1 do
            local district = CityDistricts:GetDistrictByIndex(DistrictIndex)
            if district then
                Ruivo_Single_District(district)
            end
        end
    end

--单个区域处理相邻加成
    function Ruivo_Single_District(district)
        if district and district:IsComplete() then
            local iDistrictType = district:GetType()
            local districtPlot = Map.GetPlot(district:GetX(), district:GetY())

            --防御性编程
            if districtPlot and GameInfo.Districts[iDistrictType] then
                local iX = districtPlot:GetX()
                local iY = districtPlot:GetY()
                local targetDistrictType = GameInfo.Districts[iDistrictType].DistrictType

                --显示文本
                --Game.AddWorldViewText(0, Locale.Lookup(GameInfo.Districts[iDistrictType].Name), iX, iY)

                -- 获取附属信息
                local playerID = district:GetOwner()
                local pCity = Cities.GetPlotPurchaseCity(districtPlot)
                if not pCity then return end
                local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
                local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()

                --获取模块化加成缓存
                --遍历本区域对应的相邻加成
                local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {}
                for _, row in ipairs(cachedEntries) do
                    local CanDisplay = CanDisplayModule(row, CivilizationType, LeaderType, playerID, pCity)
                    if CanDisplay then
                        local iBonus = StatsModule_For_GP(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                        if iBonus >= 0 then
                            Ruivo_Zip_SetProperty(row.ID, iBonus, row.YieldChange, iX, iY)
                        end
                    end
                end


            end
        end
    end
--============================================================================================================================



--============================================================================================================================
-- ================= 区域进度改变事件，100时视为建成 =================
--因为区域建成事件必然触发2次，所以使用开关法
    DistrictCompletedSwitch = false
    function Ruivo_Refresh_OnDistrictCompleted(playerID, districtID, cityID, iX, iY, districtType, era, civilization, iPercentComplete, iAppeal, isPillaged)
        --建成时刷新
        if iPercentComplete == 100 then


            --因为区域建成事件必然触发2次所以使用开关法
            if DistrictCompletedSwitch then
                DistrictCompletedSwitch = false
                return
            end
            DistrictCompletedSwitch = true


            --开始对区域进行那个啥
            if districtType and iX and iY then
                local plot = Map.GetPlot(iX, iY)
                if plot then
                    local district = CityManager.GetDistrictAt(plot)
                    if district then


                        
                    --============================================================================================================================
                    --我把函数体塞进来了
                            if district and district:IsComplete() then
                                local iDistrictType = district:GetType()
                                local districtPlot = Map.GetPlot(district:GetX(), district:GetY())

                                --防御性编程
                                if districtPlot and GameInfo.Districts[iDistrictType] then
                                    local iX = districtPlot:GetX()
                                    local iY = districtPlot:GetY()
                                    local targetDistrictType = GameInfo.Districts[iDistrictType].DistrictType

                                    --显示文本
                                    --Game.AddWorldViewText(0, Locale.Lookup(GameInfo.Districts[iDistrictType].Name), iX, iY)

                                    -- 获取附属信息
                                    local playerID = district:GetOwner()
                                    local pCity = Cities.GetPlotPurchaseCity(districtPlot)
                                    if not pCity then return end
                                    local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
                                    local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()

                                    --获取模块化加成缓存
                                    --遍历本区域对应的相邻加成
                                    local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {}
                                    for _, row in ipairs(cachedEntries) do
                                        local CanDisplay = CanDisplayModule(row, CivilizationType, LeaderType, playerID, pCity)
                                        if CanDisplay then
                                            local iBonus = StatsModule_For_GP(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                                            if iBonus >= 0 then
                                                Ruivo_Zip_SetProperty(row.ID, iBonus, row.YieldChange, iX, iY)
                                            end
                                        end
                                    end


                                end
                            end
                    --============================================================================================================================


                    
                    end
                end
            end



        end
    end
--============================================================================================================================


--============================================================================================================================
-- ================= 玩家回合开始事件 =================
    function Ruivo_Refresh_OnPlayerTurnActivated(playerID, bIsFirstTime)
        --只触发一次
        if not bIsFirstTime then return end
        Ruivo_Single_Player(playerID)
    end
--============================================================================================================================


--============================================================================================================================
--记录本局风暴次数
    function OnRandomEventOccurred(type:number, severity:number, plotx:number, ploty:number, mitigationLevel:number, randomEventID:number, gameCorePlaybackEventID:number)		
        local info:table = GameInfo.RandomEvents[type];
        if info.EffectOperatorType == 'STORM' then
            local stormTimes = Game:GetProperty("PROPERTY_RUIVO_STORM_TIMES") or 0
            stormTimes = stormTimes + 1
            Game:SetProperty("PROPERTY_RUIVO_STORM_TIMES", stormTimes)
            --Game.AddWorldViewText(0, "本局风暴发生次数："..Game:GetProperty("PROPERTY_RUIVO_STORM_TIMES"), plotx, ploty)
        end
    end
--============================================================================================================================



--============================================================================================================================
--初始化函数
    function Initialize()
        -- ================= 事件注册集中区 =================
        Events.DistrictBuildProgressChanged.Add(Ruivo_Refresh_OnDistrictCompleted)
        --Events.TurnEnd.Add(Ruivo_Refresh_Core)
        Events.PlayerTurnActivated.Add(Ruivo_Refresh_OnPlayerTurnActivated);
        --给风暴灾难用的
        Events.RandomEventOccurred.Add(OnRandomEventOccurred);
        -- ================= 事件注册集中区 =================
    end
--初始化
    Events.LoadGameViewStateDone.Add(Initialize);
--============================================================================================================================
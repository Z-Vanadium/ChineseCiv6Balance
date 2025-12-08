include("RUIVO_STAT_MODULE_GP.lua");


--其实我把刷新函数内置了，因为沟槽的参数传递问题
--============================================================================================================================
--SetProperty刷新核心函数
    function Ruivo_Refresh_Core(playerID)
        local pPlayer = Players[playerID];
        local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName();
        local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName();
        local cities = pPlayer:GetCities(); -- 获取玩家所有城市

        --=================================================================================
        --不能给野蛮人和自由城市SetProperty
            --print(CivilizationType);
            --print(LeaderType);
            if CivilizationType == 'CIVILIZATION_FREE_CITIES' or CivilizationType == 'CIVILIZATION_BARBARIAN' then
                --print("是野蛮人或者自由城市");
                return;
            end
        --=================================================================================

        --=================================================================================
        --遍历所有城市
            for indexKey, pCity in cities:Members() do
                --遍历所有区域
                local CityDistricts = pCity:GetDistricts();
                for i,district in CityDistricts:Members() do
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
                                local iBonus = StatsModule_For_UI(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                                if iBonus >= 0 then
                                    local kPara = {}
                                    kPara.iX = iX
                                    kPara.iY = iY
                                    kPara.ID = row.ID
                                    kPara.iBonus = iBonus
                                    kPara.YieldChange = row.YieldChange
                                    kPara.OnStart = 'RuivoADJBonusSetProperty'
                                    UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, kPara)
                                end
                            end
                        end
                    end

                end
            end
        --=================================================================================

    end
--单个区域
    function Ruivo_Single_District_UI(district)
        if district and district:IsComplete() then
            local iDistrictType = district:GetType()
            local iX, iY = district:GetX(), district:GetY()
            local districtPlot = Map.GetPlot(iX, iY)

            if districtPlot and GameInfo.Districts[iDistrictType] then
                local districtRow = GameInfo.Districts[iDistrictType]
                local targetDistrictType = districtRow.DistrictType

                -- 显示区域名称（调试用途）
                --UI.AddWorldViewText(0, "UI端:"..Locale.Lookup(districtRow.Name), iX, iY)

                local playerID = district:GetOwner()
                local pCity = Cities.GetPlotPurchaseCity(districtPlot)
                if not pCity then return end

                local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
                local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()

                -- 获取缓存的相邻加成规则
                local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {}
                for _, row in ipairs(cachedEntries) do
                    local CanDisplay = CanDisplayModule(row, CivilizationType, LeaderType, playerID, pCity)
                    if CanDisplay then
                        local iBonus = StatsModule_For_UI(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                        if iBonus >= 0 then
                            local kPara = {
                                iX = iX,
                                iY = iY,
                                ID = row.ID,
                                iBonus = iBonus,
                                YieldChange = row.YieldChange,
                                OnStart = 'RuivoADJBonusSetProperty'
                            }
                            UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, kPara)
                        end
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

        local pPlayer = Players[playerID];
        local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName();
        local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName();
        local cities = pPlayer:GetCities(); -- 获取玩家所有城市

        --=================================================================================
        --不能给野蛮人和自由城市SetProperty
            --print(CivilizationType);
            --print(LeaderType);
            if CivilizationType == 'CIVILIZATION_FREE_CITIES' or CivilizationType == 'CIVILIZATION_BARBARIAN' then
                --print("是野蛮人或者自由城市");
                return;
            end
        --=================================================================================

        --=================================================================================
        --遍历所有城市
            for indexKey, pCity in cities:Members() do
                --遍历所有区域
                local CityDistricts = pCity:GetDistricts();
                for i,district in CityDistricts:Members() do
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
                                local iBonus = StatsModule_For_UI(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                                if iBonus >= 0 then
                                    local kPara = {}
                                    kPara.iX = iX
                                    kPara.iY = iY
                                    kPara.ID = row.ID
                                    kPara.iBonus = iBonus
                                    kPara.YieldChange = row.YieldChange
                                    kPara.OnStart = 'RuivoADJBonusSetProperty'
                                    UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, kPara)
                                end
                            end
                        end
                    end

                end
            end
        --=================================================================================


    end
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
                                local iX, iY = district:GetX(), district:GetY()
                                local districtPlot = Map.GetPlot(iX, iY)

                                if districtPlot and GameInfo.Districts[iDistrictType] then
                                    local districtRow = GameInfo.Districts[iDistrictType]
                                    local targetDistrictType = districtRow.DistrictType

                                    -- 显示区域名称（调试用途）
                                    --UI.AddWorldViewText(0, "UI端:"..Locale.Lookup(districtRow.Name), iX, iY)

                                    local playerID = district:GetOwner()
                                    local pCity = Cities.GetPlotPurchaseCity(districtPlot)
                                    if not pCity then return end

                                    local CivilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
                                    local LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()

                                    -- 获取缓存的相邻加成规则
                                    local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {}
                                    for _, row in ipairs(cachedEntries) do
                                        local CanDisplay = CanDisplayModule(row, CivilizationType, LeaderType, playerID, pCity)
                                        if CanDisplay then
                                            local iBonus = StatsModule_For_UI(row.AdjacencyType, row.CustomAdjacentObject, iX, iY, playerID, pCity, row.Rings)
                                            if iBonus >= 0 then
                                                local kPara = {
                                                    iX = iX,
                                                    iY = iY,
                                                    ID = row.ID,
                                                    iBonus = iBonus,
                                                    YieldChange = row.YieldChange,
                                                    OnStart = 'RuivoADJBonusSetProperty'
                                                }
                                                UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, kPara)
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
--初始化函数，事件和缓存都在这里
    function Initialize()
        -- ================= 事件注册集中区 =================
        Events.DistrictBuildProgressChanged.Add(Ruivo_Refresh_OnDistrictCompleted)
        Events.PlayerTurnActivated.Add(Ruivo_Refresh_OnPlayerTurnActivated);
        -- ================= 事件注册集中区 =================
    end
--初始化
    Events.LoadGameViewStateDone.Add(Initialize);
--============================================================================================================================
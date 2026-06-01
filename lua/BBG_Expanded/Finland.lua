--==========================================================================================================================
-- Finland Functions - CCB
-- Description: When losing a city, all cities gain +5% all yields (max +20%) and all units gain +1 combat strength (max +4)
--==========================================================================================================================
-- INCLUDES
--==========================================================================================================================
include("Civ6Common.lua")
--==========================================================================================================================
-- UTILITY FUNCTIONS
--==========================================================================================================================
--==========================================================================================================================
-- CORE FUNCTIONS
--==========================================================================================================================
local iMaxLostCityBonus = 4
local sLostCityCountKey = "CCB_FINLAND_LOST_CITY_COUNT"

function OnCityConquered(newPlayerID, oldPlayerID, newCityID, cityX, cityY)
    local pOldOwner = Players[oldPlayerID];

    if pOldOwner:IsMajor() ~= true then return end
    if PlayerConfigurations[oldPlayerID]:GetLeaderName() ~= "LEADER_MER_MANNERHEIM" then return end
    local pCaptainCity = Players[oldPlayerID]:GetCities():GetCapitalCity();
    local pPlot = pCaptainCity:GetPlot();
    local iCount = pPlot:GetProperty(sLostCityCountKey) or 0;
    if iCount >= iMaxLostCityBonus then return end;
    iCount = iCount + 1;
    pPlot:SetProperty(sLostCityCountKey, iCount);
end

GameEvents.CityConquered.Add(OnCityConquered)

print("Finland.lua loaded")

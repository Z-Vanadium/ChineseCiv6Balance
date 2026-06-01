-----------------------------------------------
-- MALAYSIA FUNCTIONS
-----------------------------------------------
-----------------------------------------------
-- UTILITIES
-----------------------------------------------

function C15_ValidTrait(sTrait) -- Chrisy
    local tValid = {}
    for k, v in ipairs(PlayerManager.GetWasEverAliveIDs()) do
        local leaderType = PlayerConfigurations[v]:GetLeaderTypeName()
        for trait in GameInfo.LeaderTraits() do
            if trait.LeaderType == leaderType and trait.TraitType == sTrait then 
                tValid[v] = true 
            end;
        end
        if not tValid[v] then
            local civType = PlayerConfigurations[v]:GetCivilizationTypeName()
            for trait in GameInfo.CivilizationTraits() do
                if trait.CivilizationType == civType and trait.TraitType == sTrait then 
                    tValid[v] = true 
                end;
            end
        end
    end
    return tValid
end

-----------------------------------------------
-- CONSTANTS
-----------------------------------------------

	local sTrait = "TRAIT_CIVILIZATION_CVS_MALAYSIA_UA"
	local tTraitPlayers = C15_ValidTrait(sTrait)

-----------------------------------------------
-- FUNCTION CPG_Malaysia_QuestEnvoy
-- Authors: ChimpanG
-----------------------------------------------

function CPG_Malaysia_QuestEnvoy(CityStatePlayerID, CompletedQuestPlayerID)
	
	if tTraitPlayers[CompletedQuestPlayerID] then
		local pPlayer = Players[CompletedQuestPlayerID]
		local pCityState = Players[CityStatePlayerID]
		local pSuzerain = pCityState:GetInfluence():GetSuzerain()

		if pSuzerain ~= -1 and pSuzerain ~= pPlayer then
			pPlayer:GetInfluence():GiveFreeTokenToPlayer(CityStatePlayerID)
		end
	end
end		

Events.QuestChanged.Add(CPG_Malaysia_QuestEnvoy);

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local TalentMgr = {}

function TalentMgr:GetNode(nodeID)
    local id = tonumber(nodeID)
    if id == nil then
        return nil
    end
    return TalentConfig.Nodes[id]
end

function TalentMgr:IsUltimateNode(nodeID)
    local id = tonumber(nodeID)
    return id ~= nil and TalentConfig.UltimateNodeIDs[id] == true
end

function TalentMgr:HasLearnedTalent(playerState, nodeID)
    local node = self:GetNode(nodeID)
    if playerState == nil or node == nil then
        return false
    end

    local learnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                               playerState.LearnedTalents
    if type(learnedTalents) ~= "table" then
        return false
    end

    local learned = learnedTalents[tostring(node.ID)]
    if learned == nil then
        learned = learnedTalents[node.ID]
    end
    return learned == true or tonumber(learned) == 1
end

function TalentMgr:ArePrerequisitesMet(playerState, nodeID)
    local node = self:GetNode(nodeID)
    if playerState == nil or node == nil then
        return false
    end

    local requireID = node.RequireID
    if requireID == nil then
        return true
    end

    if type(requireID) == "table" then
        for _, prerequisiteID in ipairs(requireID) do
            if not self:HasLearnedTalent(playerState, prerequisiteID) then
                return false
            end
        end
        return true
    end

    return self:HasLearnedTalent(playerState, requireID)
end

function TalentMgr:CanLearnTalent(playerState, nodeID)
    local node = self:GetNode(nodeID)
    if playerState == nil or node == nil then
        return false
    end

    if self:HasLearnedTalent(playerState, node.ID) then
        return false
    end

    if not self:ArePrerequisitesMet(playerState, node.ID) then
        return false
    end

    local talentPoints = playerState.GetTalentPoints ~= nil and playerState:GetTalentPoints() or
                             math.max(0, math.floor(tonumber(playerState.TalentPoints) or 0))
    local cost = math.max(0, math.floor(tonumber(node.Cost) or 0))
    return talentPoints >= cost
end

function TalentMgr:GetSpentTalentPoints(playerState)
    if playerState == nil then
        return 0
    end

    local learnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                               playerState.LearnedTalents
    if type(learnedTalents) ~= "table" then
        return 0
    end

    local spentPoints = 0
    for learnedID, learned in pairs(learnedTalents) do
        if learned == true or tonumber(learned) == 1 then
            local node = self:GetNode(learnedID)
            if node ~= nil then
                spentPoints = spentPoints + math.max(0, math.floor(tonumber(node.Cost) or 0))
            end
        end
    end
    return spentPoints
end

function TalentMgr:GetTotalTalentPoints(playerState)
    if playerState == nil then
        return 0
    end

    local availablePoints = playerState.GetTalentPoints ~= nil and playerState:GetTalentPoints() or
                                math.max(0, math.floor(tonumber(playerState.TalentPoints) or 0))
    return availablePoints + self:GetSpentTalentPoints(playerState)
end

function TalentMgr:CanGrantTalentPoints(playerState, amount)
    local grantAmount = math.floor(tonumber(amount) or 0)
    if playerState == nil or grantAmount <= 0 then
        return false
    end

    local maxTotalPoints = tonumber(TalentConfig.MaxTotalPoints)
    if maxTotalPoints == nil then
        return true
    end

    maxTotalPoints = math.max(0, math.floor(maxTotalPoints))
    return self:GetTotalTalentPoints(playerState) + grantAmount <= maxTotalPoints
end

function TalentMgr:GrantTalentPoints(playerState, amount)
    local grantAmount = math.floor(tonumber(amount) or 0)
    if not self:CanGrantTalentPoints(playerState, grantAmount) then
        return false
    end

    local oldTalentPoints = playerState.GetTalentPoints ~= nil and playerState:GetTalentPoints() or
                                math.max(0, math.floor(tonumber(playerState.TalentPoints) or 0))
    playerState.TalentPoints = oldTalentPoints + grantAmount

    if playerState.SaveToArchive == nil or playerState:SaveToArchive() ~= true then
        playerState.TalentPoints = oldTalentPoints
        return false
    end

    return true
end

function TalentMgr:GrantTestPointsIfEmpty(playerState)
    if TalentConfig.TestGrantEnabled ~= true or playerState == nil then
        return false
    end

    local talentPoints = playerState.GetTalentPoints ~= nil and playerState:GetTalentPoints() or
                             math.max(0, math.floor(tonumber(playerState.TalentPoints) or 0))
    local learnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                               playerState.LearnedTalents
    if talentPoints ~= 0 or type(learnedTalents) == "table" and next(learnedTalents) ~= nil then
        return false
    end

    return self:GrantTalentPoints(playerState, TalentConfig.TestGrantPoints)
end

function TalentMgr:CanEquipUltimate(playerState, nodeID)
    if playerState == nil then
        return false
    end

    local id = tonumber(nodeID)
    if id == nil then
        return false
    end
    id = math.floor(id)
    if id == 0 then
        return true
    end

    return self:IsUltimateNode(id) and self:HasLearnedTalent(playerState, id)
end

function TalentMgr:EquipUltimate(playerState, nodeID)
    if not self:CanEquipUltimate(playerState, nodeID) then
        return false
    end

    local id = math.floor(tonumber(nodeID) or 0)
    local oldEquippedID = playerState.GetEquippedUltimateID ~= nil and playerState:GetEquippedUltimateID() or
                              math.max(0, math.floor(tonumber(playerState.EquippedUltimateID) or 0))
    if oldEquippedID == id then
        return false
    end

    playerState.EquippedUltimateID = id
    if playerState.SaveToArchive == nil or playerState:SaveToArchive() ~= true then
        playerState.EquippedUltimateID = oldEquippedID
        return false
    end

    return true
end

function TalentMgr:LearnTalent(playerState, nodeID)
    local node = self:GetNode(nodeID)
    if not self:CanLearnTalent(playerState, nodeID) or node == nil then
        return false
    end

    local oldTalentPoints = playerState.GetTalentPoints ~= nil and playerState:GetTalentPoints() or
                                math.max(0, math.floor(tonumber(playerState.TalentPoints) or 0))
    local oldLearnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                                  playerState.LearnedTalents
    local learnedTalents = {}
    for learnedID, learned in pairs(oldLearnedTalents or {}) do
        if learned == true or tonumber(learned) == 1 then
            learnedTalents[tostring(learnedID)] = true
        end
    end

    local cost = math.max(0, math.floor(tonumber(node.Cost) or 0))
    learnedTalents[tostring(node.ID)] = true
    playerState.TalentPoints = oldTalentPoints - cost
    playerState.LearnedTalents = learnedTalents

    if playerState.SaveToArchive == nil or playerState:SaveToArchive() ~= true then
        playerState.TalentPoints = oldTalentPoints
        playerState.LearnedTalents = oldLearnedTalents
        return false
    end

    return true
end

function TalentMgr:HasResettableTalents(playerState)
    if playerState == nil then
        return false
    end

    local learnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                               playerState.LearnedTalents
    for _, learned in pairs(learnedTalents or {}) do
        if learned == true or tonumber(learned) == 1 then
            return true
        end
    end

    local equippedUltimateID = playerState.GetEquippedUltimateID ~= nil and playerState:GetEquippedUltimateID() or
                                   math.max(0, math.floor(tonumber(playerState.EquippedUltimateID) or 0))
    return equippedUltimateID > 0
end

function TalentMgr:ResetTalents(playerState)
    if playerState == nil then
        return false, 0, "invalid_player_state"
    end

    local oldTalentPoints = playerState.GetTalentPoints ~= nil and playerState:GetTalentPoints() or
                                math.max(0, math.floor(tonumber(playerState.TalentPoints) or 0))
    local oldLearnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                                  playerState.LearnedTalents
    local oldEquippedUltimateID = playerState.GetEquippedUltimateID ~= nil and
                                      playerState:GetEquippedUltimateID() or
                                      math.max(0, math.floor(tonumber(playerState.EquippedUltimateID) or 0))
    local refundedPoints = self:GetSpentTalentPoints(playerState)

    if not self:HasResettableTalents(playerState) then
        return false, 0, "nothing_to_reset"
    end

    playerState.TalentPoints = oldTalentPoints + refundedPoints
    playerState.LearnedTalents = {}
    playerState.EquippedUltimateID = 0

    if playerState.SaveToArchive == nil or playerState:SaveToArchive() ~= true then
        playerState.TalentPoints = oldTalentPoints
        playerState.LearnedTalents = oldLearnedTalents
        playerState.EquippedUltimateID = oldEquippedUltimateID
        return false, 0, "save_failed"
    end

    return true, refundedPoints, "success"
end

return TalentMgr

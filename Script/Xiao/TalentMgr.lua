local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local TalentMgr = {}

function TalentMgr:GetNode(nodeID)
    local id = tonumber(nodeID)
    if id == nil then
        return nil
    end
    return TalentConfig.Nodes[id]
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

    return learnedTalents[tostring(node.ID)] == true or learnedTalents[node.ID] == true
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

function TalentMgr:GrantTalentPoints(playerState, amount)
    if playerState == nil then
        return false
    end

    local grantAmount = math.floor(tonumber(amount) or 0)
    if grantAmount <= 0 then
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

return TalentMgr

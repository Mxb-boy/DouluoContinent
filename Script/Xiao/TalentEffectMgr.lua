local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local TalentEffectMgr = {}

local function GetLearnedTalents(playerState)
    if playerState == nil then
        return nil
    end

    local learnedTalents = playerState.GetLearnedTalents ~= nil and playerState:GetLearnedTalents() or
                               playerState.LearnedTalents
    return type(learnedTalents) == "table" and learnedTalents or nil
end

local function IsLearned(learnedTalents, nodeID)
    if learnedTalents == nil then
        return false
    end

    local learned = learnedTalents[tostring(nodeID)]
    if learned == nil then
        learned = learnedTalents[nodeID]
    end
    return learned == true or tonumber(learned) == 1
end

local function AddSkillPaths(result, seen, configuredPaths)
    if type(configuredPaths) == "string" then
        configuredPaths = {configuredPaths}
    end
    if type(configuredPaths) ~= "table" then
        return
    end

    for _, skillPath in ipairs(configuredPaths) do
        if type(skillPath) == "string" and skillPath ~= "" and seen[skillPath] ~= true then
            seen[skillPath] = true
            table.insert(result, skillPath)
        end
    end
end

function TalentEffectMgr:GetLearnedNodeIDs(playerState)
    local learnedTalents = GetLearnedTalents(playerState)
    local nodeIDs = {}

    for nodeID in pairs(TalentConfig.Nodes or {}) do
        local numericID = tonumber(nodeID)
        if numericID ~= nil and IsLearned(learnedTalents, numericID) then
            table.insert(nodeIDs, numericID)
        end
    end

    table.sort(nodeIDs)
    return nodeIDs
end

-- Node effect schema:
-- Effects = {
--     Stats = { MaxHealthFlat = 100, AttackFlat = 10, CritRate = 0.05 },
--     PassiveSkillPaths = { "Asset/.../PassiveSkill.PassiveSkill_C" },
--     UltimateSkillPath = "Asset/.../UltimateSkill.UltimateSkill_C"
-- }
function TalentEffectMgr:GetStatBonuses(playerState)
    local bonuses = {}

    for _, nodeID in ipairs(self:GetLearnedNodeIDs(playerState)) do
        local node = TalentConfig.Nodes[nodeID]
        local stats = node ~= nil and node.Effects ~= nil and node.Effects.Stats or nil
        if type(stats) == "table" then
            for statName, value in pairs(stats) do
                if type(statName) == "string" then
                    bonuses[statName] = (bonuses[statName] or 0) + (tonumber(value) or 0)
                end
            end
        end
    end

    return bonuses
end

function TalentEffectMgr:GetStatBonus(playerState, statName)
    if type(statName) ~= "string" or statName == "" then
        return 0
    end
    return tonumber(self:GetStatBonuses(playerState)[statName]) or 0
end

function TalentEffectMgr:GetEffectiveBaseMaxHp(playerState, baseMaxHp)
    local baseValue = tonumber(baseMaxHp)
    if baseValue == nil and playerState ~= nil then
        baseValue = playerState.GetBaseMaxHp ~= nil and tonumber(playerState:GetBaseMaxHp()) or
                        tonumber(playerState.BaseMaxHp)
    end
    return math.max(0, (baseValue or 100) + self:GetStatBonus(playerState, "MaxHealthFlat"))
end

function TalentEffectMgr:GetEffectiveBaseAttack(playerState, baseAttack)
    local baseValue = tonumber(baseAttack)
    if baseValue == nil and playerState ~= nil then
        baseValue = playerState.GetBaseAttack ~= nil and tonumber(playerState:GetBaseAttack()) or
                        tonumber(playerState.BaseAttack)
    end
    return math.max(0, (baseValue or 40) + self:GetStatBonus(playerState, "AttackFlat"))
end

function TalentEffectMgr:GetLearnedPassiveSkillPaths(playerState)
    local result = {}
    local seen = {}

    for _, nodeID in ipairs(self:GetLearnedNodeIDs(playerState)) do
        local node = TalentConfig.Nodes[nodeID]
        local effects = node ~= nil and node.Effects or nil
        if type(effects) == "table" then
            AddSkillPaths(result, seen, effects.PassiveSkillPaths)
        end
    end

    return result
end

function TalentEffectMgr:GetEquippedUltimateSkillPath(playerState)
    if playerState == nil then
        return nil
    end

    local nodeID = playerState.GetEquippedUltimateID ~= nil and playerState:GetEquippedUltimateID() or
                       tonumber(playerState.EquippedUltimateID)
    nodeID = math.max(0, math.floor(tonumber(nodeID) or 0))
    local learnedTalents = GetLearnedTalents(playerState)
    local node = TalentConfig.Nodes[nodeID]
    if node == nil or TalentConfig.UltimateNodeIDs[nodeID] ~= true or not IsLearned(learnedTalents, nodeID) then
        return nil
    end

    local effects = node.Effects
    local skillPath = type(effects) == "table" and effects.UltimateSkillPath or nil
    return type(skillPath) == "string" and skillPath ~= "" and skillPath or nil
end

function TalentEffectMgr:BuildEffectSnapshot(playerState)
    return {
        Stats = self:GetStatBonuses(playerState),
        PassiveSkillPaths = self:GetLearnedPassiveSkillPaths(playerState),
        UltimateSkillPath = self:GetEquippedUltimateSkillPath(playerState)
    }
end

return TalentEffectMgr

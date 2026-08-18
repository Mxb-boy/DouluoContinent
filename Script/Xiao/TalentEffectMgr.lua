local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")

local TalentEffectMgr = {}
local OriginalSkillCooldowns = {}

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
--     Stats = { MaxHealthFlat = 100, MaxHealthPercent = 0.1, AttackFlat = 10, CritRate = 0.05 },
--     PassiveBuffStats = { CritRate = { CritRate = 0.1 } },
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

function TalentEffectMgr:GetPassiveBuffStatBonus(playerState, buffKey, statName)
    if type(buffKey) ~= "string" or buffKey == "" or type(statName) ~= "string" or statName == "" then
        return 0
    end

    local bonus = 0
    for _, nodeID in ipairs(self:GetLearnedNodeIDs(playerState)) do
        local node = TalentConfig.Nodes[nodeID]
        local effects = node ~= nil and node.Effects or nil
        local passiveBuffStats = type(effects) == "table" and effects.PassiveBuffStats or nil
        local buffStats = type(passiveBuffStats) == "table" and passiveBuffStats[buffKey] or nil
        if type(buffStats) == "table" then
            bonus = bonus + (tonumber(buffStats[statName]) or 0)
        end
    end
    return bonus
end

function TalentEffectMgr:GetEffectiveBaseMaxHp(playerState, baseMaxHp)
    local baseValue = tonumber(baseMaxHp)
    if baseValue == nil and playerState ~= nil then
        baseValue = playerState.GetBaseMaxHp ~= nil and tonumber(playerState:GetBaseMaxHp()) or
                        tonumber(playerState.BaseMaxHp)
    end
    local healthWithFlatBonus = (baseValue or 100) + self:GetStatBonus(playerState, "MaxHealthFlat")
    local healthPercent = math.max(0, self:GetStatBonus(playerState, "MaxHealthPercent"))
    return math.max(0, healthWithFlatBonus * (1 + healthPercent))
end

function TalentEffectMgr:GetEffectiveBaseAttack(playerState, baseAttack)
    local baseValue = tonumber(baseAttack)
    if baseValue == nil and playerState ~= nil then
        baseValue = playerState.GetBaseAttack ~= nil and tonumber(playerState:GetBaseAttack()) or
                        tonumber(playerState.BaseAttack)
    end

    local attackWithFlatBonus = (baseValue or 40) + self:GetStatBonus(playerState, "AttackFlat")
    local attackPercent = math.max(0, self:GetStatBonus(playerState, "AttackPercent"))
    return math.max(0, attackWithFlatBonus * (1 + attackPercent))
end

function TalentEffectMgr:GetOutgoingDamageMultiplier(playerState)
    local passiveBuffPercent = playerState ~= nil and tonumber(playerState.TalentBuff_AttackPercent) or 0
    return 1 + math.max(0, passiveBuffPercent)
end

function TalentEffectMgr:GetEffectiveCritRate(playerState, baseRate)
    local criticalConfig = TalentConfig.Critical or {}
    local rate = tonumber(baseRate)
    if rate == nil then
        rate = tonumber(criticalConfig.BaseRate) or 0
    end

    local passiveBuffRate = playerState ~= nil and tonumber(playerState.TalentBuff_CritRate) or 0
    return math.max(0, math.min(1, rate + self:GetStatBonus(playerState, "CritRate") + passiveBuffRate))
end

function TalentEffectMgr:GetEffectiveCritMultiplier(playerState, baseMultiplier)
    local criticalConfig = TalentConfig.Critical or {}
    local multiplier = tonumber(baseMultiplier)
    if multiplier == nil then
        multiplier = tonumber(criticalConfig.BaseMultiplier) or 1
    end

    local passiveBuffMultiplier = playerState ~= nil and tonumber(playerState.TalentBuff_CritMultiplierFlat) or 0
    return math.max(1, multiplier + self:GetStatBonus(playerState, "CritMultiplierFlat") + passiveBuffMultiplier)
end

function TalentEffectMgr:ClearTransientBuffState(playerState)
    if playerState == nil then
        return
    end

    playerState.TalentBuff_AttackPercent = 0
    playerState.TalentBuff_CritRate = 0
    playerState.TalentBuff_CritMultiplierFlat = 0
end

local function RequestGameplayTag(tagName)
    if type(tagName) ~= "string" or tagName == "" or UGCGameplayTagSystem == nil or
        UGCGameplayTagSystem.RequestGameplayTag == nil then
        return nil
    end

    local success, gameplayTag = pcall(UGCGameplayTagSystem.RequestGameplayTag, tagName)
    return success and gameplayTag or nil
end

function TalentEffectMgr:GetSkillCooldownMultiplier(playerState)
    local multiplier = 1
    for _, nodeID in ipairs(self:GetLearnedNodeIDs(playerState)) do
        local node = TalentConfig.Nodes[nodeID]
        local effects = node ~= nil and node.Effects or nil
        local nodeMultiplier = type(effects) == "table" and tonumber(effects.SkillCooldownMultiplier) or nil
        if nodeMultiplier ~= nil then
            multiplier = multiplier * math.max(0, nodeMultiplier)
        end
    end
    return multiplier
end

local function ApplySkillCooldownMultiplier(skill, multiplier)
    if skill == nil or skill.GetCDRecoveryTime == nil or skill.SetCDRecoveryTime == nil then
        return false, false
    end

    local success, currentCooldown = pcall(skill.GetCDRecoveryTime, skill)
    currentCooldown = success and tonumber(currentCooldown) or nil
    if currentCooldown == nil or currentCooldown <= 0 then
        return false, false
    end

    local originalCooldown = OriginalSkillCooldowns[skill]
    if originalCooldown == nil then
        originalCooldown = currentCooldown
        OriginalSkillCooldowns[skill] = originalCooldown
    end

    local targetCooldown = math.max(0.01, originalCooldown * multiplier)
    if math.abs(currentCooldown - targetCooldown) <= 0.001 then
        return true, false
    end

    local err = nil
    success, err = pcall(skill.SetCDRecoveryTime, skill, targetCooldown)
    if not success then
        ugcprint("[TalentCooldown] SetCDRecoveryTime failed: " .. tostring(err))
        return false, false
    end
    return true, true
end

function TalentEffectMgr:RefreshSkillCooldowns(ownerActor, playerState)
    local skillTags = TalentConfig.SkillCooldownTags
    if ownerActor == nil or playerState == nil or type(skillTags) ~= "table" or
        UGCPersistEffectSystem == nil or UGCPersistEffectSystem.GetSkillsByTag == nil then
        return 0
    end
    if UGCGameSystem.IsServer ~= nil and not UGCGameSystem.IsServer() then
        return 0
    end

    local multiplier = self:GetSkillCooldownMultiplier(playerState)
    local matchedCount = 0
    local updatedCount = 0
    local seenSkills = {}
    for _, tagName in ipairs(skillTags) do
        local gameplayTag = RequestGameplayTag(tagName)
        if gameplayTag ~= nil then
            local success, skills = pcall(UGCPersistEffectSystem.GetSkillsByTag, ownerActor, gameplayTag)
            if success and skills ~= nil then
                local iterateSuccess, iterateError = pcall(function()
                    for _, skill in ipairs(skills) do
                        if skill ~= nil and seenSkills[skill] ~= true then
                            seenSkills[skill] = true
                            local matched, updated = ApplySkillCooldownMultiplier(skill, multiplier)
                            if matched then
                                matchedCount = matchedCount + 1
                            end
                            if updated then
                                updatedCount = updatedCount + 1
                            end
                        end
                    end
                end)
                if not iterateSuccess then
                    ugcprint("[TalentCooldown] iterate skills failed for tag=" .. tostring(tagName) ..
                                 ": " .. tostring(iterateError))
                end
            elseif not success then
                ugcprint("[TalentCooldown] GetSkillsByTag failed for tag=" .. tostring(tagName) ..
                             ": " .. tostring(skills))
            end
        else
            ugcprint("[TalentCooldown] invalid skill tag=" .. tostring(tagName))
        end
    end

    ugcprint("[TalentCooldown] multiplier=" .. tostring(multiplier) ..
                 ", matched=" .. tostring(matchedCount) .. ", updated=" .. tostring(updatedCount))
    return matchedCount
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

local TalentUltimateMgr = {}

local TalentConfig = UGCGameSystem.UGCRequire("Script.Xiao.TalentConfig")
local TalentEffectMgr = UGCGameSystem.UGCRequire("Script.Xiao.TalentEffectMgr")

local ULTIMATE_SKILL_SLOT = "Skill.Slot.Slot0"
local LOGIN_RESTORE_RETRY_INTERVAL = 0.2
local LOGIN_RESTORE_MAX_RETRIES = 20

local function Log(message)
    if ugcprint ~= nil then
        ugcprint("[TalentUltimate] " .. tostring(message))
    end
end

local function CollectSkillInstances(playerPawn, skillPath, result, seen)
    local fullPath = UGCGameSystem.GetUGCResourcesFullPath(skillPath)
    local success, skills = pcall(UGCPersistEffectSystem.GetSkillsByClass, playerPawn, fullPath)
    if not success or skills == nil then
        return
    end

    local countSuccess, skillCount = pcall(function()
        return #skills
    end)
    if countSuccess and tonumber(skillCount) ~= nil then
        for index = 1, tonumber(skillCount) do
            local readSuccess, skillInstance = pcall(function()
                return skills[index]
            end)
            if readSuccess and skillInstance ~= nil and not seen[skillInstance] then
                seen[skillInstance] = true
                table.insert(result, skillInstance)
            end
        end
    elseif skills ~= nil and not seen[skills] then
        seen[skills] = true
        table.insert(result, skills)
    end
end

local function RemoveAllUltimateSkills(playerPawn)
    if UGCPersistEffectSystem == nil or UGCPersistEffectSystem.GetSkillsByClass == nil or
        UGCPersistEffectSystem.RemoveSkillInstance == nil then
        Log("remove failed: skill query or removal API is unavailable")
        return false
    end

    local skillInstances = {}
    local seen = {}
    for nodeID in pairs(TalentConfig.UltimateNodeIDs or {}) do
        local node = TalentConfig.Nodes[nodeID]
        local effects = node ~= nil and node.Effects or nil
        local skillPath = type(effects) == "table" and effects.UltimateSkillPath or nil
        if type(skillPath) == "string" and skillPath ~= "" then
            CollectSkillInstances(playerPawn, skillPath, skillInstances, seen)
        end
    end

    local allRemoved = true
    for _, skillInstance in ipairs(skillInstances) do
        local success, errorMessage = pcall(
            UGCPersistEffectSystem.RemoveSkillInstance,
            playerPawn,
            skillInstance
        )
        if not success then
            allRemoved = false
            Log("remove failed: " .. tostring(errorMessage))
        end
    end

    if not allRemoved then
        return false
    end
    playerPawn.TalentUltimateSkillInstance = nil
    playerPawn.TalentUltimateSkillPath = nil
    Log("removed ultimate instances=" .. tostring(#skillInstances))
    return true
end

function TalentUltimateMgr:RefreshEquippedUltimate(playerPawn, playerState)
    if playerPawn == nil or playerState == nil then
        return false
    end
    if UGCGameSystem.IsServer ~= nil and not UGCGameSystem.IsServer() then
        return false
    end

    local desiredPath = TalentEffectMgr:GetEquippedUltimateSkillPath(playerState)
    if desiredPath == playerPawn.TalentUltimateSkillPath and
        playerPawn.TalentUltimateSkillInstance ~= nil then
        return true
    end
    if desiredPath == nil and playerPawn.TalentUltimateCleanupCompleted == true and
        playerPawn.TalentUltimateSkillInstance == nil then
        return true
    end

    if not RemoveAllUltimateSkills(playerPawn) then
        return false
    end
    playerPawn.TalentUltimateCleanupCompleted = true
    if desiredPath == nil then
        Log("ultimate cleared from slot 0")
        return true
    end
    if UGCPersistEffectSystem == nil or UGCPersistEffectSystem.AddSkillByClass == nil then
        Log("equip failed: AddSkillByClass is unavailable")
        return false
    end

    local fullPath = UGCGameSystem.GetUGCResourcesFullPath(desiredPath)
    local skillClass = nil
    if UGCObjectUtility ~= nil and UGCObjectUtility.LoadClass ~= nil then
        local loadSuccess, loadResult = pcall(UGCObjectUtility.LoadClass, fullPath)
        if loadSuccess then
            skillClass = loadResult
        else
            Log("load class failed: path=" .. tostring(fullPath) .. " error=" .. tostring(loadResult))
        end
    end
    if skillClass == nil then
        Log("equip failed: skill class is nil path=" .. tostring(fullPath))
        return false
    end

    local success, skillInstance = pcall(
        UGCPersistEffectSystem.AddSkillByClass,
        playerPawn,
        skillClass,
        nil,
        ULTIMATE_SKILL_SLOT
    )
    if not success or skillInstance == nil then
        Log("equip failed: path=" .. tostring(fullPath) .. " error=" .. tostring(skillInstance))
        return false
    end

    if skillInstance.EnableSkill ~= nil then
        local enableSuccess, enableError = pcall(skillInstance.EnableSkill, skillInstance)
        if not enableSuccess then
            pcall(UGCPersistEffectSystem.RemoveSkillInstance, playerPawn, skillInstance)
            Log("enable failed: path=" .. tostring(desiredPath) .. " error=" .. tostring(enableError))
            return false
        end
    end

    local enabledState = "unknown"
    if skillInstance.IsSkillEnable ~= nil then
        local stateSuccess, stateResult = pcall(skillInstance.IsSkillEnable, skillInstance)
        if stateSuccess then
            enabledState = tostring(stateResult)
        end
    end

    playerPawn.TalentUltimateSkillInstance = skillInstance
    playerPawn.TalentUltimateSkillPath = desiredPath
    Log("equipped path=" .. tostring(desiredPath) .. " slot=" .. ULTIMATE_SKILL_SLOT ..
        " enabled=" .. enabledState)
    return true
end

local function IsWeaponRuntimeReady(playerPawn)
    if playerPawn == nil or UGCWeaponManagerSystem == nil or
        UGCWeaponManagerSystem.GetCurrentWeaponSlot == nil or
        UGCWeaponManagerSystem.GetCurrentWeapon == nil or
        ESurviveWeaponPropSlot == nil then
        return false
    end

    local slotSuccess, currentSlot = pcall(UGCWeaponManagerSystem.GetCurrentWeaponSlot, playerPawn)
    local weaponSuccess, currentWeapon = pcall(UGCWeaponManagerSystem.GetCurrentWeapon, playerPawn)
    local meleeSlot = ESurviveWeaponPropSlot.SWPS_MeleeWeapon
    return slotSuccess and weaponSuccess and currentWeapon ~= nil and meleeSlot ~= nil and
        tonumber(currentSlot) == tonumber(meleeSlot)
end

function TalentUltimateMgr:ScheduleLoginRestore(playerPawn, playerState)
    if playerPawn == nil or playerState == nil then
        return false
    end
    if UGCGameSystem.IsServer ~= nil and not UGCGameSystem.IsServer() then
        return false
    end
    if UGCTimerUtility == nil or UGCTimerUtility.CreateLuaTimer == nil then
        return self:RefreshEquippedUltimate(playerPawn, playerState)
    end

    local restoreSerial = (tonumber(playerPawn.TalentUltimateLoginRestoreSerial) or 0) + 1
    playerPawn.TalentUltimateLoginRestoreSerial = restoreSerial
    local retryCount = 0

    local function TryRestore()
        if playerPawn == nil or playerState == nil or
            playerPawn.TalentUltimateLoginRestoreSerial ~= restoreSerial then
            return
        end

        local archiveReady = playerState.bArchiveLoaded == true
        local weaponReady = archiveReady and IsWeaponRuntimeReady(playerPawn)
        if weaponReady or retryCount >= LOGIN_RESTORE_MAX_RETRIES then
            local success = TalentUltimateMgr:RefreshEquippedUltimate(playerPawn, playerState)
            if success and TalentEffectMgr.RefreshSkillCooldowns ~= nil then
                TalentEffectMgr:RefreshSkillCooldowns(playerPawn, playerState)
            end
            Log("login restore success=" .. tostring(success) .. " weaponReady=" .. tostring(weaponReady) ..
                " retries=" .. tostring(retryCount))
            return
        end

        retryCount = retryCount + 1
        UGCTimerUtility.CreateLuaTimer(LOGIN_RESTORE_RETRY_INTERVAL, TryRestore, false)
    end

    UGCTimerUtility.CreateLuaTimer(LOGIN_RESTORE_RETRY_INTERVAL, TryRestore, false)
    return true
end

function TalentUltimateMgr:RestoreAfterRespawn(playerPawn, playerState)
    if playerPawn == nil or playerState == nil or playerState.bArchiveLoaded ~= true then
        return false
    end
    if UGCGameSystem.IsServer ~= nil and not UGCGameSystem.IsServer() then
        return false
    end
    if playerPawn.TalentUltimateRespawnRestoreCompleted == true then
        return true
    end

    local success = self:RefreshEquippedUltimate(playerPawn, playerState)
    if not success then
        Log("respawn restore failed")
        return false
    end

    if TalentEffectMgr.RefreshSkillCooldowns ~= nil then
        TalentEffectMgr:RefreshSkillCooldowns(playerPawn, playerState)
    end
    playerPawn.TalentUltimateRespawnRestoreCompleted = true
    Log("respawn restore completed")
    return true
end

function TalentUltimateMgr:ClearEquippedUltimate(playerPawn)
    if playerPawn == nil then
        return false
    end
    local success = RemoveAllUltimateSkills(playerPawn)
    if success then
        playerPawn.TalentUltimateCleanupCompleted = true
    end
    return success
end

return TalentUltimateMgr

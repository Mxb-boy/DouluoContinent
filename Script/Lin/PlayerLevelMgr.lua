local PlayerLevelMgr = {}
--[[----------------------负责等级经验规则------------------------]] --

--[[----------------------配置表路径------------------------]] --
local LEVEL_TABLE_PATH = "Data/Table/Lin/DT_PlayerLevelConfig"
local WAVE_EXP_TABLE_PATH = "Data/Table/Lin/DT_WaveExpConfig"
local DEFAULT_MAX_LEVEL = 40
local PLAYER_SKILL_1_REQUIRED_LEVEL = 20
local PLAYER_SKILL_1_PATH = "Asset/Blueprint/Prefabs/Skills/Lin/PlayerSkill/PlayerSkill_1.PlayerSkill_1_C"

--[[----------------------读取某一级的配置------------------------]] --
-- level 对应 DT_PlayerLevelConfig 里的 Level
function PlayerLevelMgr:GetLevelConfig(level)
    level = tonumber(level) or 1
    return UGCGameSystem.GetTableDataByRowName(LEVEL_TABLE_PATH, tostring(level))
end

--[[----------------------读取某一波怪物击杀经验------------------------]] --
-- MonsterID 对应 DT_WaveExpConfig 里的行名
function PlayerLevelMgr:GetWaveKillExp(monsterID)
    local cfg = UGCGameSystem.GetTableDataByRowName(WAVE_EXP_TABLE_PATH, tostring(monsterID))
    return cfg and tonumber(cfg.KillExp) or 0
end

--[[----------------------根据累计经验计算等级------------------------]] --
-- 返回值1：当前等级
-- 返回值2：下一级配置；满级时为 nil
function PlayerLevelMgr:GetLevelByExp(totalExp)
    totalExp = tonumber(totalExp) or 0

    local level = 1
    local nextCfg = nil
    for i = 1, DEFAULT_MAX_LEVEL do
        local cfg = self:GetLevelConfig(i)
        if cfg == nil then
            break
        end

        if totalExp >= (tonumber(cfg.ExpRequired) or 0) then
            level = i
            nextCfg = self:GetLevelConfig(i + 1)
        else
            nextCfg = cfg
            break
        end
    end

    return level, nextCfg
end

--[[----------------------计算当前等级内经验------------------------]] --
function PlayerLevelMgr:GetCurrentLevelExp(totalExp, level)
    local cfg = self:GetLevelConfig(level)
    local levelStartExp = cfg and (tonumber(cfg.ExpRequired) or 0) or 0
    return math.max((tonumber(totalExp) or 0) - levelStartExp, 0)
end

--[[----------------------给玩家增加经验------------------------]] --
-- PlayerController：获得经验的玩家控制器
-- amount：增加的经验值
-- 返回值1：是否升级
-- 返回值2：增加经验后的等级
function PlayerLevelMgr:AddExp(PlayerController, amount)
    amount = tonumber(amount) or 0
    if PlayerController == nil or amount <= 0 then
        return false, 1
    end

    local playerState = PlayerController.PlayerState
    if playerState == nil then
        return false, 1
    end

    local oldExp = playerState:GetPlayerExp()
    local expLevel = self:GetLevelByExp(oldExp)
    local oldLevel = math.max(playerState:GetPlayerLevel(), expLevel)
    local newExp = oldExp + amount
    local newLevel, nextCfg = self:GetLevelByExp(newExp)

    if newLevel > oldLevel then
        self:ApplyLevelBonus(PlayerController, oldLevel, newLevel)
    end

    playerState:SetPlayerLevel(newLevel)
    playerState:SetPlayerExp(newExp)
    playerState:SetPlayerMaxExp(nextCfg and (tonumber(nextCfg.ExpRequired) or newExp) or newExp)

    if _G.DOREPONCE ~= nil then
        _G.DOREPONCE(playerState, "PlayerLevel")
        _G.DOREPONCE(playerState, "PlayerExp")
        _G.DOREPONCE(playerState, "PlayerMaxExp")
    end

    --[[-----------------------客户端提示-----------------------]] --
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
        "添加的经验是" .. tostring(amount))
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_RefreshPlayerExp",
        self:GetCurrentLevelExp(newExp, newLevel),
        playerState:GetPlayerMaxExp(), newLevel)
    return newLevel > oldLevel, newLevel
end

--[[----------------------升级后应用属性加成------------------------]] --
-- 只加 oldLevel 到 newLevel 中间新增等级的差值，避免重复叠加
-- 属性写入 PlayerState 的 BaseAttack/BaseMaxHp，再走 RefreshStateMgrProperty 刷新 Pawn 和 UI
function PlayerLevelMgr:ApplyLevelBonus(PlayerController, oldLevel, newLevel)
    local playerState = PlayerController.PlayerState
    local addAttack = 0
    local addMaxHp = 0

    for level = oldLevel + 1, newLevel do
        local cfg = self:GetLevelConfig(level)
        if cfg ~= nil then
            addAttack = addAttack + (tonumber(cfg.AttackBonus) or 0)
            addMaxHp = addMaxHp + (tonumber(cfg.HealthMaxBonus) or 0)
        end
    end

    playerState:SetBaseAttack(playerState:GetBaseAttack() + addAttack)
    playerState:SetBaseMaxHp(playerState:GetBaseMaxHp() + addMaxHp)

    local pawn = PlayerController.Pawn or PlayerController:K2_GetPawn()
    if pawn ~= nil and pawn.RefreshStateMgrProperty ~= nil then
        pawn:RefreshStateMgrProperty(true)
    end

    if oldLevel < PLAYER_SKILL_1_REQUIRED_LEVEL and newLevel >= PLAYER_SKILL_1_REQUIRED_LEVEL and pawn ~= nil then
        UGCPersistEffectSystem.AddSkillByClass(pawn, UGCGameSystem.GetUGCResourcesFullPath(PLAYER_SKILL_1_PATH))
    end
end

return PlayerLevelMgr

local PlayerLevelMgr = {}
local WeaponRefineConfig = UGCGameSystem.UGCRequire("Script.Common.WeaponRefineConfig")
--[[----------------------负责等级经验规则------------------------]] --

--[[----------------------等级公式参数------------------------]] --
local WAVE_EXP_TABLE_PATH = "Data/Table/Lin/DT_WaveExpConfig"
local DEFAULT_MAX_LEVEL = 9999999 -- 最高等级
local DEFAULT_PLAYER_LEVEL = 1 -- 玩家默认等级
local DEFAULT_PLAYER_EXP = 0 -- 玩家默认累计经验
local BASE_LEVEL_EXP = 60 -- 1级升到2级的基础经验
local EXP_GROWTH = 1.72 -- 经验全局膨胀系数
local BASE_HP_BONUS = 4 -- 1级生命单级加成
local BASE_ATK_BONUS = 2 -- 1级攻击单级加成
local ATTR_GROWTH = 1.025 -- 属性单级成长系数
local PLAYER_SKILL_1_REQUIRED_LEVEL = 50 -- 解锁玩家技能1所需等级
local PLAYER_SKILL_1_PATH = "Asset/Blueprint/Prefabs/Skills/Lin/PlayerSkill/PlayerSkill_1.PlayerSkill_1_C"

local function IsSamePlayerKey(KeyA, KeyB)
    return KeyA ~= nil and KeyB ~= nil and tostring(KeyA) == tostring(KeyB)
end

--[[----------------------公式结果取整------------------------]] --
function PlayerLevelMgr:RoundFormula(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

--[[----------------------计算单级升阶经验------------------------]] --
function PlayerLevelMgr:GetLevelStepExp(level)
    level = math.max(DEFAULT_PLAYER_LEVEL, tonumber(level) or DEFAULT_PLAYER_LEVEL)
    return self:RoundFormula(BASE_LEVEL_EXP * (EXP_GROWTH ^ (level - 1)))
end

--[[----------------------计算达到等级所需累计经验------------------------]] --
function PlayerLevelMgr:GetLevelTotalExp(level)
    level = math.max(DEFAULT_PLAYER_LEVEL, tonumber(level) or DEFAULT_PLAYER_LEVEL)
    local totalExp = DEFAULT_PLAYER_EXP
    for i = DEFAULT_PLAYER_LEVEL, level - 1 do
        totalExp = totalExp + self:GetLevelStepExp(i)
    end
    return totalExp
end

--[[----------------------计算单级生命加成------------------------]] --
function PlayerLevelMgr:GetLevelHpBonus(level)
    level = math.max(DEFAULT_PLAYER_LEVEL, tonumber(level) or DEFAULT_PLAYER_LEVEL)
    return self:RoundFormula(BASE_HP_BONUS * (ATTR_GROWTH ^ (level - 1)))
end

--[[----------------------计算单级攻击加成------------------------]] --
function PlayerLevelMgr:GetLevelAtkBonus(level)
    level = math.max(DEFAULT_PLAYER_LEVEL, tonumber(level) or DEFAULT_PLAYER_LEVEL)
    return self:RoundFormula(BASE_ATK_BONUS * (ATTR_GROWTH ^ (level - 1)))
end

--[[----------------------读取某一波怪物击杀经验------------------------]] --
-- MonsterID 对应 DT_WaveExpConfig 里的行名
function PlayerLevelMgr:GetWaveKillExp(monsterID)
    local cfg = UGCGameSystem.GetTableDataByRowName(WAVE_EXP_TABLE_PATH, tostring(monsterID))
    return cfg and tonumber(cfg.KillExp) or 0
end

--[[----------------------根据累计经验计算等级------------------------]] --
-- 返回值：当前等级
-- 返回值：下一级累计经验阈值；满级时为当前经验
function PlayerLevelMgr:GetLevelByExp(totalExp)
    totalExp = tonumber(totalExp) or DEFAULT_PLAYER_EXP

    local level = DEFAULT_PLAYER_LEVEL
    local nextMaxExp = totalExp
    for i = DEFAULT_PLAYER_LEVEL, DEFAULT_MAX_LEVEL do
        local nextLevel = i + 1
        local nextTotalExp = self:GetLevelTotalExp(nextLevel)
        if nextLevel <= DEFAULT_MAX_LEVEL and totalExp >= nextTotalExp then
            level = nextLevel
            nextMaxExp = self:GetLevelTotalExp(nextLevel + 1)
        else
            nextMaxExp = nextLevel <= DEFAULT_MAX_LEVEL and nextTotalExp or totalExp
            break
        end
    end

    return level, nextMaxExp
end

--[[----------------------计算当前等级内经验------------------------]] --
function PlayerLevelMgr:GetCurrentLevelExp(totalExp, level)
    local levelStartExp = self:GetLevelTotalExp(level)
    return math.max((tonumber(totalExp) or DEFAULT_PLAYER_EXP) - levelStartExp, 0)
end

--[[----------------------计算当前等级升级所需经验------------------------]] --
function PlayerLevelMgr:GetCurrentLevelMaxExp(level, nextTotalExp)
    return self:GetLevelStepExp(level)
end

--[[----------------------给单个玩家增加经验------------------------]] --
-- PlayerController：获得经验的玩家控制器
-- amount：增加的经验值
-- 返回值：是否升级
-- 返回值：增加经验后的等级
function PlayerLevelMgr:AddExpToPlayer(PlayerController, amount)
    amount = tonumber(amount) or 0
    if PlayerController == nil or amount <= 0 then
        return false, DEFAULT_PLAYER_LEVEL
    end

    local playerState = PlayerController.PlayerState
    if playerState == nil then
        return false, DEFAULT_PLAYER_LEVEL
    end

    local oldExp = playerState:GetPlayerExp()
    local expLevel = self:GetLevelByExp(oldExp)
    local oldLevel = math.max(playerState:GetPlayerLevel(), expLevel)
    local newExp = oldExp + amount
    local newLevel, nextMaxExp = self:GetLevelByExp(newExp)

    if newLevel > oldLevel then
        self:ApplyLevelBonus(PlayerController, oldLevel, newLevel)
    end

    playerState:SetPlayerLevel(newLevel)
    playerState:SetPlayerExp(newExp)
    playerState:SetPlayerMaxExp(nextMaxExp)

    if _G.DOREPONCE ~= nil then
        _G.DOREPONCE(playerState, "PlayerLevel")
        _G.DOREPONCE(playerState, "PlayerExp")
        _G.DOREPONCE(playerState, "PlayerMaxExp")
    end

    -- 升级后服务端立即累计激活已解锁的旋转武器，不依赖UI是否打开。
    local PlayerPawn = PlayerController.Pawn or
        (PlayerController.K2_GetPawn ~= nil and PlayerController:K2_GetPawn() or nil)
    if PlayerPawn ~= nil and PlayerPawn.SetOrbitWeaponActiveGun ~= nil then
        local UnlockedCount = WeaponRefineConfig.GetUnlockedWeaponCount(newLevel)
        PlayerPawn:SetOrbitWeaponActiveGun(UnlockedCount,
            PlayerPawn.OrbitWeaponDamagePercent)
        if PlayerPawn.SetOrbitWeaponRotationSpeed ~= nil then
            local SkinIndex = math.max(1, math.min(WeaponRefineConfig.MAX_SKIN_COUNT,
                math.floor(tonumber(PlayerController.OrbitWeaponSkinIndex) or 1)))
            local RotationSpeed = WeaponRefineConfig.GetRotationSpeed(playerState,
                SkinIndex, UnlockedCount)
            PlayerController.OrbitWeaponRotationSpeed = RotationSpeed
            PlayerPawn:SetOrbitWeaponRotationSpeed(RotationSpeed)
        end
    end

    --[[-----------------------客户端提示----------------------]] --
    -- UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_ShowToast",
    --     "添加的经验是" .. tostring(amount))
    UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_RefreshPlayerExp",
        self:GetCurrentLevelExp(newExp, newLevel), self:GetCurrentLevelMaxExp(newLevel, playerState:GetPlayerMaxExp()),
        newLevel)
    return newLevel > oldLevel, newLevel
end

--[[----------------------将单个玩家提升到指定等级------------------------]] --
-- 只允许提升，不允许降级；提升后目标等级内经验为 0。
-- 复用正常加经验链路，确保等级属性、技能、旋转武器和客户端 UI 同步。
function PlayerLevelMgr:RaisePlayerToLevel(PlayerController, targetLevel)
    targetLevel = tonumber(targetLevel)
    if PlayerController == nil or targetLevel == nil or targetLevel ~= math.floor(targetLevel) or
        targetLevel < DEFAULT_PLAYER_LEVEL or targetLevel > DEFAULT_MAX_LEVEL then
        return false, "invalid_target", DEFAULT_PLAYER_LEVEL, DEFAULT_PLAYER_EXP
    end

    local playerState = PlayerController.PlayerState
    if playerState == nil then
        return false, "player_state_nil", DEFAULT_PLAYER_LEVEL, DEFAULT_PLAYER_EXP
    end

    local oldExp = playerState:GetPlayerExp()
    local expLevel = self:GetLevelByExp(oldExp)
    local oldLevel = math.max(playerState:GetPlayerLevel(), expLevel)
    if targetLevel <= oldLevel then
        return false, "target_not_higher", oldLevel, oldExp
    end

    local targetTotalExp = self:GetLevelTotalExp(targetLevel)
    local addExp = targetTotalExp - oldExp
    if addExp <= 0 then
        return false, "target_exp_not_higher", oldLevel, oldExp
    end

    local _, newLevel = self:AddExpToPlayer(PlayerController, addExp)
    local savedExp = playerState:GetPlayerExp()
    local verifiedLevel = self:GetLevelByExp(savedExp)
    local currentLevelExp = self:GetCurrentLevelExp(savedExp, verifiedLevel)
    if newLevel ~= targetLevel or verifiedLevel ~= targetLevel or math.abs(currentLevelExp) > 0.5 then
        return false, "verify_failed", verifiedLevel, savedExp
    end

    return true, "completed", verifiedLevel, savedExp
end

--[[----------------------按动态队伍共享经验------------------------]] --
-- 同队每名在线成员获得完整经验，不分摊、不限制距离；未组队时仅发给原玩家。
-- 返回值保持原约定：返回原获得者是否升级、增加经验后的等级。
function PlayerLevelMgr:AddExp(PlayerController, amount)
    amount = tonumber(amount) or 0
    if PlayerController == nil or amount <= 0 then
        return false, DEFAULT_PLAYER_LEVEL
    end

    local PlayerKey = PlayerController.PlayerKey
    local GameMode = UGCGameSystem.GetGameMode()
    local Squad = GameMode ~= nil and GameMode.GetSquadForMember ~= nil and PlayerKey ~= nil and
                      GameMode:GetSquadForMember(PlayerKey) or nil
    if Squad == nil or Squad.Members == nil then
        return self:AddExpToPlayer(PlayerController, amount)
    end

    local GrantedPlayerKeys = {}
    local bOriginalPlayerGranted = false
    local bOriginalPlayerLevelUp = false
    local OriginalPlayerLevel = DEFAULT_PLAYER_LEVEL
    for _, MemberKey in ipairs(Squad.Members) do
        local MemberKeyText = tostring(MemberKey)
        if MemberKey ~= nil and GrantedPlayerKeys[MemberKeyText] ~= true then
            GrantedPlayerKeys[MemberKeyText] = true
            local MemberController = UGCGameSystem.GetPlayerControllerByPlayerKey(MemberKey)
            if MemberController ~= nil then
                local bLevelUp, NewLevel = self:AddExpToPlayer(MemberController, amount)
                if IsSamePlayerKey(MemberKey, PlayerKey) then
                    bOriginalPlayerGranted = true
                    bOriginalPlayerLevelUp = bLevelUp
                    OriginalPlayerLevel = NewLevel
                end
            end
        end
    end

    if not bOriginalPlayerGranted then
        bOriginalPlayerLevelUp, OriginalPlayerLevel = self:AddExpToPlayer(PlayerController, amount)
    end
    return bOriginalPlayerLevelUp, OriginalPlayerLevel
end

--[[----------------------升级后应用属性加成------------------------]] --
-- 只加 oldLevel 到 newLevel 中间新增等级的差值，避免重复叠加
-- 属性写入 PlayerState 的 BaseAttack/BaseMaxHp，再走 RefreshStateMgrProperty 刷新 Pawn 和 UI
function PlayerLevelMgr:ApplyLevelBonus(PlayerController, oldLevel, newLevel)
    local playerState = PlayerController.PlayerState
    local addAttack = 0
    local addMaxHp = 0

    for level = oldLevel + 1, newLevel do
        addAttack = addAttack + self:GetLevelAtkBonus(level)
        addMaxHp = addMaxHp + self:GetLevelHpBonus(level)
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

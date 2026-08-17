UGCGameSystem.UGCRequire('Script.GameAttribute.game_attribute_type')
local DamageSync = UGCGameSystem.UGCRequire('Script.Common.DamageSync')
local TalentConfig = UGCGameSystem.UGCRequire('Script.Xiao.TalentConfig')
local TalentEffectMgr = UGCGameSystem.UGCRequire('Script.Xiao.TalentEffectMgr')
local TalentPassiveMgr = UGCGameSystem.UGCRequire('Script.Xiao.TalentPassiveMgr')
local UGCGlobalDamageCalculation = {}

local function SafeGet(Object, FieldName)
    if Object == nil then
        return nil
    end

    local Success, Result = pcall(function()
        return Object[FieldName]
    end)
    if Success then
        return Result
    end

    return nil
end

local function HasYXWDInvincibleBuff(VictimActor)
    if VictimActor == nil then
        return false
    end

    local PlayerState = SafeGet(VictimActor, "PlayerState")

    if PlayerState == nil then
        return false
    end

    if PlayerState.IsYXWDInvincibleBuffActive ~= nil then
        local Success, Result = pcall(PlayerState.IsYXWDInvincibleBuffActive, PlayerState)
        if Success then
            return Result == true
        end
    end

    if PlayerState.YXWD_InvincibleBuffActive == true then
        return true
    end

    if PlayerState.GetYXWD_InvincibleBuff ~= nil then
        local Success, Result = pcall(PlayerState.GetYXWD_InvincibleBuff, PlayerState)
        if Success and Result == true then
            return true
        end
    end

    return tonumber(PlayerState.YXWD_InvincibleBuff) == 1
end

local function IsIncomingDamage(CauserActor, VictimActor)
    if CauserActor == nil or VictimActor == nil then
        return true
    end

    return CauserActor ~= VictimActor
end

local function HasAuthority(Object)
    return Object ~= nil and Object.HasAuthority ~= nil and Object:HasAuthority()
end

local function GetPlayerKey(Object)
    if Object == nil then
        return nil
    end
    local DirectKey = SafeGet(Object, "PlayerKey")
    if DirectKey ~= nil then
        return DirectKey
    end
    local Controller = SafeGet(Object, "Controller")
    local ControllerKey = SafeGet(Controller, "PlayerKey")
    if ControllerKey ~= nil then
        return ControllerKey
    end
    local PlayerState = SafeGet(Object, "PlayerState")
    local StateKey = SafeGet(PlayerState, "PlayerKey")
    if StateKey ~= nil then
        return StateKey
    end
    if UGCGameSystem.GetPlayerKeyByPlayerPawn ~= nil then
        local Success, Result = pcall(UGCGameSystem.GetPlayerKeyByPlayerPawn, Object)
        if Success then
            return Result
        end
    end
    return nil
end

local function ShouldBlockSquadDamage(VictimActor, InstigatorController, CauserActor)
    local VictimKey = GetPlayerKey(VictimActor)
    local AttackerKey = GetPlayerKey(InstigatorController) or GetPlayerKey(CauserActor)
    if VictimKey == nil or AttackerKey == nil or tostring(VictimKey) == tostring(AttackerKey) then
        return false
    end
    local GameMode = UGCGameSystem.GetGameMode()
    return GameMode ~= nil and GameMode.ArePlayersInSameSquad ~= nil and
               GameMode:ArePlayersInSameSquad(VictimKey, AttackerKey)
end

local function AddCriticalResultTag(ExtraResult)
    if ExtraResult == nil or ExtraResult.ResultTags == nil or UGCGameplayTagSystem == nil or
        UGCGameplayTagSystem.RequestGameplayTag == nil then
        return
    end

    local Success, CritTag = pcall(UGCGameplayTagSystem.RequestGameplayTag, "UGC.Damage.Result.Critical")
    if Success and CritTag ~= nil then
        pcall(ExtraResult.ResultTags.Add, ExtraResult.ResultTags, CritTag)
    end
end

function UGCGlobalDamageCalculation:GetCalculationResult(Context, ExtraResult)
    local VictimActor = UGCAttributeSystem.GetVictimFromContext(Context)
    local InstigatorController = UGCAttributeSystem.GetInstigatorFromContext(Context)
    local CauserActor = UGCGameSystem.GetPlayerPawnByPlayerController(InstigatorController)

    if ShouldBlockSquadDamage(VictimActor, InstigatorController, CauserActor) then
        ugcprint("[Team] Server blocked teammate damage")
        return 0, ExtraResult
    end

    local FinalDamage = UGCAttributeSystem.GetSourceMagnitudeFromContext(Context)
    local DamageCauser = nil
    if UGCAttributeSystem.GetCauserFromContext ~= nil then
        local success, result = pcall(UGCAttributeSystem.GetCauserFromContext, Context)
        if success then
            DamageCauser = result
        end
    end
    local bCauserIsPlayer = CauserActor ~= nil and CauserActor.PlayerState ~= nil
    local bVictimIsPlayer = VictimActor ~= nil and VictimActor.PlayerState ~= nil
    local PlayerState = bCauserIsPlayer and CauserActor.PlayerState or nil
    local ServerAttackPower = nil
    if bCauserIsPlayer and not bVictimIsPlayer then
        ServerAttackPower = UGCAttributeSystem.GetGameAttributeValue(CauserActor, "AttackPower")
    end
    ServerAttackPower = tonumber(ServerAttackPower)
    FinalDamage = tonumber(FinalDamage) or 0
    -- 带攻击力倍率标记的碰撞/技能已经传入 AttackPower × Percent，不能再被抬高为 100% 攻击力。
    local bUseAttackPercentDamage = DamageCauser ~= nil and DamageCauser.UseAttackPercentDamage == true
    if bUseAttackPercentDamage then
        FinalDamage = DamageSync.GetAttackPercentDamage(InstigatorController, DamageCauser,
            DamageCauser.AttackDamagePercent) or FinalDamage
    elseif ServerAttackPower ~= nil and ServerAttackPower > FinalDamage then
        FinalDamage = ServerAttackPower
    end

    local CurrentSignalHP = 0
    local MaxSignalHP = 0
    if VictimActor ~= nil then
        local success, value = pcall(UGCAttributeSystem.GetGameAttributeValue, VictimActor, "SignalHP")
        if success then
            CurrentSignalHP = tonumber(value) or 0
        end

        success, value = pcall(UGCAttributeSystem.GetGameAttributeValueMax, VictimActor, "SignalHP")
        if success then
            MaxSignalHP = tonumber(value) or 0
        end
    end

    if MaxSignalHP > 0 then
        local SignalHPPercent = (CurrentSignalHP / MaxSignalHP) * 100
        if SignalHPPercent > 0 and SignalHPPercent <= 25 then
            FinalDamage = FinalDamage * 1.8
        elseif SignalHPPercent > 25 and SignalHPPercent <= 50 then
            FinalDamage = FinalDamage * 1.5
        elseif SignalHPPercent > 50 and SignalHPPercent <= 75 then
            FinalDamage = FinalDamage * 1.2
        end
    end

    local bHasYXWDBuff = HasYXWDInvincibleBuff(VictimActor)
    local bIsIncomingDamage = IsIncomingDamage(CauserActor, VictimActor)
    if bHasYXWDBuff and bIsIncomingDamage then
        return 1, ExtraResult
    end

    if bCauserIsPlayer and not bVictimIsPlayer then
        FinalDamage = FinalDamage * TalentEffectMgr:GetOutgoingDamageMultiplier(PlayerState)
    end

    local CriticalConfig = TalentConfig.Critical or {}
    local bIsCritical = false
    if CriticalConfig.Enabled == true and bCauserIsPlayer and not bVictimIsPlayer and
        HasAuthority(InstigatorController) then
        local CritRate = TalentEffectMgr:GetEffectiveCritRate(PlayerState)
        if CritRate > 0 and math.random() < CritRate then
            local CritMultiplier = TalentEffectMgr:GetEffectiveCritMultiplier(PlayerState)
            FinalDamage = FinalDamage * CritMultiplier
            bIsCritical = true
            AddCriticalResultTag(ExtraResult)
        end
    end

    if bIsCritical then
        ugcprint("[Critical] Server damage=" .. tostring(FinalDamage))
    end

    if bCauserIsPlayer and not bVictimIsPlayer and HasAuthority(InstigatorController) then
        if FinalDamage > 0 then
            TalentPassiveMgr:TryTriggerOnDamage(CauserActor, PlayerState)
        end
        UnrealNetwork.CallUnrealRPC(InstigatorController, InstigatorController, "Client_ShowMonsterDamageNumber",
            VictimActor, FinalDamage)
    end

    return FinalDamage, ExtraResult
end

return UGCGlobalDamageCalculation

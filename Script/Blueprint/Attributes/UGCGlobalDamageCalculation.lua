UGCGameSystem.UGCRequire('Script.GameAttribute.game_attribute_type')
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

function UGCGlobalDamageCalculation:GetCalculationResult(Context, ExtraResult)
    local VictimActor = UGCAttributeSystem.GetVictimFromContext(Context)
    local InstigatorController = UGCAttributeSystem.GetInstigatorFromContext(Context)
    local CauserActor = UGCGameSystem.GetPlayerPawnByPlayerController(InstigatorController)

    local SkillAttack = UGCAttributeSystem.GetSourceMagnitudeFromContext(Context)
    local bCauserIsPlayer = CauserActor ~= nil and CauserActor.PlayerState ~= nil
    local bVictimIsPlayer = VictimActor ~= nil and VictimActor.PlayerState ~= nil
    local ServerAttackPower = nil
    if bCauserIsPlayer and not bVictimIsPlayer then
        ServerAttackPower = UGCAttributeSystem.GetGameAttributeValue(CauserActor, "AttackPower")
    end
    ServerAttackPower = tonumber(ServerAttackPower)
    SkillAttack = tonumber(SkillAttack) or 0
    if ServerAttackPower ~= nil and ServerAttackPower > SkillAttack then
        SkillAttack = ServerAttackPower
    end

    local CurrentSignalHP = UGCAttributeSystem.GetGameAttributeValue(VictimActor, "SignalHP")
    local MaxSignalHP = UGCAttributeSystem.GetGameAttributeValueMax(VictimActor, "SignalHP")

    local SignalHPPercent = (CurrentSignalHP / MaxSignalHP) * 100
    if SignalHPPercent > 0 and SignalHPPercent <= 25 then
        SkillAttack = SkillAttack * 1.8
    elseif SignalHPPercent > 25 and SignalHPPercent <= 50 then
        SkillAttack = SkillAttack * 1.5
    elseif SignalHPPercent > 50 and SignalHPPercent <= 75 then
        SkillAttack = SkillAttack * 1.2
    else
        SkillAttack = SkillAttack * 1
    end

    local bHasYXWDBuff = HasYXWDInvincibleBuff(VictimActor)
    local bIsIncomingDamage = IsIncomingDamage(CauserActor, VictimActor)
    if bHasYXWDBuff and bIsIncomingDamage then
        return 1, ExtraResult
    end

    return SkillAttack, ExtraResult
end

return UGCGlobalDamageCalculation

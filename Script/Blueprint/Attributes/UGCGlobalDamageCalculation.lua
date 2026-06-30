UGCGameSystem.UGCRequire('Script.GameAttribute.game_attribute_type')
local UGCGlobalDamageCalculation = {}
local MONSTER_DAMAGE_TAG = "Dmg_Monster"
local YXWD_DAMAGE_DEBUG_COUNT = 0

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
        if Success and Result == true then
            return true
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
    local Causer = UGCAttributeSystem.GetCauserFromContext(Context)
    local InstigatorController = UGCAttributeSystem.GetInstigatorFromContext(Context)
    local CauserActor = UGCGameSystem.GetPlayerPawnByPlayerController(InstigatorController)
    print("[UGCGlobalDamageCalculation] Context CauserActor --->"..tostring(CauserActor))
    print("[UGCGlobalDamageCalculation] Context VictimActor --->"..tostring(VictimActor))

    local SkillAttack = UGCAttributeSystem.GetSourceMagnitudeFromContext(Context)
    local ServerAttackPower = nil
    if CauserActor ~= nil then
        ServerAttackPower = UGCAttributeSystem.GetGameAttributeValue(CauserActor, "AttackPower")
    end
    print("[DamageDebug] CauserActor=" .. tostring(CauserActor)
        .. ", SourceMagnitude=" .. tostring(SkillAttack)
        .. ", ServerAttackPower=" .. tostring(ServerAttackPower)
        .. ", VictimActor=" .. tostring(VictimActor))
    ServerAttackPower = tonumber(ServerAttackPower)
    SkillAttack = tonumber(SkillAttack) or 0
    if ServerAttackPower ~= nil and ServerAttackPower > SkillAttack then
        print("[DamageDebug] Override SourceMagnitude by ServerAttackPower: "
            .. tostring(SkillAttack) .. " -> " .. tostring(ServerAttackPower))
        SkillAttack = ServerAttackPower
    end

    local CurrentSignalHP = UGCAttributeSystem.GetGameAttributeValue(VictimActor, "SignalHP")
    print("[UGCGlobalDamageCalculation] Context CurrentSignalHP --->"..tostring(CurrentSignalHP))
    local MaxSignalHP = UGCAttributeSystem.GetGameAttributeValueMax(VictimActor, "SignalHP")
    print("[UGCGlobalDamageCalculation] Context MaxSignalHP --->"..tostring(MaxSignalHP))

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
    print("[UGCGlobalDamageCalculation] Context SkillAttack --->"..tostring(SkillAttack))

    local bHasYXWDBuff = HasYXWDInvincibleBuff(VictimActor)
    local bIsIncomingDamage = IsIncomingDamage(CauserActor, VictimActor)
    if bHasYXWDBuff and bIsIncomingDamage then
        print("[YXWD Invincible] " .. MONSTER_DAMAGE_TAG .. " damage reduced to 1, original=" .. tostring(SkillAttack)
            .. ", CauserActor=" .. tostring(CauserActor)
            .. ", VictimActor=" .. tostring(VictimActor))
        return 1, ExtraResult
    end

    if bHasYXWDBuff and not bIsIncomingDamage and YXWD_DAMAGE_DEBUG_COUNT < 10 then
        YXWD_DAMAGE_DEBUG_COUNT = YXWD_DAMAGE_DEBUG_COUNT + 1
        print("[YXWD Invincible] buff active but ignored self damage, damage="
            .. tostring(SkillAttack) .. ", CauserActor=" .. tostring(CauserActor)
            .. ", VictimActor=" .. tostring(VictimActor)
            .. ", Context=" .. tostring(Context)
            .. ", ExtraResult=" .. tostring(ExtraResult))
    end

    return SkillAttack, ExtraResult
end

return UGCGlobalDamageCalculation

local DamageSync = {}

local function TryCall(object, functionName, ...)
    if object == nil or object[functionName] == nil then
        return nil
    end

    local success, result = pcall(object[functionName], object, ...)
    if success then
        return result
    end

    success, result = pcall(object[functionName], ...)
    if success then
        return result
    end

    return nil
end

local function GetPawnFromController(controller)
    if controller == nil then
        return nil
    end

    if controller.Pawn ~= nil then
        return controller.Pawn
    end

    return TryCall(controller, "K2_GetPawn") or TryCall(controller, "GetPawn") or
               TryCall(controller, "GetControlledPawn")
end

local function GetInstigatorPawn(eventInstigator, damageCauser)
    local pawn = GetPawnFromController(eventInstigator)
    if pawn ~= nil then
        return pawn
    end

    pawn = GetPawnFromController(TryCall(damageCauser, "GetInstigatorController"))
    if pawn ~= nil then
        return pawn
    end

    pawn = TryCall(damageCauser, "GetInstigator") or TryCall(damageCauser, "GetOwner")
    if pawn ~= nil then
        return pawn
    end

    return damageCauser
end

function DamageSync.GetPanelAttack(eventInstigator, damageCauser)
    local pawn = GetInstigatorPawn(eventInstigator, damageCauser)
    if pawn == nil then
        return nil
    end

    if UGCAttributeSystem ~= nil and UGCAttributeSystem.GetGameAttributeValue ~= nil then
        local success, attack = pcall(UGCAttributeSystem.GetGameAttributeValue, pawn, "AttackPower")
        attack = tonumber(attack)
        if success and attack ~= nil and attack > 0 then
            return attack
        end
    end

    return nil
end

-- 50 and 0.5 both mean 50%.
function DamageSync.NormalizeDamagePercent(percent)
    percent = tonumber(percent)
    if percent == nil then
        return 100
    end

    if percent >= 0 and percent <= 1 then
        percent = percent * 100
    end

    return math.max(0, percent)
end

-- Returns nil when the attacker has no valid AttackPower.
function DamageSync.GetAttackPercentDamage(eventInstigator, damageCauser, percent)
    local panelAttack = DamageSync.GetPanelAttack(eventInstigator, damageCauser)
    if panelAttack == nil then
        return nil
    end

    return panelAttack * DamageSync.NormalizeDamagePercent(percent) / 100
end

-- Lets global damage calculation preserve the AttackPower percentage.
function DamageSync.SetAttackPercentDamageSource(damageCauser, percent)
    if damageCauser == nil then
        return nil
    end

    local normalizedPercent = DamageSync.NormalizeDamagePercent(percent)
    damageCauser.UseAttackPercentDamage = true
    damageCauser.AttackDamagePercent = normalizedPercent
    return normalizedPercent
end

function DamageSync.OverrideDamageWithPanelAttack(damage, eventInstigator, damageCauser)
    local panelAttack = DamageSync.GetPanelAttack(eventInstigator, damageCauser)
    if panelAttack == nil then
        return damage
    end

    local currentDamage = tonumber(damage) or 0
    if currentDamage > panelAttack then
        return currentDamage
    end

    return panelAttack
end

return DamageSync

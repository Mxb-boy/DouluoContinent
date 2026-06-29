local DamageSync = {}
local Property = UGCGameSystem.UGCRequire("Script.property.property")

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

    return TryCall(controller, "K2_GetPawn")
        or TryCall(controller, "GetPawn")
        or TryCall(controller, "GetControlledPawn")
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

    pawn = TryCall(damageCauser, "GetInstigator")
        or TryCall(damageCauser, "GetOwner")
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

    if Property ~= nil and Property.GetAttack ~= nil then
        local attack = tonumber(Property.GetAttack(pawn))
        if attack ~= nil and attack > 0 then
            return attack
        end
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

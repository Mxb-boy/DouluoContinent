local property = {}

local DEFAULT_BASE_ATTACK = 40
local DEFAULT_MAX_HP = 100
local COMBAT_POWER_HP_FACTOR = 12345

local RuntimeData = {}

local function GetKey(owner)
    return owner or "__default"
end

local function GetData(owner)
    local key = GetKey(owner)
    RuntimeData[key] = RuntimeData[key] or {
        FlatAttack = {},
        PercentAttack = {},
        FlatHP = {},
        PercentHP = {},
    }
    return RuntimeData[key]
end

local function NormalizePercent(value)
    value = tonumber(value) or 0
    if math.abs(value) > 1 then
        return value / 100
    end
    return value
end

local function Round(value)
    value = tonumber(value) or 0
    return math.floor(value + 0.5)
end

local function GetAttrValue(actor, attrName, fallback)
    if actor ~= nil and UGCAttributeSystem ~= nil and UGCAttributeSystem.GetGameAttributeValue ~= nil then
        local success, result = pcall(UGCAttributeSystem.GetGameAttributeValue, actor, attrName)
        if success and result ~= nil then
            return tonumber(result) or fallback
        end
    end
    return fallback
end

local function GetAttrMax(actor, attrName, fallback)
    if actor ~= nil and UGCAttributeSystem ~= nil and UGCAttributeSystem.GetGameAttributeValueMax ~= nil then
        local success, result = pcall(UGCAttributeSystem.GetGameAttributeValueMax, actor, attrName)
        if success and result ~= nil then
            return tonumber(result) or fallback
        end
    end
    return fallback
end

function property.GetCurrentHP(playerPawn)
    return GetAttrValue(playerPawn, "Health", property.GetMaxHP(playerPawn))
end

function property.GetMaxHP(playerPawn)
    return GetAttrMax(playerPawn, "Health", DEFAULT_MAX_HP)
end

function property.GetBaseAttack(owner)
    return GetAttrValue(owner, "AttackPower", DEFAULT_BASE_ATTACK)
end

function property.SetBaseAttack(owner, value)
    if owner ~= nil and UGCAttributeSystem ~= nil and UGCAttributeSystem.SetGameAttributeValue ~= nil then
        local success = pcall(UGCAttributeSystem.SetGameAttributeValue, owner, "AttackPower", tonumber(value) or DEFAULT_BASE_ATTACK)
        if success then
            return
        end
    end
end

function property.SetAttackFlat(owner, sourceKey, value)
    local data = GetData(owner)
    data.FlatAttack[sourceKey or "default"] = tonumber(value) or 0
end

function property.AddAttackFlat(owner, sourceKey, value)
    local data = GetData(owner)
    sourceKey = sourceKey or "default"
    data.FlatAttack[sourceKey] = (tonumber(data.FlatAttack[sourceKey]) or 0) + (tonumber(value) or 0)
end

function property.SetAttackPercent(owner, sourceKey, value)
    local data = GetData(owner)
    data.PercentAttack[sourceKey or "default"] = NormalizePercent(value)
end

function property.AddAttackPercent(owner, sourceKey, value)
    local data = GetData(owner)
    sourceKey = sourceKey or "default"
    data.PercentAttack[sourceKey] = (tonumber(data.PercentAttack[sourceKey]) or 0) + NormalizePercent(value)
end

function property.RemoveAttackBonus(owner, sourceKey)
    local data = GetData(owner)
    sourceKey = sourceKey or "default"
    data.FlatAttack[sourceKey] = nil
    data.PercentAttack[sourceKey] = nil
end

function property.SetHPFlat(owner, sourceKey, value)
    local data = GetData(owner)
    data.FlatHP[sourceKey or "default"] = tonumber(value) or 0
end

function property.AddHPFlat(owner, sourceKey, value)
    local data = GetData(owner)
    sourceKey = sourceKey or "default"
    data.FlatHP[sourceKey] = (tonumber(data.FlatHP[sourceKey]) or 0) + (tonumber(value) or 0)
end

function property.SetHPPercent(owner, sourceKey, value)
    local data = GetData(owner)
    data.PercentHP[sourceKey or "default"] = NormalizePercent(value)
end

function property.AddHPPercent(owner, sourceKey, value)
    local data = GetData(owner)
    sourceKey = sourceKey or "default"
    data.PercentHP[sourceKey] = (tonumber(data.PercentHP[sourceKey]) or 0) + NormalizePercent(value)
end

function property.RemoveHPBonus(owner, sourceKey)
    local data = GetData(owner)
    sourceKey = sourceKey or "default"
    data.FlatHP[sourceKey] = nil
    data.PercentHP[sourceKey] = nil
end

function property.RemoveBonus(owner, sourceKey)
    property.RemoveAttackBonus(owner, sourceKey)
    property.RemoveHPBonus(owner, sourceKey)
end

function property.GetAttackPercent(owner)
    local total = 0
    for _, value in pairs(GetData(owner).PercentAttack) do
        total = total + (tonumber(value) or 0)
    end
    return total
end

function property.GetAttackPercentTotal(owner)
    return property.GetAttackPercent(owner)
end

function property.GetAttackPercentTotalValue(owner)
    return property.GetAttackPercent(owner) * 100
end

function property.GetHPPercent(owner)
    local total = 0
    for _, value in pairs(GetData(owner).PercentHP) do
        total = total + (tonumber(value) or 0)
    end
    return total
end

function property.GetHPPercentTotal(owner)
    return property.GetHPPercent(owner)
end

function property.GetHPPercentTotalValue(owner)
    return property.GetHPPercent(owner) * 100
end

function property.GetFlatHP(owner)
    local total = 0
    for _, value in pairs(GetData(owner).FlatHP) do
        total = total + (tonumber(value) or 0)
    end
    return total
end

function property.GetFinalMaxHP(owner)
    local baseHP = property.GetMaxHP(owner)
    local flatHP = property.GetFlatHP(owner)
    local percentHP = property.GetHPPercent(owner)
    return (baseHP + flatHP) * (1 + percentHP)
end

function property.GetFlatAttack(owner)
    local total = 0
    for _, value in pairs(GetData(owner).FlatAttack) do
        total = total + (tonumber(value) or 0)
    end
    return total
end

function property.GetAttack(owner)
    local baseAttack = property.GetBaseAttack(owner)
    local flatAttack = property.GetFlatAttack(owner)
    local percentAttack = property.GetAttackPercent(owner)
    return (baseAttack + flatAttack) * (1 + percentAttack)
end

function property.GetCombatPower(owner, playerPawn)
    local attack = property.GetAttack(owner)
    local maxHP = property.GetFinalMaxHP(playerPawn or owner)
    return attack + maxHP * COMBAT_POWER_HP_FACTOR
end

function property.GetSnapshot(owner, playerPawn)
    playerPawn = playerPawn or owner
    local currentHP = property.GetCurrentHP(playerPawn)
    local maxHP = property.GetFinalMaxHP(playerPawn)

    return {
        CurrentHP = currentHP,
        MaxHP = maxHP,
        HPPercent = maxHP > 0 and currentHP / maxHP or 0,
        Attack = property.GetAttack(owner),
        CombatPower = property.GetCombatPower(owner, playerPawn),
    }
end

function property.RefreshUI(ui, playerPawn)
    if ui == nil then
        return
    end

    playerPawn = playerPawn or UGCGameSystem.GetLocalPlayerPawn()
    if playerPawn == nil then
        return
    end

    local snapshot = property.GetSnapshot(playerPawn, playerPawn)

    if ui.ProgressBar_122 ~= nil and ui.ProgressBar_122.SetPercent ~= nil then
        ui.ProgressBar_122:SetPercent(snapshot.HPPercent)
    end
    if ui.hp ~= nil and ui.hp.SetText ~= nil then
        ui.hp:SetText(tostring(Round(snapshot.CurrentHP)) .. "/" .. tostring(Round(snapshot.MaxHP)))
    end
    if ui.gjl ~= nil and ui.gjl.SetText ~= nil then
        ui.gjl:SetText(tostring(Round(snapshot.Attack)))
    end
    if ui.TextBlock_303 ~= nil and ui.TextBlock_303.SetText ~= nil then
        ui.TextBlock_303:SetText(tostring(Round(snapshot.CombatPower)))
    end
end

return property

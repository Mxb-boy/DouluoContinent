local UGCAttributeGroup_Character = {}
local Property = UGCGameSystem.UGCRequire("Script.property.property")

local WATCHED_ATTRIBUTES = {
    Health = true,
    HealthMax = true,
    AttackPower = true,
}

local function TryNotifyPropertyChanged(...)
    local args = { ... }
    local attrName = nil
    local ownerActor = nil

    for _, value in ipairs(args) do
        if type(value) == "string" and WATCHED_ATTRIBUTES[value] then
            attrName = value
        elseif type(value) == "userdata" or type(value) == "table" then
            ownerActor = ownerActor or value
        end
    end

    if attrName ~= nil then
        Property.NotifyChanged(ownerActor)
    end
end
 
--[[
function UGCAttributeGroup_Character:ReceiveBeginPlay()
    UGCAttributeGroup_Character.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function UGCAttributeGroup_Character:ReceiveTick(DeltaTime)
    UGCAttributeGroup_Character.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function UGCAttributeGroup_Character:ReceiveEndPlay()
    UGCAttributeGroup_Character.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function UGCAttributeGroup_Character:GetReplicatedProperties()
    return
end
--]]

--[[
function UGCAttributeGroup_Character:GetAvailableServerRPCs()
    return
end
--]]

function UGCAttributeGroup_Character:GetFallingDamageRatio_Override(OriginalValue, AttributeOwnerActor)
	return OriginalValue;
end

function UGCAttributeGroup_Character:OnAttributeChanged(...)
    TryNotifyPropertyChanged(...)
end

function UGCAttributeGroup_Character:OnGameAttributeChanged(...)
    TryNotifyPropertyChanged(...)
end

function UGCAttributeGroup_Character:PostAttributeChange(...)
    TryNotifyPropertyChanged(...)
end

function UGCAttributeGroup_Character:PostAttributeChanged(...)
    TryNotifyPropertyChanged(...)
end

function UGCAttributeGroup_Character:GetAttackPower_Override(OriginalValue, AttributeOwnerActor)
    local baseAttack = tonumber(OriginalValue) or 0
    local flatAttack = 0
    local percentAttack = 0

    if Property ~= nil then
        if Property.GetFlatAttack ~= nil then
            flatAttack = tonumber(Property.GetFlatAttack(AttributeOwnerActor)) or 0
        end
        if Property.GetAttackPercent ~= nil then
            percentAttack = tonumber(Property.GetAttackPercent(AttributeOwnerActor)) or 0
        end
    end

	return (baseAttack + flatAttack) * (1 + percentAttack);
end

return UGCAttributeGroup_Character

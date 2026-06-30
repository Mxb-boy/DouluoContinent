local L_Com = {}
UGCGameSystem.UGCRequire("Script.GameAttribute.game_attribute_type")
local property = UGCGameSystem.UGCRequire("Script.property.property")

local HUNHUAN_TABLE_PATH = "Data/Table/Customized/HunHuanConfig"

function L_Com.UseHunHuan(pawn, itemID, num)
    local cfg = UGCGameSystem.GetTableDataByRowName(HUNHUAN_TABLE_PATH, tostring(itemID))
    local hp = tonumber(cfg.Add_Health) * num
    local maxhp = tonumber(cfg.Add_MaxHealth) * num
    local atk = tonumber(cfg.Add_Attack) * num

    local oldMaxHealth = UGCPawnAttrSystem.GetHealthMax(pawn)
    local oldHealth = UGCPawnAttrSystem.GetHealth(pawn)
    local newMaxHealth = oldMaxHealth + maxhp
    local newHealth = oldHealth + hp
    if newHealth > newMaxHealth then
        newHealth = newMaxHealth
    end

    UGCPawnAttrSystem.SetHealthMax(pawn, newMaxHealth)
    UGCPawnAttrSystem.SetHealth(pawn, newHealth)

    local oldAttack = property.GetBaseAttack(pawn)
    property.SetBaseAttack(pawn, oldAttack + atk)
    property.NotifyChanged(pawn)

    return true
end

return L_Com

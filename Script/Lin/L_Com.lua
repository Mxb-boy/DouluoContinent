local L_Com = {}

local HUNHUAN_TABLE_PATH = "Data/Table/Customized/HunHuanConfig"

function L_Com.UseHunHuan(pawn, itemID, num)
    local cfg = UGCGameSystem.GetTableDataByRowName(HUNHUAN_TABLE_PATH, tostring(itemID))
    if cfg == nil then
        return false
    end

    num = tonumber(num) or 1
    local maxhp = (tonumber(cfg.Add_MaxHealth) or 0) * num
    local atk = (tonumber(cfg.Add_Attack) or 0) * num

    local playerState = pawn.PlayerState
    local newBaseAttack = playerState:GetBaseAttack() + atk
    local newBaseMaxHp = playerState:GetBaseMaxHp() + maxhp
    playerState:SetBaseAttack(newBaseAttack)
    playerState:SetBaseMaxHp(newBaseMaxHp)

    return true, newBaseAttack, newBaseMaxHp
end

return L_Com

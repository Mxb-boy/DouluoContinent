local L_Com = {}

local ToastManager = UGCGameSystem.UGCRequire("Script.Lin.ToastManager")
local HUNHUAN_TABLE_PATH = "Data/Table/Customized/HunHuanConfig"
local JingJieConfig = "Data/Table/Customized/JingJieConfig"

--[[-----------------------显示小提示-----------------------]] --
function L_Com.ShowToast(text)
    ToastManager.ShowToast(text)
end

function L_Com.UseHunHuan(pawn, itemID, num)
    local cfg = UGCGameSystem.GetTableDataByRowName(HUNHUAN_TABLE_PATH, tostring(itemID))

    num = tonumber(num) or 1
    local maxhp = tonumber(cfg.Add_MaxHealth) * num
    local atk = tonumber(cfg.Add_Attack) * num

    local playerState = pawn.PlayerState
    local newBaseAttack = playerState:GetBaseAttack() + atk
    local newBaseMaxHp = playerState:GetBaseMaxHp() + maxhp
    playerState:SetBaseAttack(newBaseAttack)
    playerState:SetBaseMaxHp(newBaseMaxHp)

    return true, newBaseAttack, newBaseMaxHp
end

function L_Com:GetJingJieAddMaxHp(index)
    local cfg = UGCGameSystem.GetTableDataByRowName(JingJieConfig, tostring(index))
    return tonumber(cfg.AddMaxHp)
end

function L_Com:GetJingJieAddAtk(index)
    local cfg = UGCGameSystem.GetTableDataByRowName(JingJieConfig, tostring(index))
    return tonumber(cfg.AddAtk)
end

function L_Com:GetJingJieName(index)
    local cfg = UGCGameSystem.GetTableDataByRowName(JingJieConfig, tostring(index))
    return cfg.Name
end

return L_Com

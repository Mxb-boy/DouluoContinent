local L_Com = {}

local ToastManager = UGCGameSystem.UGCRequire("Script.Lin.ToastManager")
local HUNHUAN_TABLE_PATH = "Data/Table/Customized/HunHuanConfig"
local JingJieConfig = "Data/Table/Customized/JingJieConfig"
local LastToastTime = 0

--[[-----------------------显示小提示-----------------------]] --
function L_Com.ShowToast(text)
    local NowTime = os.time()
    if NowTime - LastToastTime < 1 then
        return
    end
    LastToastTime = NowTime
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

--[[----------------------在指定位置播放一次性粒子特效------------------------]]
function L_Com.PlayParticleAtLocation(World_Context, Particle_Path, Location, Rotation, Scale)
    local Particle_System = UE.LoadObject(Particle_Path) -- 粒子特效资源
    if not Particle_System then
        return
    end

    return UGCGameSystem.SpawnEmitterAtLocation(World_Context, Particle_System, Location, Rotation or {}, Scale or {
        X = 1,
        Y = 1,
        Z = 1
    }, true)
end

--[[----------------------播放2D音效------------------------]]
function L_Com.PlaySound2D()
    if UGCGameSystem.IsServer() then
        return
    end

    local Sound_Path = UGCGameSystem.GetUGCResourcesFullPath('Asset/WwiseEvent/EventNotice.EventNotice') -- 音效资源路径

    local Sound_Asset = UE.LoadObject(Sound_Path)

    return UGCSoundManagerSystem.PlaySound2D(Sound_Asset)
end

--[[----------------------购买商城商品------------------------]]
function L_Com.BuyShopProduct(Product_ID, Buy_Count)
    if ShopV2Manager == nil or ShopV2Manager.CheckBackpackBeforePurchase == nil or
        ShopV2Manager:CheckBackpackBeforePurchase() == false then
        return nil
    end
    Buy_Count = Buy_Count or 1 -- 购买数量
    local Product_Data = ShopV2Manager:GetProductConfigData(Product_ID) -- 商品信息
    local Object_Data = ShopV2Manager:GetItemConfigData(Product_Data.ItemID) -- 物品信息

    return UGCCommoditySystem.BuyUGCCommodity2(Product_ID, Object_Data.ItemIcon, Object_Data.ItemDesc, Buy_Count)
end
return L_Com

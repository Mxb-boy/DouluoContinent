---@class Cola_C:UGCItemHandle_ConsumeBase_C
--Edit Below--
local Cola = {}

-- 回血量配置（固定值，超过最大血量时自动截断）
local HEAL_AMOUNT = 100

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function Cola:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return Cola.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品
-- function Cola:HandleDrop(InCount, Reason)
--    return Cola.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function Cola:HandleTake(TakeCount, TotalCount)
--    return Cola.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function Cola:HandleUse(Target, Reason)
--    return Cola.SuperClass.HandleUse(self, Target, Reason)
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function Cola:HandleDisuse(Reason)
--    return Cola.SuperClass.HandleDisuse(self, Reason)
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function Cola:HandleTryDisuse(Reason)
--    return Cola.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function Cola:HandleEnable(bEnable)
--    Cola.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function Cola:HanldeCleared()
--    return Cola.SuperClass.HanldeCleared(self)
-- end
]]--

--[[V2背包事件]]--

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return bool 物品是否能够被使用
function Cola:CanUseV2()
    return Cola.SuperClass.CanUseV2(self)
end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
--- 使用核子可乐后恢复固定血量
function Cola:OnUseV2()
    Cola.SuperClass.OnUseV2(self)

    -- 获取背包组件 → 获取 PlayerController → 获取 PlayerPawn
    local OwnBackpackComponent = UGCItemSystemV2.GetOwnBackpackComponent(self)
    if OwnBackpackComponent == nil then
        print("[Cola:OnUseV2] Failed to get OwnBackpackComponent")
        return
    end

    local PlayerController = OwnBackpackComponent:GetOwner()
    if PlayerController == nil then
        print("[Cola:OnUseV2] Failed to get PlayerController")
        return
    end

    local PlayerPawn = UGCGameSystem.GetPlayerPawnByPlayerController(PlayerController)
    if PlayerPawn == nil then
        print("[Cola:OnUseV2] Failed to get PlayerPawn")
        return
    end

    -- 当前血量 + 最大血量
    local currentHP = UGCPawnAttrSystem.GetHealth(PlayerPawn)
    local maxHP = UGCPawnAttrSystem.GetHealthMax(PlayerPawn)
    if currentHP == nil or maxHP == nil then
        print("[Cola:OnUseV2] Failed to get HP, current=" .. tostring(currentHP) .. " max=" .. tostring(maxHP))
        return
    end

    -- 计算回血后血量（不超过最大血量）
    local newHP = math.min(currentHP + HEAL_AMOUNT, maxHP)
    UGCPawnAttrSystem.SetHealth(PlayerPawn, newHP)

    print("[Cola:OnUseV2] Heal " .. tostring(HEAL_AMOUNT)
        .. " (HP " .. tostring(currentHP) .. " -> " .. tostring(newHP)
        .. ", max=" .. tostring(maxHP) .. ")")
end

return Cola

---@class CH_best_2_C:UGCItemHandle_ConsumeBase_C
--Edit Below--
local CH_best_2 = {}

function CH_best_2:OnUseV2()
    local itemID = tonumber(self.ItemID)
    local ownBackpackComponent = UGCItemSystemV2.GetOwnBackpackComponent(self)
    local player = ownBackpackComponent and ownBackpackComponent:GetOwner() or nil
    if player ~= nil then
        local count = UGCBackpackSystemV2.GetItemCountV2(player, itemID)
        if player.UnlockTitle ~= nil then
            player:UnlockTitle(6)
        else
            UnrealNetwork.CallUnrealRPC(player, player, "Client_UnlockTitle", 6)
        end
        UGCBackpackSystemV2.RemoveItemV2(player, itemID, count)
    end
end

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function CH_best_2:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return CH_best_2.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function CH_best_2:HandleDrop(InCount, Reason)
--    return CH_best_2.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function CH_best_2:HandleTake(TakeCount, TotalCount)
--    return CH_best_2.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function CH_best_2:HandleUse(Target, Reason)
--    return CH_best_2.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function CH_best_2:HandleDisuse(Reason)
--    return CH_best_2.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function CH_best_2:HandleTryDisuse(Reason)
--    return CH_best_2.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function CH_best_2:HandleEnable(bEnable)
--    CH_best_2.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function CH_best_2:HanldeCleared()
--    return CH_best_2.SuperClass.HanldeCleared(self)
-- end
]]--

--[[V2背包事件]]--
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function CH_best_2:CanCreateItemHandleV2()
--     return CH_best_2.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function CH_best_2:OnCreateItemHandleV2()
--     CH_best_2.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function CH_best_2:CanDestoryItemHandleV2()
--     return CH_best_2.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function CH_best_2:OnDestoryItemHandleV2()
--     CH_best_2.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function CH_best_2:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return CH_best_2.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function CH_best_2:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     CH_best_2.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function CH_best_2:CanUseV2()
--     return CH_best_2.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function CH_best_2:OnUseV2()
--     CH_best_2.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function CH_best_2:OnDisuseV2()
--     CH_best_2.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function CH_best_2:UGC_OnStartUse()
--     CH_best_2.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function CH_best_2:UGC_OnStopUse(Reason)
    CH_best_2.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]]--

return CH_best_2

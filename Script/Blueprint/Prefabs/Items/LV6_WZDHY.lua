---@class LV6_WZDHY_C:UGCItemHandle_ConsumeBase_C
--Edit Below--
local LV6_WZDHY = {} 

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function LV6_WZDHY:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return LV6_WZDHY.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function LV6_WZDHY:HandleDrop(InCount, Reason)
--    return LV6_WZDHY.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function LV6_WZDHY:HandleTake(TakeCount, TotalCount)
--    return LV6_WZDHY.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function LV6_WZDHY:HandleUse(Target, Reason)
--    return LV6_WZDHY.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function LV6_WZDHY:HandleDisuse(Reason)
--    return LV6_WZDHY.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function LV6_WZDHY:HandleTryDisuse(Reason)
--    return LV6_WZDHY.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function LV6_WZDHY:HandleEnable(bEnable)
--    LV6_WZDHY.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function LV6_WZDHY:HanldeCleared()
--    return LV6_WZDHY.SuperClass.HanldeCleared(self)
-- end
]]--

--[[V2背包事件]]--
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function LV6_WZDHY:CanCreateItemHandleV2()
--     return LV6_WZDHY.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function LV6_WZDHY:OnCreateItemHandleV2()
--     LV6_WZDHY.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function LV6_WZDHY:CanDestoryItemHandleV2()
--     return LV6_WZDHY.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function LV6_WZDHY:OnDestoryItemHandleV2()
--     LV6_WZDHY.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function LV6_WZDHY:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return LV6_WZDHY.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function LV6_WZDHY:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     LV6_WZDHY.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function LV6_WZDHY:CanUseV2()
--     return LV6_WZDHY.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function LV6_WZDHY:OnUseV2()
--     LV6_WZDHY.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function LV6_WZDHY:OnDisuseV2()
--     LV6_WZDHY.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function LV6_WZDHY:UGC_OnStartUse()
--     LV6_WZDHY.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function LV6_WZDHY:UGC_OnStopUse(Reason)
    LV6_WZDHY.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]]--

return LV6_WZDHY
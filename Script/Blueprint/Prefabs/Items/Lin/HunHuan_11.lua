---@class HunHuan_11_C:HunHuan_01_C
--Edit Below--
local HunHuan_11 = {} 

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function HunHuan_11:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return HunHuan_11.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function HunHuan_11:HandleDrop(InCount, Reason)
--    return HunHuan_11.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function HunHuan_11:HandleTake(TakeCount, TotalCount)
--    return HunHuan_11.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function HunHuan_11:HandleUse(Target, Reason)
--    return HunHuan_11.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function HunHuan_11:HandleDisuse(Reason)
--    return HunHuan_11.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function HunHuan_11:HandleTryDisuse(Reason)
--    return HunHuan_11.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function HunHuan_11:HandleEnable(bEnable)
--    HunHuan_11.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function HunHuan_11:HanldeCleared()
--    return HunHuan_11.SuperClass.HanldeCleared(self)
-- end
]]--

--[[V2背包事件]]--
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function HunHuan_11:CanCreateItemHandleV2()
--     return HunHuan_11.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function HunHuan_11:OnCreateItemHandleV2()
--     HunHuan_11.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function HunHuan_11:CanDestoryItemHandleV2()
--     return HunHuan_11.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function HunHuan_11:OnDestoryItemHandleV2()
--     HunHuan_11.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function HunHuan_11:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return HunHuan_11.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function HunHuan_11:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     HunHuan_11.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function HunHuan_11:CanUseV2()
--     return HunHuan_11.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function HunHuan_11:OnUseV2()
--     HunHuan_11.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function HunHuan_11:OnDisuseV2()
--     HunHuan_11.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function HunHuan_11:UGC_OnStartUse()
--     HunHuan_11.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function HunHuan_11:UGC_OnStopUse(Reason)
    HunHuan_11.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]]--

return HunHuan_11
---@class LV6_DHY_C:Template_ItemHandle_C
--Edit Below--
local LV6_DHY = {} 

--[[V2背包事件]]--
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function LV6_DHY:CanCreateItemHandleV2()
--     return LV6_DHY.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function LV6_DHY:OnCreateItemHandleV2()
--     LV6_DHY.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function LV6_DHY:CanDestoryItemHandleV2()
--     return LV6_DHY.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function LV6_DHY:OnDestoryItemHandleV2()
--     LV6_DHY.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function LV6_DHY:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return LV6_DHY.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function LV6_DHY:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     LV6_DHY.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function LV6_DHY:CanUseV2()
--     return LV6_DHY.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function LV6_DHY:OnUseV2()
--     LV6_DHY.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function LV6_DHY:OnDisuseV2()
--     LV6_DHY.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function LV6_DHY:UGC_OnStartUse()
--     LV6_DHY.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function LV6_DHY:UGC_OnStopUse(Reason)
    LV6_DHY.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]]--

return LV6_DHY
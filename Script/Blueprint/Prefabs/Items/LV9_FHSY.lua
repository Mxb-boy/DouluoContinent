---@class LV9_FHSY_C:Template_ItemHandle_C
--Edit Below--
local LV9_FHSY = {} 

--[[V2背包事件]]--
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function LV9_FHSY:CanCreateItemHandleV2()
--     return LV9_FHSY.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function LV9_FHSY:OnCreateItemHandleV2()
--     LV9_FHSY.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function LV9_FHSY:CanDestoryItemHandleV2()
--     return LV9_FHSY.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function LV9_FHSY:OnDestoryItemHandleV2()
--     LV9_FHSY.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function LV9_FHSY:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return LV9_FHSY.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function LV9_FHSY:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     LV9_FHSY.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function LV9_FHSY:CanUseV2()
--     return LV9_FHSY.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function LV9_FHSY:OnUseV2()
--     LV9_FHSY.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function LV9_FHSY:OnDisuseV2()
--     LV9_FHSY.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function LV9_FHSY:UGC_OnStartUse()
--     LV9_FHSY.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function LV9_FHSY:UGC_OnStopUse(Reason)
    LV9_FHSY.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]]--

return LV9_FHSY
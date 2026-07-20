---@class PTCSJ_C:UGCItemHandle_ConsumeBase_C
--Edit Below--
---@class PTCSJ_C:UGCItemHandle_ConsumeBase_C
-- Edit Below--
local PTCSJ = {}

function PTCSJ:OnUseV2()
    PTCSJ.SuperClass.OnUseV2(self);

    --[[----------------------执行传送逻辑，传送到塔------------------------]] --

    local CSPoint = 201
    local OwnBackpackComponent = UGCItemSystemV2.GetOwnBackpackComponent(self)
    local PlayerController = OwnBackpackComponent:GetOwner()
    if PlayerController then
        if PlayerController:Server_TeleportToSpawn(CSPoint) then
            PlayerController.bFeiTowerHidden = true
            UnrealNetwork.CallUnrealRPC(PlayerController, PlayerController, "Client_SetFeiTowerButtonsHidden", 1)
            UGCBackpackSystemV2.RemoveItemV2(PlayerController, tonumber(self.ItemID), 1)
        end
    end
end
--[[V2背包事件]] --
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function PTCSJ:CanCreateItemHandleV2()
--     return PTCSJ.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function PTCSJ:OnCreateItemHandleV2()
--     PTCSJ.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function PTCSJ:CanDestoryItemHandleV2()
--     return PTCSJ.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function PTCSJ:OnDestoryItemHandleV2()
--     PTCSJ.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function PTCSJ:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return PTCSJ.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function PTCSJ:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     PTCSJ.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function PTCSJ:CanUseV2()
--     return PTCSJ.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function PTCSJ:OnUseV2()
--     PTCSJ.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function PTCSJ:OnDisuseV2()
--     PTCSJ.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function PTCSJ:UGC_OnStartUse()
--     PTCSJ.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function PTCSJ:UGC_OnStopUse(Reason)
    PTCSJ.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]] --

return PTCSJ

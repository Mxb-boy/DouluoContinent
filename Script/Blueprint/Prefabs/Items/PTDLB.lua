---@class PTDLB_C:UGCItemHandle_ConsumeBase_C
-- Edit Below--
local PTDLB = {}

function PTDLB:OnUseV2()
    PTDLB.SuperClass.OnUseV2(self);

    --[[-------------------测试生成掉落---------------------------]] --
    local ownBackpackComponent = UGCItemSystemV2.GetOwnBackpackComponent(self)
    local player = ownBackpackComponent:GetOwner()
    local pawn = UGCGameSystem.GetPlayerPawnByPlayerController(player) or player
    local PlayerLoc = pawn:K2_GetActorLocation()

    SpawnNearPlayer(PlayerLoc, 8310035, math.random(6, 10))
    SpawnNearPlayer(PlayerLoc, 8310065, 1)
    SpawnNearPlayer(PlayerLoc, 8310042, math.random(1, 2))
    SpawnNearPlayer(PlayerLoc, 8310045, 1)

    local ExtraDrops = {
        { ItemID = 8310048, Count = 66 },
        { ItemID = 8310049, Count = 22 },
        { ItemID = 8310051, Count = 12 },
        { ItemID = 8310053, Count = 6 },
    }
    local ExtraDrop = ExtraDrops[math.random(1, #ExtraDrops)]
    SpawnNearPlayer(PlayerLoc, ExtraDrop.ItemID, ExtraDrop.Count)
    UGCBackpackSystemV2.RemoveItemV2(player, tonumber(self.ItemID), 1)
end
-- 辅助函数：在玩家周围随机位置掉落
function SpawnNearPlayer(PlayerLoc, ItemID, Count)
    local angle = math.random() * 2 * math.pi
    local dist = math.random(500, 1000) -- 这个是随机的范围
    local x = PlayerLoc.X + math.cos(angle) * dist
    local y = PlayerLoc.Y + math.sin(angle) * dist
    local z = PlayerLoc.Z
    local pos = Vector.New(x, y, z)
    return UGCItemSystemV2.SpawnPickupWrapper(pos, ItemID, Count)
end
--[[经典背包事件]] --
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function PTDLB:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return PTDLB.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function PTDLB:HandleDrop(InCount, Reason)
--    return PTDLB.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function PTDLB:HandleTake(TakeCount, TotalCount)
--    return PTDLB.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function PTDLB:HandleUse(Target, Reason)
--    return PTDLB.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function PTDLB:HandleDisuse(Reason)
--    return PTDLB.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function PTDLB:HandleTryDisuse(Reason)
--    return PTDLB.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function PTDLB:HandleEnable(bEnable)
--    PTDLB.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function PTDLB:HanldeCleared()
--    return PTDLB.SuperClass.HanldeCleared(self)
-- end
]] --

--[[V2背包事件]] --
--[[
--- func 能否创建物品Handle(服务端生效)
---@return bool @是否允许创建物品Handle, 若不允许，物品也将创建失败
-- function PTDLB:CanCreateItemHandleV2()
--     return PTDLB.SuperClass.CanCreateItemHandleV2(self);
-- end

--- func 当创建物品Handle后回调，可重载并自定义(服务端生效)
--  function PTDLB:OnCreateItemHandleV2()
--     PTDLB.SuperClass.OnCreateItemHandleV2(self);
--  end

--- func 能否销毁物品Handle，可重载并自定义(服务端生效)
---@return bool 是否允许销毁Handle, 若不允许，物品移除或丢弃也可能失败
-- function PTDLB:CanDestoryItemHandleV2()
--     return PTDLB.SuperClass.CanDestoryItemHandleV2(self);
-- end

--- func 销毁物品Handle前回调，可重载并自定义(服务端生效)
-- function PTDLB:OnDestoryItemHandleV2()
--     PTDLB.SuperClass.OnDestoryItemHandleV2(self);
-- end

--- func 能否更新此物品实例，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
---@return 是否允许物品数量更新，若不允许，物品添加或移除操作可能失败
-- function PTDLB:CanUpdateItemCountV2(NewItemCount, OldItemCount)
--     return PTDLB.SuperClass.CanUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 物品数量更新后回调，可重载并自定义(服务端生效)
---@param NewItemCount number 新物品数量
---@param OldItemCount number 旧物品数量
-- function PTDLB:OnUpdateItemCountV2(NewItemCount, OldItemCount)
--     PTDLB.SuperClass.OnUpdateItemCountV2(self, NewItemCount, OldItemCount);
-- end

--- func 能否使用物品，可重载并自定义(服务端生效)
---@return 物品是否能够被使用
-- function PTDLB:CanUseV2()
--     return PTDLB.SuperClass.CanUseV2(self);
-- end

--- func 当物品被使用回调，可重载并自定义(服务端生效)
-- function PTDLB:OnUseV2()
--     PTDLB.SuperClass.OnUseV2(self);
-- end

--- func 当物品被取消使用，与UseItem对应，用于清理状态，应当支持多次调用，不产生额外副作用，移除物品时自动调用，可重载并自定义(服务端生效)
-- function PTDLB:OnDisuseV2()
--     PTDLB.SuperClass.OnDisuseV2(self);
-- end

--- func 当物品开始使用时回调，可重载并自定义(服务端生效)
-- function PTDLB:UGC_OnStartUse()
--     PTDLB.SuperClass.UGC_OnStartUse(self)
-- end

--- func 当物品停止使用时回调，可重载并自定义(服务端生效)，在OnUseV2后调用
-- function PTDLB:UGC_OnStopUse(Reason)
    PTDLB.SuperClass.UGC_OnStopUse(self, Reason)
-- end
]] --

return PTDLB

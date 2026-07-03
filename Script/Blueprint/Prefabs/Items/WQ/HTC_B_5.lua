---@class HTC_B_5_C:Template_Melee_TangDao_Handle_C
--Edit Below--
local HTC_B = {} 

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function HTC_B:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return HTC_B.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function HTC_B:HandleDrop(InCount, Reason)
--    return HTC_B.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function HTC_B:HandleTake(TakeCount, TotalCount)
--    return HTC_B.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function HTC_B:HandleUse(Target, Reason)
--    return HTC_B.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function HTC_B:HandleDisuse(Reason)
--    return HTC_B.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function HTC_B:HandleTryDisuse(Reason)
--    return HTC_B.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function HTC_B:HandleEnable(bEnable)
--    HTC_B.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function HTC_B:HanldeCleared()
--    return HTC_B.SuperClass.HanldeCleared(self)
-- end
]]--


return HTC_B
---@class XJWQ_B_6_C:Template_Melee_TangDao_Handle_C
--Edit Below--
local XJWQ_B_6 = {} 

--[[经典背包事件]]--
--[[
--- func 处理物品的拾取(服务端生效)
---@return bool @是否拾取该物品, 返回true才能拾取进背包
-- function XJWQ_B_6:HandlePickup(ItemContainer, PickupInfo, Reason)
--    return XJWQ_B_6.SuperClass.HandlePickup(self, ItemContainer, PickupInfo, Reason)
-- end

--- func 处理物品的丢弃(服务端生效)
---@return bool @是否丢弃该物品, 返回true才会丢弃
-- function XJWQ_B_6:HandleDrop(InCount, Reason)
--    return XJWQ_B_6.SuperClass.HandleDrop(self, InCount, Reason)
-- end

--- func 处理物品的取出(服务端生效)
---@return number @可取出物品数量
-- function XJWQ_B_6:HandleTake(TakeCount, TotalCount)
--    return XJWQ_B_6.SuperClass.HandleTake(self, TakeCount, TotalCount)
-- end

--- func 处理物品的使用(服务端生效)
---@return bool @使用是否成功
-- function XJWQ_B_6:HandleUse(Target, Reason)
--    return XJWQ_B_6.SuperClass.HandleUse(self, Target, Reason) 
-- end

--- func 处理物品的取消使用(服务端生效)
---@return bool @取消使用是否成功
-- function XJWQ_B_6:HandleDisuse(Reason)
--    return XJWQ_B_6.SuperClass.HandleDisuse(self, Reason) 
-- end

--- func 尝试取消使用物品，仅尝试(服务端生效)
---@return bool @物品能否取消使用
-- function XJWQ_B_6:HandleTryDisuse(Reason)
--    return XJWQ_B_6.SuperClass.HandleTryDisuse(self, Reason)
-- end

--- func 处理物品的有效性(服务端生效)
-- function XJWQ_B_6:HandleEnable(bEnable)
--    XJWQ_B_6.SuperClass.HandleEnable(self, bEnable)
-- end

--- func 处理物品的清除(服务端生效)
---@return bool @清除物品是否成功
-- function XJWQ_B_6:HanldeCleared()
--    return XJWQ_B_6.SuperClass.HanldeCleared(self)
-- end
]]--


return XJWQ_B_6
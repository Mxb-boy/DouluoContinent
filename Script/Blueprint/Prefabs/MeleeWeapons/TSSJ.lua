---@class TSSJ_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
--Edit Below--
local HTC = {}
 
--[[
function HTC:ReceiveBeginPlay()
    HTC.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function HTC:ReceiveTick(DeltaTime)
    HTC.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function HTC:ReceiveEndPlay()
    HTC.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function HTC:GetReplicatedProperties()
    return
end
--]]

--[[
function HTC:GetAvailableServerRPCs()
    return
end
--]]

return HTC
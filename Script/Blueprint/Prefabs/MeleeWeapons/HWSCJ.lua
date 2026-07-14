---@class HWSCJ_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
--Edit Below--
local HWSCJ = {}
 
--[[
function HWSCJ:ReceiveBeginPlay()
    HWSCJ.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function HWSCJ:ReceiveTick(DeltaTime)
    HWSCJ.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function HWSCJ:ReceiveEndPlay()
    HWSCJ.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function HWSCJ:GetReplicatedProperties()
    return
end
--]]

--[[
function HWSCJ:GetAvailableServerRPCs()
    return
end
--]]

return HWSCJ
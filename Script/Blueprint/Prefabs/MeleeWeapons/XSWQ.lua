---@class XSWQ_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
--Edit Below--
local XSWQ = {}

local WEAPON_CONFIG_ID = 1005

function XSWQ:ReceiveBeginPlay()
    if XSWQ.SuperClass ~= nil and XSWQ.SuperClass.ReceiveBeginPlay ~= nil then
        XSWQ.SuperClass.ReceiveBeginPlay(self)
    end
    self.WeaponConfigID = WEAPON_CONFIG_ID
end

--[[
function XSWQ:ReceiveTick(DeltaTime)
    XSWQ.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function XSWQ:ReceiveEndPlay()
    XSWQ.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function XSWQ:GetReplicatedProperties()
    return
end
--]]

--[[
function XSWQ:GetAvailableServerRPCs()
    return
end
--]]

return XSWQ

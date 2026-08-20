---@class HTC_1_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
--Edit Below--
local HTC = {}

local WEAPON_CONFIG_ID = 1003

function HTC:ReceiveBeginPlay()
    if HTC.SuperClass ~= nil and HTC.SuperClass.ReceiveBeginPlay ~= nil then
        HTC.SuperClass.ReceiveBeginPlay(self)
    end
    self.WeaponConfigID = WEAPON_CONFIG_ID
end

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

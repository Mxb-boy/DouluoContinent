---@class LSSL_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
--Edit Below--
local LSSL = {}

local WEAPON_CONFIG_ID = 1004

function LSSL:ReceiveBeginPlay()
    if LSSL.SuperClass ~= nil and LSSL.SuperClass.ReceiveBeginPlay ~= nil then
        LSSL.SuperClass.ReceiveBeginPlay(self)
    end
    self.WeaponConfigID = WEAPON_CONFIG_ID
end

--[[
function LSSL:ReceiveTick(DeltaTime)
    LSSL.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function LSSL:ReceiveEndPlay()
    LSSL.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function LSSL:GetReplicatedProperties()
    return
end
--]]

--[[
function LSSL:GetAvailableServerRPCs()
    return
end
--]]

return LSSL

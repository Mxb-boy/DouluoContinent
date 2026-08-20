---@class HWSCJ_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
--Edit Below--
local HWSCJ = {}

local WEAPON_CONFIG_ID = 1001

function HWSCJ:ReceiveBeginPlay()
    if HWSCJ.SuperClass ~= nil and HWSCJ.SuperClass.ReceiveBeginPlay ~= nil then
        HWSCJ.SuperClass.ReceiveBeginPlay(self)
    end
    self.WeaponConfigID = WEAPON_CONFIG_ID
end

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

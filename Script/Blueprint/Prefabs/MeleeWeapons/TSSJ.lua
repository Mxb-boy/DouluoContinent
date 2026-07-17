---@class TSSJ_C:BP_UGC_MeleeWeap_TangDao_C
---@field WeaponLevel int32
---@field WeaponLevel_0 int32
---@field WeaponConfigID int32
--Edit Below--
local TSSJ = {}

local WEAPON_CONFIG_ID = 1002

function TSSJ:ReceiveBeginPlay()
    if TSSJ.SuperClass ~= nil and TSSJ.SuperClass.ReceiveBeginPlay ~= nil then
        TSSJ.SuperClass.ReceiveBeginPlay(self)
    end
    self.WeaponConfigID = WEAPON_CONFIG_ID
end

--[[
function TSSJ:ReceiveTick(DeltaTime)
    TSSJ.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function TSSJ:ReceiveEndPlay()
    TSSJ.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function TSSJ:GetReplicatedProperties()
    return
end
--]]

--[[
function TSSJ:GetAvailableServerRPCs()
    return
end
--]]

return TSSJ

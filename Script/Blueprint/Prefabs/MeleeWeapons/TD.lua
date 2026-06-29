---@class TD_C:BP_UGC_MeleeWeap_TangDao_C
--Edit Below--
local TD = {}
 
--[[
function TD:ReceiveBeginPlay()
    TD.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function TD:ReceiveTick(DeltaTime)
    TD.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function TD:ReceiveEndPlay()
    TD.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function TD:GetReplicatedProperties()
    return
end
--]]

--[[
function TD:GetAvailableServerRPCs()
    return
end
--]]

return TD
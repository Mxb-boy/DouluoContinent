local HWSCJ_02 = {}
 
--[[
function HWSCJ_02:ReceiveBeginPlay()
    HWSCJ_02.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function HWSCJ_02:ReceiveTick(DeltaTime)
    HWSCJ_02.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function HWSCJ_02:ReceiveEndPlay()
    HWSCJ_02.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function HWSCJ_02:GetReplicatedProperties()
    return
end
--]]

--[[
function HWSCJ_02:GetAvailableServerRPCs()
    return
end
--]]

return HWSCJ_02
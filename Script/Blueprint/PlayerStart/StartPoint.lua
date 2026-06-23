local StartPoint = {}
 
--[[
function StartPoint:ReceiveBeginPlay()
    StartPoint.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function StartPoint:ReceiveTick(DeltaTime)
    StartPoint.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function StartPoint:ReceiveEndPlay()
    StartPoint.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function StartPoint:GetReplicatedProperties()
    return
end
--]]

--[[
function StartPoint:GetAvailableServerRPCs()
    return
end
--]]

return StartPoint
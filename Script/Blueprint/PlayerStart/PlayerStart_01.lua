local PlayerStart_01 = {}
 
--[[
function PlayerStart_01:ReceiveBeginPlay()
    PlayerStart_01.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function PlayerStart_01:ReceiveTick(DeltaTime)
    PlayerStart_01.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function PlayerStart_01:ReceiveEndPlay()
    PlayerStart_01.SuperClass.ReceiveEndPlay(self) 
end
--]]

return PlayerStart_01
local PlayerStart_01 = {}

MAX_PLAYER_BORN_POINT_ID = 99

function PlayerStart_01:GetUGCModePlayerStart(Controller)
    local PlayerState = Controller and Controller.PlayerState
    local bornPointID = PlayerState and PlayerState.TeamID or 1
    if bornPointID > MAX_PLAYER_BORN_POINT_ID then
        bornPointID = 1
    end

    local PlayerStart = self:FindPlayerStartByBornPointID(bornPointID, true)
    if PlayerStart then
        PlayerStart:SetMarkOccupied()
    end
    return PlayerStart
end
 
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

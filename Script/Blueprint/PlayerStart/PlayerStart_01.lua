local PlayerStart_01 = {}

function PlayerStart_01:GetUGCModePlayerStart(Controller)
    if UGCGameSystem.GameState:HasAuthority() == true then
    else
    end

    local SelectedPlayerStart = self:FindPlayerStartByBornPointID(1, false);

    if SelectedPlayerStart ~= nil then
        return SelectedPlayerStart;
    end

    return nil;
end

return PlayerStart_01

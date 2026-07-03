local PlayerStart_01 = {}

function PlayerStart_01:GetUGCModePlayerStart(Controller)
    if UGCGameSystem.GameState:HasAuthority() == true then
        print("MMG_Lua PlayerStart_01:GetUGCModePlayerStart Server");
    else
        print("MMG_Lua PlayerStart_01:GetUGCModePlayerStart Client");
    end

    local SelectedPlayerStart = self:FindPlayerStartByBornPointID(1, false);

    if SelectedPlayerStart ~= nil then
        print(string.format("PlayerStart_01:GetUGCModePlayerStart SelectedPlayerStart[%s] BornID[%d] PlayerID[%s]",
            KismetSystemLibrary.GetObjectName(SelectedPlayerStart), SelectedPlayerStart.PlayerBornPointID,
            Controller.PlayerKey));
        return SelectedPlayerStart;
    end

    print("Error: PlayerStart_01:GetUGCModePlayerStart SelectedPlayerStart is nil!");
    return nil;
end

return PlayerStart_01

local PlayerStart_01 = {}
 

function PlayerStart_01:GetUGCModePlayerStart(Controller)
    local SelectedPlayerStart=self:FindPlayerStartByBornPointID(1,false);
    if SelectedPlayerStart ~=nil then
        SelectedPlayerStart:SetMarkOccupied();
        self.CameraChange()
        return SelectedPlayerStart;
    end
return nil;
end

function  PlayerStart_01:CameraChange()
    
end


return PlayerStart_01
--[[-------------------这里放角色状态，重连后可以恢复数据---------------------------]]--
local UGCPlayerState = {
    HunHuan=1,--大魂环
    HunHuan_Little=1,--小等级
}

function UGCPlayerState:GetReplicatedProperties()
    return {
        "HunHuan",
        "HunHuan_Little",
    }
end

function UGCPlayerState:GetHunHuan()
    return self.HunHuan


end
function UGCPlayerState:GetHunHuan_Little()
    return self.HunHuan_Little
end

function UGCPlayerState:SetHunHuan(value)
     self.HunHuan=value
    self:CallRefreshZhanli()
end

function UGCPlayerState:SetHunHuan_Little(value)
     self.HunHuan_Little=value
    self:CallRefreshZhanli()
end

function  UGCPlayerState:CallRefreshZhanli()
    local playerPawn = UGCGameSystem.GetLocalPlayerPawn()
    if playerPawn ~= nil then
        UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(playerPawn, L_Enum_Event.Enum.ReFreshZhanLi_01)
    end
end


return UGCPlayerState

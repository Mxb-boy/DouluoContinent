---@class CB_2_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_2 = {}
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

function CB_2:ReceiveBeginPlay()
    CB_2.SuperClass.ReceiveBeginPlay(self)
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(14)
    end
end

--[[
function CB_2:ReceiveTick(DeltaTime)
    CB_2.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

function CB_2:ReceiveEndPlay()
    CB_2.SuperClass.ReceiveEndPlay(self) 
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(0)
    end
end

--[[
function CB_2:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_2:GetAvailableServerRPCs()
    return
end
--]]

return CB_2

---@class cb_6_C:AActor
---@field cb_1 USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local cb_6 = {}
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

function cb_6:ReceiveBeginPlay()
    cb_6.SuperClass.ReceiveBeginPlay(self)
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(24)
    end
end

--[[
function cb_6:ReceiveTick(DeltaTime)
    cb_6.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

function cb_6:ReceiveEndPlay()
    cb_6.SuperClass.ReceiveEndPlay(self) 
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(0)
    end
end

--[[
function cb_6:GetReplicatedProperties()
    return
end
--]]

--[[
function cb_6:GetAvailableServerRPCs()
    return
end
--]]

return cb_6

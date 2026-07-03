---@class cb_1_C:AActor
---@field cb_1 USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local cb_1 = {}
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

function cb_1:ReceiveBeginPlay()
    cb_1.SuperClass.ReceiveBeginPlay(self)
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(2)
    end
end

--[[
function cb_1:ReceiveTick(DeltaTime)
    cb_1.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

function cb_1:ReceiveEndPlay()
    cb_1.SuperClass.ReceiveEndPlay(self) 
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(0)
    end
end

--[[
function cb_1:GetReplicatedProperties()
    return
end
--]]

--[[
function cb_1:GetAvailableServerRPCs()
    return
end
--]]

return cb_1

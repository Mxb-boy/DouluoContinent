---@class CB_T5_C:AActor
---@field SkeletalMesh USkeletalMeshComponent
---@field DefaultSceneRoot USceneComponent
--Edit Below--
local CB_T5 = {}
local StateMgr = UGCGameSystem.UGCRequire("Script.Lin.StateMgr")

function CB_T5:ReceiveBeginPlay()
    CB_T5.SuperClass.ReceiveBeginPlay(self)
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(5)
    end
end

--[[
function CB_T5:ReceiveTick(DeltaTime)
    CB_T5.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

function CB_T5:ReceiveEndPlay()
    CB_T5.SuperClass.ReceiveEndPlay(self) 
    if StateMgr ~= nil and StateMgr.UI ~= nil then
        StateMgr:ChiBangTextShow(0)
    end
end

--[[
function CB_T5:GetReplicatedProperties()
    return
end
--]]

--[[
function CB_T5:GetAvailableServerRPCs()
    return
end
--]]

return CB_T5

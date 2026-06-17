---@class HWSCJ_3_C:PESkillProjectileBase
---@field StaticMesh UStaticMeshComponent
---@field Capsule UCapsuleComponent
--Edit Below--
local HWSCJ_3 = {}
 
--[[
function HWSCJ_3:ReceiveBeginPlay()
    HWSCJ_3.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function HWSCJ_3:ReceiveTick(DeltaTime)
    HWSCJ_3.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function HWSCJ_3:ReceiveEndPlay()
    HWSCJ_3.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function HWSCJ_3:GetReplicatedProperties()
    return
end
--]]

--[[
function HWSCJ_3:GetAvailableServerRPCs()
    return
end
--]]

return HWSCJ_3
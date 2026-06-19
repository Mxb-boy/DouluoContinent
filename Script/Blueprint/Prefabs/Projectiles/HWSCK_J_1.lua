---@class HWSCK_J_1_C:PESkillProjectileBase
---@field StaticMesh3 UStaticMeshComponent
---@field StaticMesh2 UStaticMeshComponent
---@field StaticMesh1 UStaticMeshComponent
---@field StaticMesh UStaticMeshComponent
---@field ParticleSystem UParticleSystemComponent
---@field Sphere USphereComponent
--Edit Below--
local HWSCJ = {}
 
--[[
function HWSCJ:ReceiveBeginPlay()
    HWSCJ.SuperClass.ReceiveBeginPlay(self)
end
--]]

--[[
function HWSCJ:ReceiveTick(DeltaTime)
    HWSCJ.SuperClass.ReceiveTick(self, DeltaTime)
end
--]]

--[[
function HWSCJ:ReceiveEndPlay()
    HWSCJ.SuperClass.ReceiveEndPlay(self) 
end
--]]

--[[
function HWSCJ:GetReplicatedProperties()
    return
end
--]]

--[[
function HWSCJ:GetAvailableServerRPCs()
    return
end
--]]

return HWSCJ
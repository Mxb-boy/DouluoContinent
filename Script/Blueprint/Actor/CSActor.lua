---@class CSActor_C:AActor
---@field Box UBoxComponent
---@field StaticMesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field CSPoint int32
--Edit Below--
local CSActor = {}
local L_Event = UGCGameSystem.UGCRequire('Script.Lin.L_Event')
function  CSActor:ReceiveBeginPlay()
    self.SuperClass.ReceiveBeginPlay(self);
    if self:HasAuthority() then
	self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
        
    end
end 

function CSActor:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local pc = OtherActor:GetPlayerControllerSafety()
      if pc then
          pc:Server_TeleportToSpawn(self.CSPoint)
      end
end



return CSActor
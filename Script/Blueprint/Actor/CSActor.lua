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
        local playerController=OtherActor:GetPlayerControllerSafety()
        if playerController then
                    L_Event:SendEvent("OnStartPoint",  self.CSPoint)
ugcprint("[CSActor] Overlap! CSPoint=" .. tostring(self.CSPoint))

        end
end



return CSActor
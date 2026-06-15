---@class bottomCreateMoms_C:AActor
---@field Box UBoxComponent
---@field Sphere UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field Level int32
--Edit Below--
local bottomCreateMoms = {}
function bottomCreateMoms:ReceiveBeginPlay()
    bottomCreateMoms.SuperClass.ReceiveBeginPlay(self)
	self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
end

function bottomCreateMoms:ReceiveEndPlay()
    L_Event:RemoveListener(L_Enum_Event.Enum.Test_01,self.OnhandleTest,self)
    bottomCreateMoms.SuperClass.ReceiveEndPlay(self)
end

function bottomCreateMoms:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local PlayerController=OtherActor:GetPlayerControllerSafety()

    --[[----------------------我现在想要实现碰撞通知谁碰撞了第几关卡------------------------]]--
local allPlayerControllers = UGCGameSystem.GetAllPlayerController()
local uid = UGCGameSystem.GetUIDByPlayerPawn(OtherActor)

for _, pc in ipairs(allPlayerControllers) do
    if pc then
        UnrealNetwork.CallUnrealRPC(pc,pc,"Client_BroadcastPlantMessage",uid,self.Level)
    end
end

--[[----------------------摧毁-----------------------]]--
    self:K2_DestroyActor()
end


-- [Editor Generated Lua] function define End;

return bottomCreateMoms
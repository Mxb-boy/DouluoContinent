---@class CreateMonsWall_C:AActor
---@field Box UBoxComponent
---@field DefaultSceneRoot USceneComponent
---@field Scene TEnumAsByte<Scene_Enum>
---@field BigLevel int32
---@field LittleLevel int32
--Edit Below--
---@class CreateMonsWall_C:AActor
---@field Box UBoxComponent
---@field StaticMesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field Scene TEnumAsByte<Scene_Enum>
---@field BigLevel int32
local CreateMonsWall = {}

function CreateMonsWall:ReceiveBeginPlay()
    CreateMonsWall.SuperClass.ReceiveBeginPlay(self)
	self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
end

function CreateMonsWall:ReceiveEndPlay()
    CreateMonsWall.SuperClass.ReceiveEndPlay(self)
end

function CreateMonsWall:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    local PlayerController=OtherActor:GetPlayerControllerSafety()

    --[[----------------------我现在想要实现碰撞通知谁碰撞了第几关卡------------------------]]--
local allPlayerControllers = UGCGameSystem.GetAllPlayerController()
local uid = UGCGameSystem.GetUIDByPlayerPawn(OtherActor)

for _, pc in ipairs(allPlayerControllers) do
    if pc then
        UnrealNetwork.CallUnrealRPC(pc,pc,"Client_BroadcastPlantMessage",uid,self.LittleLevel)
    end
end


--[[----------------------怪物定点生成------------------------]]--
local monsters = MonsterSpawnMgr.SpawnAtLevelPoints(
    UGCGameSystem.GameMode,
    self.Scene,
    self.BigLevel,
    self.LittleLevel,
    nil
)


--[[----------------------摧毁-----------------------]]--
    self:K2_DestroyActor()

end


return CreateMonsWall
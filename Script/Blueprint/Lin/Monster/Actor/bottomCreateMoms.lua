---@class bottomCreateMoms_C:AActor
---@field Box UBoxComponent
---@field Sphere UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field Level int32
--Edit Below--
local bottomCreateMoms = {}
function bottomCreateMoms:ReceiveBeginPlay()
    bottomCreateMoms.SuperClass.ReceiveBeginPlay(self)

        self.HasTriggered = false
	self.Box.OnComponentBeginOverlap:Add(self.Box_OnComponentBeginOverlap, self);
end

function bottomCreateMoms:ReceiveEndPlay()
    bottomCreateMoms.SuperClass.ReceiveEndPlay(self)
end

function bottomCreateMoms:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
   
    if not self:HasAuthority() or self.HasTriggered then
        return
    end
   
    local PlayerController=OtherActor:GetPlayerControllerSafety()

    --[[----------------------我现在想要实现碰撞通知谁碰撞了第几关卡------------------------]]--
local allPlayerControllers = UGCGameSystem.GetAllPlayerController()
local uid = UGCGameSystem.GetUIDByPlayerPawn(OtherActor)

for _, pc in ipairs(allPlayerControllers) do
    if pc then
        UnrealNetwork.CallUnrealRPC(pc,pc,"Client_BroadcastPlantMessage",uid,self.Level)
    end
end

--[[---------------------怪物出生-------------------------]]--

--  self.HasTriggered = true
-- MonsterSpawnMgr.SpawnMonsters(
--         self,
--         PathMgr.Monster_Level_01,
--         self:K2_GetActorLocation(),
--         self:K2_GetActorRotation(),
--         4,
--         self
--     )

--[[-----------------------怪物定点生成-----------------------]]--

local monsters = MonsterSpawnMgr.SpawnAtLevelPoints(
    UGCGameSystem.GameMode,
    PathMgr.Monster_Level_01,
    PathMgr.MonsStartPoint_C,
    self.Level,
    nil
)



--[[----------------------摧毁-----------------------]]--
    self:K2_DestroyActor()
end


-- [Editor Generated Lua] function define End;

return bottomCreateMoms
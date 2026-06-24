---@class CreateMonsWall_C:AActor
---@field Capsule UCapsuleComponent
---@field DefaultSceneRoot USceneComponent
---@field Scene TEnumAsByte<Scene_Enum>
---@field BigLevel int32
---@field LittleLevel int32
---@field InPeo int32
--Edit Below--
---@class CreateMonsWall_C:AActor
---@field StaticMesh UStaticMeshComponent
---@field DefaultSceneRoot USceneComponent
---@field Scene TEnumAsByte<Scene_Enum>
---@field BigLevel int32
local CreateMonsWall = {}

function CreateMonsWall:ReceiveBeginPlay()
    CreateMonsWall.SuperClass.ReceiveBeginPlay(self)

    self.HasStarted = false
    self.IsWaitingRespawn = false
    self.IsCheckingWave = false
    self.AliveMonsters = {}
    self.InsidePlayerOverlapCounts = {}
    self.ActorToPlayerUIDs = {}
    self.InsidePlayerCount = 0

    	self.Capsule.OnComponentBeginOverlap:Add(self.Capsule_OnComponentBeginOverlap, self);
	self.Capsule.OnComponentEndOverlap:Add(self.Capsule_OnComponentEndOverlap, self);
end

function CreateMonsWall:ReceiveEndPlay()
    CreateMonsWall.SuperClass.ReceiveEndPlay(self)
end

function CreateMonsWall:Box_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
 
end

function CreateMonsWall:Box_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
  
end

function CreateMonsWall:HasPlayerInside()
    return (self.InsidePlayerCount or 0) > 0
end

function CreateMonsWall:ResumeWaveLoop()
    if self:HasPlayerInside() == false then
        self.IsCheckingWave = false
        return
    end

    if self.IsWaitingRespawn then
        return
    end

    if #(self.AliveMonsters or {}) <= 0 then
        self:StartRespawnTimer()
        return
    end

    self:CheckWaveCleared()
end

function CreateMonsWall:SpawnWave()
    if self:HasAuthority() == false then
        return
    end

    if self:HasPlayerInside() == false then
        self.IsWaitingRespawn = false
        return
    end

    self.IsWaitingRespawn = false

    self.AliveMonsters = MonsterSpawnMgr.SpawnAtLevelPoints(
        UGCGameSystem.GameMode,
        self.Scene,
        self.BigLevel,
        self.LittleLevel,
        nil
    ) or {}

    for _, monster in ipairs(self.AliveMonsters) do
        if monster then
            monster.SpawnWall = self
        end
    end

    self:CheckWaveCleared()
end

function CreateMonsWall:CheckWaveCleared()
    if self:HasAuthority() == false or self.IsWaitingRespawn then
        return
    end

    if self:HasPlayerInside() == false then
        return
    end

    for index = #self.AliveMonsters, 1, -1 do
        local monster = self.AliveMonsters[index]
        if self:IsMonsterAlive(monster) == false then
            table.remove(self.AliveMonsters, index)
        end
    end

    if #self.AliveMonsters <= 0 then
        self.IsCheckingWave = false
        self:StartRespawnTimer()
        return
    end

    if self.IsCheckingWave then
        return
    end

    self.IsCheckingWave = true

    local wall = self
    UGCTimerUtility.CreateLuaTimer(1, function()
        if wall ~= nil and UE.IsValid(wall) then
            wall.IsCheckingWave = false
        end

        if wall ~= nil and UE.IsValid(wall) and wall:HasPlayerInside() then
            wall:CheckWaveCleared()
        end
    end, false)
end

function CreateMonsWall:IsMonsterAlive(monster)
    if monster == nil or UE.IsValid(monster) == false then
        return false
    end

    return true
end

function CreateMonsWall:StartRespawnTimer()
    if self.IsWaitingRespawn or self:HasPlayerInside() == false then
        return
    end

    self.IsWaitingRespawn = true
    self.IsCheckingWave = false

    local wall = self
    UGCTimerUtility.CreateLuaTimer(3, function()
        if wall ~= nil and UE.IsValid(wall) then
            wall.IsWaitingRespawn = false
            if wall:HasPlayerInside() then
                wall:SpawnWave()
            end
        end
    end, false)
end

function CreateMonsWall:OnMonsterDied(monster)
    if self:HasAuthority() == false then
        return
    end

    for index = #self.AliveMonsters, 1, -1 do
        if self.AliveMonsters[index] == monster then
            table.remove(self.AliveMonsters, index)
            break
        end
    end

    if #self.AliveMonsters <= 0 and self:HasPlayerInside() then
        self:StartRespawnTimer()
    end
end

-- [Editor Generated Lua] function define Begin:
function CreateMonsWall:LuaInit()
	if self.bInitDoOnce then
		return;
	end
	self.bInitDoOnce = true;
	-- [Editor Generated Lua] BindingProperty Begin:
	-- [Editor Generated Lua] BindingProperty End;
	
	-- [Editor Generated Lua] BindingEvent Begin:

	-- [Editor Generated Lua] BindingEvent End;
end

function CreateMonsWall:Capsule_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
   if self:HasAuthority() == false then
        return
    end

    local uid = self:GetPlayerUID(OtherActor)
    if uid == nil then
        return
    end

    self.ActorToPlayerUIDs[OtherActor] = uid

    local overlapCount = self.InsidePlayerOverlapCounts[uid] or 0
    self.InsidePlayerOverlapCounts[uid] = overlapCount + 1

    if overlapCount <= 0 then
        self.InsidePlayerCount = self.InsidePlayerCount + 1
    end

    if self.HasStarted then
        self:ResumeWaveLoop()
        return
    end

    self.HasStarted = true

    local allPlayerControllers = UGCGameSystem.GetAllPlayerController()

    for _, pc in ipairs(allPlayerControllers or {}) do
        if pc then
            UnrealNetwork.CallUnrealRPC(pc, pc, "Client_BroadcastPlantMessage", uid, self.LittleLevel)
        end
    end

    self:SpawnWave()
end

function CreateMonsWall:Capsule_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
  if self:HasAuthority() == false then
        return
    end

    local uid = self:GetPlayerUID(OtherActor)
    if uid == nil then
        return
    end

    local overlapCount = self.InsidePlayerOverlapCounts[uid] or 0
    if overlapCount <= 1 then
        self.InsidePlayerOverlapCounts[uid] = nil
        self.ActorToPlayerUIDs[OtherActor] = nil
        self.InsidePlayerCount = math.max(0, self.InsidePlayerCount - 1)
    else
        self.InsidePlayerOverlapCounts[uid] = overlapCount - 1
    end
end

function CreateMonsWall:GetPlayerUID(OtherActor)
    if OtherActor == nil then
        return nil
    end

    local uid = UGCGameSystem.GetUIDByPlayerPawn(OtherActor)
    if uid ~= nil then
        return uid
    end

    return self.ActorToPlayerUIDs[OtherActor]
end

-- [Editor Generated Lua] function define End;

return CreateMonsWall

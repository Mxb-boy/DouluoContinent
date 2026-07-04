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

local RegenSystem = UGCGameSystem.UGCRequire("Script.Common.RegenSystem")

--- 判断 Actor 是否为玩家 Pawn
local function IsPlayerPawn(actor)
    if actor == nil then
        return false
    end
    -- 玩家 Pawn 才有 GetPlayerControllerSafety 方法
    return actor.GetPlayerControllerSafety ~= nil
end

function CreateMonsWall:ReceiveBeginPlay()
    CreateMonsWall.SuperClass.ReceiveBeginPlay(self)

    self.HasStarted = false
    self.IsWaitingRespawn = false
    self.IsCheckingWave = false
    self.AliveMonsters = {}
    self.InsidePlayerOverlapCounts = {}
    self.ActorToPlayerUIDs = {}
    self.InsidePlayerCount = 0
    self.RespawnTimerToken = 0
    self.SpawnPointRespawnTokens = {}
    self.MonsterSpawnPoints = {}

    	self.Capsule.OnComponentBeginOverlap:Add(self.Capsule_OnComponentBeginOverlap, self);
	self.Capsule.OnComponentEndOverlap:Add(self.Capsule_OnComponentEndOverlap, self);
end

function CreateMonsWall:ReceiveEndPlay()
    CreateMonsWall.SuperClass.ReceiveEndPlay(self)
end

function CreateMonsWall:HasPlayerInside()
    return (self.InsidePlayerCount or 0) > 0
end

function CreateMonsWall:GetBossClass()
    local bossPath = UGCGameSystem.GetUGCResourcesFullPath(
        string.format(
            'Asset/Blueprint/Prefabs/Monsters/Dungeon/Boss_%d.Boss_%d_C',
            self.LittleLevel,
            self.LittleLevel
        )
    )

    return MonsterSpawnMgr.GetCachedClass(bossPath)
end

function CreateMonsWall:GetBossClassByIndex(index)
    local bossPath = UGCGameSystem.GetUGCResourcesFullPath(
        string.format(
            'Asset/Blueprint/Prefabs/Monsters/Dungeon/Boss_%d.Boss_%d_C',
            index,
            index
        )
    )

    return MonsterSpawnMgr.GetCachedClass(bossPath)
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
        self:SpawnWave()
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
    self.SpawnPointRespawnTokens = {}
    self.MonsterSpawnPoints = {}

    if self.Scene == Scene_Enum.duplicate then
        self.AliveMonsters = {}

        local points = MonsterSpawnMgr.GetCachedLevelPoints(
            UGCGameSystem.GameMode,
            self.Scene,
            self.BigLevel,
            self.LittleLevel
        )

        if self.BigLevel == 1 and self.LittleLevel == 1 then
            for _, point in ipairs(points or {}) do
                local startPoint = point.StartPoint or 0
                if startPoint >= 1 and startPoint <= 5 then
                    local boss = MonsterSpawnMgr.SpawnAtPointWithClass(
                        UGCGameSystem.GameMode,
                        self:GetBossClassByIndex(startPoint),
                        point,
                        nil
                    )

                    if boss then
                        table.insert(self.AliveMonsters, boss)
                    end
                end
            end
        else
            local bossClass = self:GetBossClass()

            for _, point in ipairs(points or {}) do
                if point.StartPoint == 1 then
                    local boss = MonsterSpawnMgr.SpawnAtPointWithClass(
                        UGCGameSystem.GameMode,
                        bossClass,
                        point,
                        nil
                    )

                    if boss then
                        table.insert(self.AliveMonsters, boss)
                    end
                    break
                end
            end
        end
    else
        self.AliveMonsters = MonsterSpawnMgr.SpawnAtLevelPoints(
            UGCGameSystem.GameMode,
            self.Scene,
            self.BigLevel,
            self.LittleLevel,
            nil
        ) or {}
    end

    for _, monster in ipairs(self.AliveMonsters) do
        if monster then
            monster.SpawnWall = self
            self.MonsterSpawnPoints[monster] = monster.SpawnPoint
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
            self:ScheduleMonsterRespawn(monster)
            self.MonsterSpawnPoints[monster] = nil
            table.remove(self.AliveMonsters, index)
        end
    end

    if self.IsCheckingWave then
        return
    end

    self.IsCheckingWave = true

    local wall = self
    UGCTimerUtility.CreateLuaTimer(0.1, function()
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

function CreateMonsWall:DestroyAliveMonsters()
    if self:HasAuthority() == false then
        return
    end

    self.RespawnTimerToken = (self.RespawnTimerToken or 0) + 1

    for index = #self.AliveMonsters, 1, -1 do
        local monster = self.AliveMonsters[index]
        if monster ~= nil and UE.IsValid(monster) then
            UGCActorComponentUtility.DestroyActor(monster)
        end
        self.MonsterSpawnPoints[monster] = nil
        table.remove(self.AliveMonsters, index)
    end

    self.IsWaitingRespawn = false
    self.IsCheckingWave = false
    self.SpawnPointRespawnTokens = {}
    self.MonsterSpawnPoints = {}
end

function CreateMonsWall:AddAliveMonster(monster)
    if monster == nil then
        return
    end

    monster.SpawnWall = self
    self.MonsterSpawnPoints = self.MonsterSpawnPoints or {}
    self.MonsterSpawnPoints[monster] = monster.SpawnPoint
    table.insert(self.AliveMonsters, monster)
end

function CreateMonsWall:ScheduleMonsterRespawn(monster)
    if self:HasAuthority() == false or self:HasPlayerInside() == false then
        return
    end

    if monster == nil then
        return
    end

    local spawnPoint = nil
    if self.MonsterSpawnPoints ~= nil then
        spawnPoint = self.MonsterSpawnPoints[monster]
    end
    if spawnPoint == nil and UE.IsValid(monster) then
        spawnPoint = monster.SpawnPoint
    end
    if spawnPoint == nil or UE.IsValid(spawnPoint) == false then
        return
    end

    self.SpawnPointRespawnTokens = self.SpawnPointRespawnTokens or {}
    local token = (self.SpawnPointRespawnTokens[spawnPoint] or 0) + 1
    self.SpawnPointRespawnTokens[spawnPoint] = token

    local respawnDelay = 3
    if self.LittleLevel == 10 then
        respawnDelay = 5
    end

    local wall = self
    UGCTimerUtility.CreateLuaTimer(respawnDelay, function()
        if wall == nil or UE.IsValid(wall) == false then
            return
        end

        if wall:HasPlayerInside() == false then
            return
        end

        if wall.SpawnPointRespawnTokens == nil or wall.SpawnPointRespawnTokens[spawnPoint] ~= token then
            return
        end

        wall.SpawnPointRespawnTokens[spawnPoint] = nil
        local newMonster = nil
        if wall.Scene == Scene_Enum.duplicate then
            local bossClass = wall:GetBossClass()
            if wall.BigLevel == 1 and wall.LittleLevel == 1 then
                bossClass = wall:GetBossClassByIndex(spawnPoint.StartPoint or 1)
            end

            newMonster = MonsterSpawnMgr.SpawnAtPointWithClass(
                UGCGameSystem.GameMode,
                bossClass,
                spawnPoint,
                nil
            )
        else
            newMonster = MonsterSpawnMgr.SpawnAtPoint(
                UGCGameSystem.GameMode,
                wall.Scene,
                wall.BigLevel,
                wall.LittleLevel,
                spawnPoint,
                nil
            )
        end

        if newMonster then
            wall:AddAliveMonster(newMonster)
            wall:CheckWaveCleared()
        end
    end, false)
end

function CreateMonsWall:StartRespawnTimer()
    if self.IsWaitingRespawn or self:HasPlayerInside() == false then
        return
    end

    self.IsWaitingRespawn = true
    self.IsCheckingWave = false
    self.RespawnTimerToken = (self.RespawnTimerToken or 0) + 1
    local timerToken = self.RespawnTimerToken

    local wall = self
    UGCTimerUtility.CreateLuaTimer(3, function()
        if wall ~= nil and UE.IsValid(wall) then
            if wall.RespawnTimerToken ~= timerToken then
                return
            end

            if wall.IsWaitingRespawn == false then
                return
            end

            wall.IsWaitingRespawn = false
            if wall:HasPlayerInside() and #(wall.AliveMonsters or {}) <= 0 then
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

    self:ScheduleMonsterRespawn(monster)
    if self.MonsterSpawnPoints ~= nil then
        self.MonsterSpawnPoints[monster] = nil
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
    local uid = self:GetPlayerUID(OtherActor)
    if uid == nil then
        return
    end

    self.InPeo=(self.InPeo or 0)+1
--[[--------------------通知谁开启了什么关卡--------------------------]]--
-- local playerPawn=UGCGameSystem.GetLocalPlayerPawn()
--     UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(playerPawn, L_Enum_Event.Enum.ReFreshZhanLi, tostring( self.InPeo))

    -- 战场区域回血：仅对玩家触发，进入即取消倒计时和回血
    if IsPlayerPawn(OtherActor) then
        RegenSystem.OnEnterBattlefield(OtherActor)
    end

    if self:HasAuthority() == false then
        return
    end

    self.ActorToPlayerUIDs[OtherActor] = uid

    local overlapCount = self.InsidePlayerOverlapCounts[uid] or 0
    self.InsidePlayerOverlapCounts[uid] = overlapCount + 1

    if overlapCount <= 0 then
        self.InsidePlayerCount = self.InsidePlayerCount + 1
    end

    if self.HasStarted then
        if #(self.AliveMonsters or {}) <= 0 then
            self.IsWaitingRespawn = false
            self.RespawnTimerToken = (self.RespawnTimerToken or 0) + 1
            self:SpawnWave()
        else
            self:ResumeWaveLoop()
        end
        return
    end

    self.HasStarted = true

    --[[--------------------服务器通知所有客户端--------------------------]]--
    -- local allPlayerControllers = UGCGameSystem.GetAllPlayerController()

    -- for _, pc in ipairs(allPlayerControllers or {}) do
    --     if pc then
    --         UnrealNetwork.CallUnrealRPC(pc, pc, "Client_BroadcastPlantMessage", uid, self.LittleLevel)
    --     end
    -- end

    self:SpawnWave()
end

function CreateMonsWall:Capsule_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    local uid = self:GetPlayerUID(OtherActor)
    if uid == nil then
        return
    end

  self.InPeo=math.max(0, (self.InPeo or 0)-1)
  --[[--------------------通知谁开启了什么关卡--------------------------]]--
--   local playerPawn=UGCGameSystem.GetLocalPlayerPawn()
--     UGCGenericMessageSystem.BroadcastUserDefinedObjectMessage(playerPawn, L_Enum_Event.Enum.ReFreshZhanLi, tostring( self.InPeo))

    -- 战场区域回血：仅对玩家触发，离开后 3 秒开始回血
    if IsPlayerPawn(OtherActor) then
        RegenSystem.OnExitBattlefield(OtherActor)
    end

    if self:HasAuthority() == false then
        return
    end

    local overlapCount = self.InsidePlayerOverlapCounts[uid] or 0

    if overlapCount <= 1 then
        self.InsidePlayerOverlapCounts[uid] = nil
        self.ActorToPlayerUIDs[OtherActor] = nil
        self.InsidePlayerCount = math.max(0, self.InsidePlayerCount - 1)

        if self.InsidePlayerCount <= 0 then
            self:DestroyAliveMonsters()
        end
    else
        self.InsidePlayerOverlapCounts[uid] = overlapCount - 1
    end
end

function CreateMonsWall:GetPlayerUID(OtherActor)
    if OtherActor == nil then
        return nil
    end

    local ok, uid = pcall(UGCGameSystem.GetUIDByPlayerPawn, OtherActor)
    if ok and uid ~= nil then
        return uid
    end

    return self.ActorToPlayerUIDs[OtherActor]
end

-- [Editor Generated Lua] function define End;

return CreateMonsWall
